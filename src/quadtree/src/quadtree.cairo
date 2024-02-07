use core::array::SpanTrait;
use core::clone::Clone;
use core::dict::Felt252DictEntryTrait;
use core::nullable::{nullable_from_box, match_nullable, FromNullableResult};
use core::array::ArrayTrait;
use quadtree::area::{AreaTrait, Area};
use quadtree::point::{Point, PointTrait};
use quadtree::node::{Felt252QuadtreeNode, Felt252QuadtreeLeaf, Felt252QuadtreeBranch};

trait QuadtreeTrait<T, C> {
    /// Creates a new uadtree instance.
    fn new(region: Area<C>) -> Felt252Quadtree<Felt252QuadtreeNode<T, C>>;
    /// Gets the value at the root of the quadtree.
    fn values(ref self: Felt252Quadtree<Felt252QuadtreeNode<T, C>>, path: felt252) -> Array<T>;
    /// Inserts a region into the quadtree.
    // fn insert(ref self: Felt252Quadtree<Felt252QuadtreeNode<T, C>>, region: Area<C>, value: T);
    fn insert(ref self: Felt252Quadtree<Felt252QuadtreeNode<T, C>>, path: felt252, value: T);
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

impl Felt252QuadtreeImpl<
    T, C, +Copy<T>, +Copy<C>, +Drop<T>, +Drop<C>, +Felt252DictValue<T>, +Felt252DictValue<C>
> of QuadtreeTrait<T, C> {
    fn new(region: Area<C>) -> Felt252Quadtree<Felt252QuadtreeNode<T, C>> {
        let root = Felt252QuadtreeNode {
            path: 0, mask: 0, region, values: ArrayTrait::<T>::new().span(),
        };

        let elements = Default::default();
        let mut tree = Felt252Quadtree { elements };
        tree.elements.insert(0, nullable_from_box(BoxTrait::new(root)));
        tree
    }

    fn values(ref self: Felt252Quadtree<Felt252QuadtreeNode<T, C>>, path: felt252) -> Array<T> {
        let (entry, val) = self.elements.entry(path);
        let node = match match_nullable(val) {
            FromNullableResult::Null => panic!("No root found"),
            FromNullableResult::NotNull(val) => val.unbox(),
        };

        let mut result = ArrayTrait::new();
        let mut i = 0;
        loop {
            if i == node.values.len() {
                break;
            }
            result.append(*node.values[i]);
            i += 1;
        };

        let val = nullable_from_box(BoxTrait::new(node));
        self.elements = entry.finalize(val);
        result
    }

    fn insert(ref self: Felt252Quadtree<Felt252QuadtreeNode<T, C>>, path: felt252, value: T) {
        let (entry, val) = self.elements.entry(path);
        let mut node = match match_nullable(val) {
            FromNullableResult::Null => panic!("No root found"),
            FromNullableResult::NotNull(val) => val.unbox(),
        };

        let mut new = ArrayTrait::new();
        let mut i = 0;
        loop {
            if i == node.values.len() {
                break;
            }
            new.append(*node.values[i]);
            i += 1;
        };
        new.append(value);
        node.values = new.span();

        let val = nullable_from_box(BoxTrait::new(node));
        self.elements = entry.finalize(val);
    }
}

