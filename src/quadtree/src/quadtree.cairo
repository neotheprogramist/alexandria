use core::traits::TryInto;
use core::array::SpanTrait;
use core::clone::Clone;
use core::dict::Felt252DictEntryTrait;
use core::nullable::{nullable_from_box, match_nullable, FromNullableResult};
use core::array::ArrayTrait;
use core::zeroable::Zeroable;
use quadtree::area::{AreaTrait, Area};
use quadtree::point::{Point, PointTrait};
use quadtree::QuadtreeTrait;

/// All the branches and leaves of the quadtree are stored in a dictionary.
struct Felt252Quadtree<T, P, C> {
    elements: Felt252Dict<Nullable<Felt252QuadtreeNode<T, P, C>>>,
}

/// Each node in the quadtree is a struct with a region, a path, a mask and a list of values.
#[derive(Drop)]
struct Felt252QuadtreeNode<T, P, C> {
    /// Values for a given region of the quadtree.
    values: Span<T>,
    /// The region of the grometry that this node represents.
    region: Area<C>,
    /// The path of the node in the quadtree, each 2 bits store a quadrant (ne, nw, se, sw).
    /// e.g. 0b00 is the top right, 0b01 is the top left quadrant, 
    /// 0b1111 is the bottom right quadrant of the bottom right.
    path: P,
    /// The mask of the node in the quadtree, to differentiate between nodes.
    /// e.g 0 with mask of 0 is the root node, but 0 with mask of 4 is the top right of 16.
    mask: P,
}


impl Felt252QuadtreeImpl<
    T,
    P,
    C,
    +Copy<T>,
    +Copy<C>,
    +Copy<P>,
    +Drop<T>,
    +Drop<C>,
    +Drop<P>,
    +Zeroable<P>, // Root has zero path of type P
    +Into<P, felt252> // Dict key is felt252
> of QuadtreeTrait<T, P, C> {
    fn new(region: Area<C>) -> Felt252Quadtree<T, P, C> {
        // constructng the root node
        let root = Felt252QuadtreeNode::<
            T, P, C
        > {
            path: Zeroable::zero(),
            mask: Zeroable::zero(),
            region,
            values: ArrayTrait::<T>::new().span()
        };
        // creating the dictionary
        let elements = Default::default();
        let mut tree = Felt252Quadtree { elements };

        // inserting it at root
        tree.elements.insert(0, nullable_from_box(BoxTrait::new(root)));
        tree
    }

    fn values(ref self: Felt252Quadtree<T, P, C>, path: P) -> Array<T> {
        // getting the node from the dictionary without cloning it
        let (entry, val) = self.elements.entry(path.into());
        let node = match match_nullable(val) {
            FromNullableResult::Null => panic!("No root found"),
            FromNullableResult::NotNull(val) => val.unbox(),
        };

        // getting the values from the node
        let mut result = ArrayTrait::new();
        let mut i = 0;
        loop {
            if i == node.values.len() {
                break;
            }
            result.append(*node.values[i]);
            i += 1;
        };

        // returning the node to the dictionary
        let val = nullable_from_box(BoxTrait::new(node));
        self.elements = entry.finalize(val);
        result
    }

    fn insert(ref self: Felt252Quadtree<T, P, C>, path: P, value: T) {
        // getting the node from the dictionary without cloning it
        let (entry, val) = self.elements.entry(path.into());
        let mut node = match match_nullable(val) {
            FromNullableResult::Null => panic!("No root found"),
            FromNullableResult::NotNull(val) => val.unbox(),
        };

        // adding the value to the node
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

        // returning the node to the dictionary
        let val = nullable_from_box(BoxTrait::new(node));
        self.elements = entry.finalize(val);
    }
}

// Needed as array doesn't implement Drop nor Destruct
impl DestructFelt252Quadtree<
    T, P, C, +Drop<T>, +Drop<C>, +Drop<P>
> of Destruct<Felt252Quadtree<T, P, C>> {
    fn destruct(self: Felt252Quadtree<T, P, C>) nopanic {
        self.elements.squash();
    }
}
