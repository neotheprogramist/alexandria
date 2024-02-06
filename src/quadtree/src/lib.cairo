#[cfg(test)]
mod tests;

trait QuadtreeTrait<T> {
    /// Creates a new uadtree instance.
    fn new() -> Felt252Quadtree<Felt252QuadtreeNode<T>>;
}

struct Felt252Quadtree<T> {
    elements: Felt252Dict<Nullable<T>>,
}

impl DestructFelt252Quadtree<T, +Drop<T>, +Felt252DictValue<T>> of Destruct<Felt252Quadtree<Felt252QuadtreeNode<T>>> {
    fn destruct(self: Felt252Quadtree<Felt252QuadtreeNode<T>>) nopanic {
        self.elements.squash();
    }
}

#[derive(Drop, Copy)]
enum Felt252QuadtreeNode<T> {
    Leaf: Felt252QuadtreeLeaf<T>,
    Branch: Felt252QuadtreeBranch,
}

#[derive(Drop, Copy)]
struct Felt252QuadtreeLeaf<T> {
    value: Nullable<T>,
}

#[derive(Drop, Copy)]
struct Felt252QuadtreeBranch {
    path: felt252,
    mask: felt252,
}

impl Felt252QuadtreeImpl<
    T,
    +Copy<T>,
    +Drop<T>,
    +Felt252DictValue<T>,
> of QuadtreeTrait<T> {
    fn new() -> Felt252Quadtree<Felt252QuadtreeNode<T>> {
        let mut elements = Default::default();
        Felt252Quadtree { elements }
    }
}

