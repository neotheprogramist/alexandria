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

impl Iter<M, Y, T, +Map<M, T, Y>, +Drop<Array<T>>> of IterTrait<M, T, Y> {
    fn iter(ref self: Array<T>) -> Array<T> {
        let mut result = ArrayTrait::new();

        loop {
            let v = match self.pop_front() {
                Option::Some(v) => v,
                Option::None => { break; }
            };

            result.append(v);
        };

        result
    }
}

#[cfg(test)]
mod tests {
    use super::{Iter, MapSquare};

    #[test]
    fn it_works() {
        let mut data = array![1_u32, 2, 3];
        let result = Iter::<MapSquare, u32, u32>::iter(ref data);
        assert(*result.at(0) == 1, 'invalid at 0');
        // assert(*result.at(1) == 4, 'invalid at 1');
        // assert(*result.at(2) == 9, 'invalid at 2');
    }
}
