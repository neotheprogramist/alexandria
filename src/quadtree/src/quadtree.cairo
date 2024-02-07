use core::traits::TryInto;
use core::array::SpanTrait;
use core::clone::Clone;
use core::dict::Felt252DictEntryTrait;
use core::nullable::{nullable_from_box, match_nullable, FromNullableResult};
use core::array::ArrayTrait;
use core::zeroable::Zeroable;
use quadtree::area::{AreaTrait, Area};
use quadtree::point::{Point, PointTrait};

trait QuadtreeTrait<T, P, C> {
    /// Creates a new uadtree instance.
    fn new(region: Area<C>) -> Felt252Quadtree<Felt252QuadtreeNode<T, P, C>>;
    /// Gets the value at the root of the quadtree.
    fn values(ref self: Felt252Quadtree<Felt252QuadtreeNode<T, P, C>>, path: felt252) -> Array<T>;
    /// Inserts a region into the quadtree.
    fn insert(ref self: Felt252Quadtree<Felt252QuadtreeNode<T, P, C>>, path: felt252, value: T);
}

struct Felt252Quadtree<T> {
    elements: Felt252Dict<Nullable<T>>,
}

#[derive(Drop)]
struct Felt252QuadtreeNode<T, P, C> {
    values: Span<T>,
    region: Area<C>,
    path: P,
    mask: P,
}

impl DestructFelt252Quadtree<
    T, P, C, +Drop<T>, +Drop<C>, +Drop<P>
> of Destruct<Felt252Quadtree<Felt252QuadtreeNode<T, P, C>>> {
    fn destruct(self: Felt252Quadtree<Felt252QuadtreeNode<T, P, C>>) nopanic {
        self.elements.squash();
    }
}

impl Felt252QuadtreeImpl<
    T, P, C, +Copy<T>, +Copy<C>, +Copy<P>, +Drop<T>, +Drop<C>, +Drop<P>, +Zeroable<P>
> of QuadtreeTrait<T, P, C> {
    fn new(region: Area<C>) -> Felt252Quadtree<Felt252QuadtreeNode<T, P, C>> {
        let root = Felt252QuadtreeNode {
            path: Zeroable::zero(), 
            mask: Zeroable::zero(), 
            region, 
            values: ArrayTrait::<T>::new().span(),
        };

        let elements = Default::default();
        let mut tree = Felt252Quadtree { elements };
        tree.elements.insert(0, nullable_from_box(BoxTrait::new(root)));
        tree
    }

    fn values(ref self: Felt252Quadtree<Felt252QuadtreeNode<T, P, C>>, path: felt252) -> Array<T> {
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

    fn insert(ref self: Felt252Quadtree<Felt252QuadtreeNode<T, P, C>>, path: felt252, value: T) {
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

