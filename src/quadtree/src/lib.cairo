#[cfg(test)]
mod tests;

trait QuadtreeTrait<T> {
    /// Creates a new uadtree instance.
    fn new() -> Felt252Quadtree<V<T>>;
}

struct Felt252Quadtree<T> {
    elements: Felt252Dict<Nullable<T>>,
}

#[derive(Drop)]
struct V<T> {
    pub v: T
}

impl DestructFelt252Quadtree<T, +Drop<T>, +Felt252DictValue<T>> of Destruct<Felt252Quadtree<V<T>>> {
    fn destruct(self: Felt252Quadtree<V<T>>) nopanic {
        self.elements.squash();
    }
}

#[derive(Drop, Copy)]
enum Felt252QuadtreeNode<T> {
    Leaf: Felt252QuadtreeLeaf<Nullable<T>>,
    Branch: Felt252QuadtreeBranch<T>,
}

#[derive(Drop, Copy)]
struct Felt252QuadtreeLeaf<T> {
    value: Nullable<T>,
}

#[derive(Drop, Copy)]
struct Felt252QuadtreeBranch<T> {
    // path: felt252,
    // mask: felt252,
    value: T,
}

impl Felt252QuadtreeImpl<
    T,
    +Copy<T>,
    +Drop<T>,
    +Felt252DictValue<T>,
> of QuadtreeTrait<T> {
    fn new() -> Felt252Quadtree<V<T>> {
        let mut elements = Default::default();
        Felt252Quadtree::<V<T>> { elements }
    }
}

