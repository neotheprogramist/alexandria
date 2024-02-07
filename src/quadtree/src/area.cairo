use quadtree::point::{Point, PointTrait, PointImpl};

/// Represents an 2D area in the quadtree
#[derive(Drop, Copy)]
struct Area<T> {
    top_left: Point<T>,
    bottom_right: Point<T>,
}

trait AreaTrait<T> {
    /// Creates a new area
    fn new(top_left: Point<T>, width: T, height: T) -> Area<T>;
    /// Checks if the area contains a point
    fn contains(self: @Area<T>, point: @Point<T>) -> bool;
    /// Checks if the area intersects or contains another area
    fn intersects(self: @Area<T>, other: @Area<T>) -> bool;
}

impl AreaTraitImpl<T, +Add<T>, +Copy<T>, +Drop<T>, +PointTrait<T>> of AreaTrait<T> {
    fn new(top_left: Point<T>, width: T, height: T) -> Area<T> {
        Area {
            top_left: top_left,
            bottom_right: Point { x: top_left.x + width, y: top_left.y + height },
        }
    }

    fn contains(self: @Area<T>, point: @Point<T>) -> bool {
        point.between_x(self.top_left, self.bottom_right)
            && point.between_y(self.top_left, self.bottom_right)
    }

    fn intersects(self: @Area<T>, other: @Area<T>) -> bool {
        self.top_left.lt_x(other.bottom_right)
            && other.top_left.lt_x(self.bottom_right)
            && self.top_left.lt_y(other.bottom_right)
            && other.top_left.lt_y(self.bottom_right)
    }
}
