#[cfg(test)]
mod tests;

use core::nullable::{nullable_from_box, match_nullable, FromNullableResult};

trait QuadtreeTrait<T> {
    /// Creates a new uadtree instance.
    fn new(root: Felt252QuadtreeNode<T>) -> Felt252Quadtree<Felt252QuadtreeNode<T>>;
    /// Gets the value at the root of the quadtree.
    fn root(ref self: Felt252Quadtree<Felt252QuadtreeNode<T>>) -> Felt252QuadtreeNode<T>;
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
    Branch: Felt252QuadtreeBranch,
    Leaf: Felt252QuadtreeLeaf<T>,
    Empty: (),
}

#[derive(Drop, Copy)]
struct Felt252QuadtreeLeaf<T> {
    value: T,
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
    fn new(root: Felt252QuadtreeNode<T>) -> Felt252Quadtree<Felt252QuadtreeNode<T>> {
        let mut elements = Default::default();
        elements.insert(0, nullable_from_box(BoxTrait::new(root)));
        Felt252Quadtree { elements }
    }

    fn root(ref self: Felt252Quadtree<Felt252QuadtreeNode<T>>) -> Felt252QuadtreeNode<T> {
        let val = self.elements.get(0);
        match match_nullable(val) {
            FromNullableResult::Null => panic!("No root found"),
            FromNullableResult::NotNull(val) => val.unbox(),
        }    
    }
}

