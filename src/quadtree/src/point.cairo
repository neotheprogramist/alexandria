/// Represents a 2D point in the quadtree
use core::traits::TryInto;
#[derive(Drop, Clone, Copy)]
struct Point<T> {
    x: T,
    y: T,
}

trait PointTrait<T> {
    /// Create a new point
    fn new(x: T, y: T) -> Point<T>;
    /// Gets a coordinate
    fn x(self: @Point<T>) -> @T;
    fn y(self: @Point<T>) -> @T;
    /// checks if lhs is between smaller and greater
    fn between_x(self: @Point<T>, smaller: @Point<T>, greater: @Point<T>) -> bool;
    fn between_y(self: @Point<T>, smaller: @Point<T>, greater: @Point<T>) -> bool;
    /// checks if lhs is less than rhs
    fn lt_x(self: @Point<T>, other: @Point<T>) -> bool;
    fn lt_y(self: @Point<T>, other: @Point<T>) -> bool;
}

impl PointImpl<T, +Copy<T>, +Drop<T>, +PartialOrd<T>> of PointTrait<T> {
    fn new(x: T, y: T) -> Point<T> {
        Point { x, y }
    }

    fn x(self: @Point<T>) -> @T {
        self.x
    }

    fn y(self: @Point<T>) -> @T {
        self.y
    }

    fn between_x(self: @Point<T>, smaller: @Point<T>, greater: @Point<T>) -> bool {
        *self.x >= *smaller.x && *self.x <= *greater.x
    }

    fn between_y(self: @Point<T>, smaller: @Point<T>, greater: @Point<T>) -> bool {
        *self.y >= *smaller.y && *self.y <= *greater.y
    }

    fn lt_x(self: @Point<T>, other: @Point<T>) -> bool {
        *self.x < *other.x
    }

    fn lt_y(self: @Point<T>, other: @Point<T>) -> bool {
        *self.y < *other.y
    }
}

// Needed as felt252 does not implement PartialOrd
impl PointFelt252Impl of PointTrait<felt252> {
    fn new(x: felt252, y: felt252) -> Point<felt252> {
        Point { x, y }
    }

    fn x(self: @Point<felt252>) -> @felt252 {
        self.x
    }

    fn y(self: @Point<felt252>) -> @felt252 {
        self.y
    }

    // slighly more efficient than comparisons as into is only called once
    fn between_x(
        self: @Point<felt252>, smaller: @Point<felt252>, greater: @Point<felt252>
    ) -> bool {
        let x: u256 = (*self.x).into();
        let smaller_x: u256 = (*smaller.x).into();
        let greater_x: u256 = (*greater.x).into();
        x >= smaller_x && x <= greater_x
    }

    // slighly more efficient than comparisons as into is only called once
    fn between_y(
        self: @Point<felt252>, smaller: @Point<felt252>, greater: @Point<felt252>
    ) -> bool {
        let y: u256 = (*self.y).into();
        let smaller_y: u256 = (*smaller.y).into();
        let greater_y: u256 = (*greater.y).into();
        y >= smaller_y && y <= greater_y
    }

    fn lt_x(self: @Point<felt252>, other: @Point<felt252>) -> bool {
        let x: u256 = (*self.x).into();
        let other_x: u256 = (*other.x).into();
        x < other_x
    }

    fn lt_y(self: @Point<felt252>, other: @Point<felt252>) -> bool {
        let y: u256 = (*self.y).into();
        let other_y: u256 = (*other.y).into();
        y < other_y
    }
}
