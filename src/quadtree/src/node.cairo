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
    fn child_at(self: @QuadtreeNode<T, P, C>, point: @Point<C>) -> Option<P>;
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
    +Zeroable<P>, // Root has zero path of type P
    +Into<P, felt252>, // Dict key is felt252
    +Into<u8, P>, // Adding nested level
    +Add<P>, // Nesting the path
    +Mul<P>, // Nesting the path
    +Add<C>, // Needed for area
    +PointTrait<C>, // Present in the area
> of QuadtreeNodeTrait<T, P, C> {
    fn child_at(self: @QuadtreeNode<T, P, C>, point: @Point<C>) -> Option<P> {
        // type interference hack
        let one: u8 = 1;
        let bottom = one + one;
        let four: P = (bottom + bottom).into();

        match self.is_leaf {
            Option::Some(middle) => Option::Some(
                {
                    match point.lt_x(middle) {
                        true => match point.lt_y(middle) {
                            true => *self.path * four + one.into(),
                            false => *self.path * four + bottom.into(),
                        },
                        false => match point.lt_y(middle) {
                            true => *self.path * four,
                            false => *self.path * four + bottom.into() + one.into()
                        },
                    }
                }
            ),
            Option::None => {
                // the node is leaf
                return Option::None;
            },
        }
    }
}
