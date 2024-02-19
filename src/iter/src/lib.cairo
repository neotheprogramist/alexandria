use core::array::ArrayTrait;

trait Map<M, T, Y> {
    fn map(x: T) -> Y;
}

struct MapSquare {}

impl MapSquareImpl of Map<MapSquare, u32, u32> {
    fn map(x: u32) -> u32 {
        x * x
    }
}

trait IterTrait<M, T, Y, +Map<M, T, Y>> {
    fn iter(ref self: Array<T>) -> Array<T>;
}

impl Iter_u32<M, +Map<M, u32, u32>> of IterTrait<M, u32, u32> {
    fn iter(ref self: Array<u32>) -> Array<u32> {
        let mut result = ArrayTrait::new();

        loop {
            let v = match self.pop_front() {
                Option::Some(v) => v,
                Option::None => { break; }
            };

            result.append(MapSquareImpl::map(v));
        };

        result
    }
}

#[cfg(test)]
mod tests {
    use super::{Iter_u32, MapSquare};

    #[test]
    fn it_works() {
        let mut data = array![1_u32, 2, 3];
        let result = Iter_u32::<MapSquare>::iter(ref data);
        
        assert(*result.at(0) == 1, 'invalid at 0');
        assert(*result.at(1) == 4, 'invalid at 1');
        assert(*result.at(2) == 9, 'invalid at 2');
    }
}
