use core::nullable::{nullable_from_box, match_nullable, FromNullableResult};
use quadtree::area::{AreaTrait, Area};
use quadtree::point::{Point, PointTrait};
use quadtree::node::{Felt252QuadtreeNode, Felt252QuadtreeLeaf, Felt252QuadtreeBranch};

trait QuadtreeTrait<T, C> {
    /// Creates a new uadtree instance.
    fn new(root: Felt252QuadtreeNode<T, C>) -> Felt252Quadtree<Felt252QuadtreeNode<T, C>>;
    /// Gets the value at the root of the quadtree.
    fn root(ref self: Felt252Quadtree<Felt252QuadtreeNode<T, C>>) -> Felt252QuadtreeNode<T, C>;
    /// Inserts a region into the quadtree.
    // fn insert(ref self: Felt252Quadtree<Felt252QuadtreeNode<T, C>>, region: Area<C>, value: T);
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

    // fn insert(ref self: Felt252Quadtree<Felt252QuadtreeNode<T, C>>, region: Area<C>, value: T) {
    // }
}

