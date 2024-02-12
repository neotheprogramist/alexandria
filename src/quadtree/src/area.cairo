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
    fn new_from_points(top: T, left: T, bottom: T, right: T) -> Area<T>;
    /// Checks if the area contains a point
    fn contains(self: @Area<T>, point: @Point<T>) -> bool;
    /// Checks if the area intersects or contains another area
    fn intersects(self: @Area<T>, other: @Area<T>) -> bool;
    /// Distance to the farthest point in the area
    fn distance_at_most(self: @Area<T>, point: @Point<T>) -> T;
    /// Getters for bouds of the area
    fn top(self: @Area<T>) -> T;
    fn left(self: @Area<T>) -> T;
    fn bottom(self: @Area<T>) -> T;
    fn right(self: @Area<T>) -> T;
    fn top_left(self: @Area<T>) -> @Point<T>;
    fn bottom_right(self: @Area<T>) -> @Point<T>;
}

impl AreaImpl<T, +Add<T>, +Mul<T>, +Copy<T>, +Drop<T>, +PointTrait<T>> of AreaTrait<T> {
    fn new(top_left: Point<T>, width: T, height: T) -> Area<T> {
        Area {
            top_left: top_left,
            bottom_right: Point { x: top_left.x + width, y: top_left.y + height },
        }
    }

    fn new_from_points(top: T, left: T, bottom: T, right: T) -> Area<T> {
        Area { top_left: Point { x: left, y: top }, bottom_right: Point { x: right, y: bottom }, }
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

    fn distance_at_most(self: @Area<T>, point: @Point<T>) -> T {
        let x = point.distance_to_farther_x(self.top_left, self.bottom_right);
        let y = point.distance_to_farther_y(self.top_left, self.bottom_right);

        x * x + y * y
    }

    fn top(self: @Area<T>) -> T {
        *self.top_left.y
    }

    fn left(self: @Area<T>) -> T {
        *self.top_left.x
    }

    fn bottom(self: @Area<T>) -> T {
        *self.bottom_right.y
    }

    fn right(self: @Area<T>) -> T {
        *self.bottom_right.x
    }

    fn top_left(self: @Area<T>) -> @Point<T> {
        self.top_left
    }

    fn bottom_right(self: @Area<T>) -> @Point<T> {
        self.bottom_right
    }
}
