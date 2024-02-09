use core::option::OptionTrait;
use core::zeroable::Zeroable;
use quadtree::area::{AreaTrait, Area, AreaImpl};
use quadtree::point::{Point, PointTrait, PointImpl};

/// Each node in the quadtree is a struct with a region, a path, a mask and a list of values.
#[derive(Drop)]
struct QuadtreeNode<T, P, C> {
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

trait QuadtreeNodeTrait<T, P, C> {
    fn new(region: Area<C>, path: P) -> QuadtreeNode<T, P, C>;
    fn child_at(self: @QuadtreeNode<T, P, C>, point: @Point<C>) -> Option<P>;
    fn split_at(ref self: QuadtreeNode<T, P, C>, point: Point<C>) -> Array<QuadtreeNode<T, P, C>>;
}

impl QuadtreeNodeImpl<
    T,
    P,
    C,
    +Copy<T>,
    +Copy<C>,
    +Copy<P>,
    +Drop<T>,
    +Drop<C>,
    +Drop<P>,
    +Into<u8, P>, // Adding nested level
    +Add<P>, // Nesting the path
    +Mul<P>, // Nesting the path
    +Add<C>, // Needed for area
    +PointTrait<C>, // Present in the area
> of QuadtreeNodeTrait<T, P, C> {
    /// Creates a leaf node with the given region and path.
    fn new(region: Area<C>, path: P) -> QuadtreeNode<T, P, C> {
        QuadtreeNode::<
            T, P, C
        > { path, region, values: ArrayTrait::new().span(), is_leaf: Option::None, }
    }

    /// Returns the child containing the given point.
    /// If the node is a leaf, it returns None.
    /// Assumes the point is within the region of the node.
    /// If the point is on the border of the region, it returns the child
    /// with greater coordinates - top first, then left.
    fn child_at(self: @QuadtreeNode<T, P, C>, point: @Point<C>) -> Option<P> {
        // type interference hack
        let one: u8 = 1;
        let bottom = one + one;
        let four: P = (bottom + bottom).into();

        match self.is_leaf {
            // compare coordinates with the middle of the region in the greater
            Option::Some(middle) => Option::Some(
                match middle.lt_y(point) {
                    false => match middle.lt_x(point) {
                        false => *self.path * four + one.into(),
                        true => *self.path * four,
                    },
                    true => match middle.lt_x(point) {
                        false => *self.path * four + bottom.into(),
                        true => *self.path * four + bottom.into() + one.into()
                    },
                }
            ),
            Option::None => {
                // return none if the node is a leaf
                return Option::None;
            },
        }
    }

    fn split_at(ref self: QuadtreeNode<T, P, C>, point: Point<C>) -> Array<QuadtreeNode<T, P, C>> {
        // returning the node to the dictionary
        assert(self.is_leaf.is_none(), 'Node is not a leaf');
        self.is_leaf = Option::Some(point);

        // retrieving the region of the parent node
        let area = self.region;

        // preparing regions for the new nodes
        let mut regions = array![
            AreaTrait::new_from_points(area.top(), *point.x(), *point.y(), area.right()), // ne
            AreaTrait::new_from_points(area.top(), area.left(), *point.y(), *point.x()), // nw
            AreaTrait::new_from_points(*point.y(), area.left(), area.bottom(), *point.x()), // sw
            AreaTrait::new_from_points(*point.y(), *point.x(), area.bottom(), area.right()), // se
        ];

        // reused multipiers for the path and mask
        let four: u8 = 4;
        let four: P = four.into();

        let mut children = ArrayTrait::new();

        let mut i: u8 = 0;
        loop {
            if regions.len() == 0 {
                break;
            }

            // creating the new path from the parent path
            let path = self.path * four + i.into();

            // creating the leaf node
            let node = QuadtreeNode::<
                T, P, C
            > {
                path,
                region: regions.pop_front().unwrap(),
                values: ArrayTrait::new().span(),
                is_leaf: Option::None,
            };

            // inserting the new node to the dictionary
            children.append(node);
            i += 1;
        };

        children
    }
}

#[test]
fn test_node_child_at() {
    let mut node = QuadtreeNodeTrait::<
        i32, u8, i32
    >::new(AreaTrait::new(PointTrait::new(0, 0), 4, 4), 1);

    assert(node.child_at(@PointTrait::new(1, 1)).is_none(), 'child before split');
    node.split_at(PointTrait::new(2, 2));

    assert(node.child_at(@PointTrait::new(3, 1)).unwrap() == 0b100, 'ne center');
    assert(node.child_at(@PointTrait::new(1, 1)).unwrap() == 0b101, 'nw center');
    assert(node.child_at(@PointTrait::new(1, 3)).unwrap() == 0b110, 'sw center');
    assert(node.child_at(@PointTrait::new(3, 3)).unwrap() == 0b111, 'se center');

    assert(node.child_at(@PointTrait::new(4, 0)).unwrap() == 0b100, 'ne corner');
    assert(node.child_at(@PointTrait::new(0, 0)).unwrap() == 0b101, 'nw corner');
    assert(node.child_at(@PointTrait::new(0, 4)).unwrap() == 0b110, 'sw corner');
    assert(node.child_at(@PointTrait::new(4, 4)).unwrap() == 0b111, 'se corner');

    assert(node.child_at(@PointTrait::new(2, 0)).unwrap() == 0b101, 'nw over ne');
    assert(node.child_at(@PointTrait::new(0, 2)).unwrap() == 0b101, 'nw over sw');
    assert(node.child_at(@PointTrait::new(2, 4)).unwrap() == 0b110, 'sw over se');
    assert(node.child_at(@PointTrait::new(4, 2)).unwrap() == 0b100, 'ne over se');
}

#[test]
fn test_node_split() {
    let mut root = QuadtreeNode::<
        i32, u8, i32
    > {
        path: 1,
        region: AreaTrait::new(PointTrait::new(0, 0), 4, 4),
        values: ArrayTrait::new().span(),
        is_leaf: Option::None,
    };

    let children = root.split_at(PointTrait::new(2, 2));

    assert(children.len() == 4, 'There should be 4 children');
    let ne = children.at(0);
    let nw = children.at(1);
    let sw = children.at(2);
    let se = children.at(3);

    assert(*ne.path == 0b100, 'path ne invalid');
    assert(*nw.path == 0b101, 'path nw invalid');
    assert(*sw.path == 0b110, 'path sw invalid');
    assert(*se.path == 0b111, 'path se invalid');

    assert(ne.region.top() == 0, 'top ne invalid');
    assert(nw.region.top() == 0, 'top nw invalid');
    assert(sw.region.top() == 2, 'top sw invalid');
    assert(se.region.top() == 2, 'top se invalid');

    assert(ne.region.left() == 2, 'left ne invalid');
    assert(se.region.left() == 2, 'left se invalid');
    assert(nw.region.left() == 0, 'right nw invalid');
    assert(sw.region.left() == 0, 'right sw invalid');

    assert(ne.region.bottom() == 2, 'bottom ne invalid');
    assert(nw.region.bottom() == 2, 'bottom nw invalid');
    assert(sw.region.bottom() == 4, 'bottom sw invalid');
    assert(se.region.bottom() == 4, 'bottom se invalid');

    assert(ne.region.right() == 4, 'right ne invalid');
    assert(se.region.right() == 4, 'right se invalid');
    assert(nw.region.right() == 2, 'right nw invalid');
    assert(sw.region.right() == 2, 'right sw invalid');
}

