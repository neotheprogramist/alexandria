use core::option::OptionTrait;
use core::traits::Into;
use core::traits::TryInto;
use core::array::SpanTrait;
use core::clone::Clone;
use core::dict::Felt252DictEntryTrait;
use core::nullable::{nullable_from_box, match_nullable, FromNullableResult};
use core::array::ArrayTrait;
use core::zeroable::Zeroable;
use quadtree::area::{AreaTrait, Area, AreaImpl};
use quadtree::point::{Point, PointTrait, PointImpl};
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
    /// The path of the node in the quadtree, the first bit is always a 1 and the
    /// each 2 bits store a quadrant (ne, nw, se, sw).
    /// e.g. 0b100 is the top right, 0b101 is the top left quadrant, 
    /// 0b11111 is the bottom right quadrant of the bottom right.
    path: P,
    /// Whether the node is a leaf or not.
    is_leaf: Option<Point<C>>,
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
    +Into<P, felt252>, // Dict key is felt252
    +Into<u8, P>, // Adding nested level
    +Add<P>, // Nesting the path
    +Mul<P>, // Nesting the path
    +Add<C>, // Needed for area
    +PointTrait<C>, // Present in the area
> of QuadtreeTrait<T, P, C> {
    fn new(region: Area<C>) -> Felt252Quadtree<T, P, C> {
        // constructng the root node
        let root_path: u8 = 1;
        let root = Felt252QuadtreeNode::<
            T, P, C
        > {
            path: root_path.into(),
            region,
            values: ArrayTrait::<T>::new().span(),
            is_leaf: Option::None,
        };
        // creating the dictionary
        let elements = Default::default();
        let mut tree = Felt252Quadtree { elements };

        // inserting it at root
        tree.elements.insert(root_path.into(), nullable_from_box(BoxTrait::new(root)));
        tree
    }

    fn values(ref self: Felt252Quadtree<T, P, C>, path: P) -> Array<T> {
        // getting the node from the dictionary without cloning it
        let (entry, val) = self.elements.entry(path.into());
        let node = match match_nullable(val) {
            FromNullableResult::Null => panic!("Node does not exist"),
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

    fn insert_at(ref self: Felt252Quadtree<T, P, C>, value: T, path: P) {
        // getting the node from the dictionary without cloning it
        let (entry, val) = self.elements.entry(path.into());
        let mut node = match match_nullable(val) {
            FromNullableResult::Null => panic!("Node does not exist"),
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

    fn insert_point(ref self: Felt252Quadtree<T, P, C>, value: T, point: Point<C>) {
        // type interference hack
        let one: u8 = 1;
        let bottom = one + one;
        let four: P = (bottom + bottom).into();


        let mut path: P = one.into();
        let mut break_flag = false;

        loop {
            if break_flag {
                break;
            }

            // getting a smaller node
            let (entry, val) = self.elements.entry(path.into());
            let mut node = match match_nullable(val) {
                FromNullableResult::Null => panic!("Node does not exist"),
                FromNullableResult::NotNull(val) => val.unbox(),
            };

            // checking if the node is a leaf, or which quadrant the point is in
            path = match node.is_leaf {
                Option::Some(middle) => {
                    match point.lt_x(@middle) {
                        true => match point.lt_y(@middle) {
                            true => path * four + one.into(),
                            false => path * four + bottom.into(), 
                        },
                        false => match point.lt_y(@middle) {
                            true => path * four,
                            false => path * four + bottom.into() + one.into()
                        },
                    }
                },
                Option::None => {
                    // the node is leaf
                    // TODO: split the node
                    break_flag = true;
                    path
                },
            };

            let val = nullable_from_box(BoxTrait::new(node));
            self.elements = entry.finalize(val);
        };

        self.insert_at(value, path);
    }

    fn split(ref self: Felt252Quadtree<T, P, C>, path: P, point: Point<C>) {
        // getting the node from the dictionary without cloning it
        let (entry, val) = self.elements.entry(path.into());
        let mut parent = match match_nullable(val) {
            FromNullableResult::Null => panic!("Node does not exist"),
            FromNullableResult::NotNull(val) => val.unbox(),
        };

        // retrieving the region of the parent node
        let area = parent.region;

        // preparing regions for the new nodes
        let mut regions = array![
            AreaTrait::new_from_points(area.top(), *point.x(), *point.y(), area.right()),    // ne
            AreaTrait::new_from_points(area.top(), area.left(), *point.y(), *point.x()),     // nw
            AreaTrait::new_from_points(*point.y(), area.left(), area.bottom(), *point.x()),  // sw
            AreaTrait::new_from_points(*point.y(), *point.x(), area.bottom(), area.right()), // se
        ];

        // returning the node to the dictionary
        parent.is_leaf = Option::Some(point);
        let val = nullable_from_box(BoxTrait::new(parent));
        self.elements = entry.finalize(val);


        // reused multipiers for the path and mask
        let four: u8 = 4;
        let four: P = four.into();

        let mut i: u8 = 0;
        loop {
            if regions.len() == 0 {
                break;
            }

            // creating the new path from the parent path
            let path = path * four + i.into();

            // creating the leaf node
            let node = Felt252QuadtreeNode::<
                T, P, C
            > {
                path,
                region: regions.pop_front().unwrap(),
                values: ArrayTrait::<T>::new().span(),
                is_leaf: Option::None,
            };

            // inserting the new node to the dictionary
            self.elements.insert(path.into(), nullable_from_box(BoxTrait::new(node)));
            i += 1;
        };
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
