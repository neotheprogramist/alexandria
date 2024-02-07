#[cfg(test)]
mod tests;

mod area;
mod point;

use core::nullable::{nullable_from_box, match_nullable, FromNullableResult};
use area::{AreaTrait, Area};
use point::{Point, PointTrait};

trait QuadtreeTrait<T, C> {
    /// Creates a new uadtree instance.
    fn new(root: Felt252QuadtreeNode<T, C>) -> Felt252Quadtree<Felt252QuadtreeNode<T, C>>;
    /// Gets the value at the root of the quadtree.
    fn root(ref self: Felt252Quadtree<Felt252QuadtreeNode<T, C>>) -> Felt252QuadtreeNode<T, C>;
}

struct Felt252Quadtree<T> {
    elements: Felt252Dict<Nullable<T>>,
}

impl DestructFelt252Quadtree<
    T, C, +Drop<T>, +Drop<C>, +Felt252DictValue<T>, +Felt252DictValue<C>
> of Destruct<Felt252Quadtree<Felt252QuadtreeNode<T, C>>> {
    fn destruct(self: Felt252Quadtree<Felt252QuadtreeNode<T, C>>) nopanic {
        self.elements.squash();
    }
}

#[derive(Drop, Copy)]
enum Felt252QuadtreeNode<T, C> {
    Branch: Felt252QuadtreeBranch,
    Leaf: Felt252QuadtreeLeaf<T, C>,
    Empty: (),
}

#[derive(Drop, Copy)]
struct Felt252QuadtreeLeaf<T, C> {
    area: Area<C>,
    value: T,
}

#[derive(Drop, Copy)]
struct Felt252QuadtreeBranch {
    path: felt252,
    mask: felt252,
}

impl Felt252QuadtreeImpl<T, C, +Copy<T>, +Copy<C>, +Drop<T>, +Drop<C>, +Felt252DictValue<T>,  +Felt252DictValue<C>> of QuadtreeTrait<T, C> {
    fn new(root: Felt252QuadtreeNode<T, C>) -> Felt252Quadtree<Felt252QuadtreeNode<T, C>> {
        let mut elements = Default::default();
        elements.insert(0, nullable_from_box(BoxTrait::new(root)));
        Felt252Quadtree { elements }
    }

    fn root(ref self: Felt252Quadtree<Felt252QuadtreeNode<T, C>>) -> Felt252QuadtreeNode<T, C> {
        let val = self.elements.get(0);
        match match_nullable(val) {
            FromNullableResult::Null => panic!("No root found"),
            FromNullableResult::NotNull(val) => val.unbox(),
        }
    }
}

