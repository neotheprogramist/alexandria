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
use quadtree::{QuadtreeTrait, QuadtreeNode, QuadtreeNodeTrait};

/// All the branches and leaves of the quadtree are stored in a dictionary.
struct Felt252Quadtree<T, P, C> {
    elements: Felt252Dict<Nullable<QuadtreeNode<T, P, C>>>,
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
        let root = QuadtreeNode::<
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

    fn query_regions(ref self: Felt252Quadtree<T, P, C>, point: Point<C>) -> Array<T> {
        // type interference hack
        let one: u8 = 1;
        let bottom = one + one;
        let four: P = (bottom + bottom).into();

        let mut path: P = one.into();
        let mut break_flag = false;
        let mut values = ArrayTrait::new();

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

            // adding the values to the result
            let mut i = 0;
            loop {
                if i == node.values.len() {
                    break;
                }
                values.append(*node.values[i]);
                i += 1;
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

        values
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

    fn insert_region(ref self: Felt252Quadtree<T, P, C>, value: T, region: Area<C>) {
        // type interference hack
        let one: u8 = 1;
        let one: P = one.into();
        let bottom = one + one;
        let four: P = (bottom + bottom).into();

        let mut to_visit = array![one];
        let mut to_append = ArrayTrait::new();

        loop {
            // getting a smaller node
            let path = match to_visit.pop_front() {
                Option::Some(path) => path,
                Option::None => { break; },
            };
            let (entry, val) = self.elements.entry(path.into());
            let mut node = match match_nullable(val) {
                FromNullableResult::Null => panic!("Node does not exist"),
                FromNullableResult::NotNull(val) => val.unbox(),
            };

            if !region
                .intersects(
                    @node.region
                ) { // if the region does not intersect the node's region, we skip it
            } else if node.is_leaf.is_none() {
                // if the node is a leaf, we add the value to the node or split it
                // TODO: split the node
                to_append.append(path);
            } else if region.contains(node.region.bottom_right())
                && region.contains(node.region.top_left()) {
                // if the region contains the node, we add it to the node
                to_append.append(path);
            } else {
                // if the region does not contain the node, we check its children
                let child_path = node.path * four;
                to_visit.append(child_path);
                to_visit.append(child_path + one);
                to_visit.append(child_path + bottom);
                to_visit.append(child_path + bottom + one);
            }

            // let p: felt252 = path.into();
            // let x: felt252 = (*node.region.top_left().x()).into();
            // let y: felt252 = (*node.region.top_left().y()).into();
            // let tv = to_visit.len();
            // let ta = to_append.len();

            // '-----'.print();
            // p.print();
            // x.print();
            // y.print();
            // tv.print();
            // ta.print();
            // '-----'.print();

            let val = nullable_from_box(BoxTrait::new(node));
            self.elements = entry.finalize(val);
        };

        loop {
            match to_append.pop_front() {
                Option::Some(path) => self.insert_at(value, path),
                Option::None => { break; },
            };
        }
    }

    fn split(ref self: Felt252Quadtree<T, P, C>, path: P, point: Point<C>) {
        // getting the node from the dictionary without cloning it
        let (entry, val) = self.elements.entry(path.into());
        let mut parent = match match_nullable(val) {
            FromNullableResult::Null => panic!("Node does not exist"),
            FromNullableResult::NotNull(val) => val.unbox(),
        };

        let mut children = parent.split_at(point);

        // returning the node to the dictionary
        let val = nullable_from_box(BoxTrait::new(parent));
        self.elements = entry.finalize(val);

        loop {
            match children.pop_front() {
                Option::Some(child) => {
                    let path = child.path.into();
                    let child = nullable_from_box(BoxTrait::new(child));
                    self.elements.insert(path, child);
                },
                Option::None => { break; },
            };
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
