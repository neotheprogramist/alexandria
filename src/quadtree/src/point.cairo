/// Represents a 2D point in the quadtree
use core::traits::TryInto;
#[derive(Drop, Copy)]
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
    /// distance between two points, without the `sqrt`
    fn distance_squared(self: @Point<T>, other: @Point<T>) -> T;
    /// checks if lhs is between smaller and greater
    fn between_x(self: @Point<T>, smaller: @Point<T>, greater: @Point<T>) -> bool;
    fn between_y(self: @Point<T>, smaller: @Point<T>, greater: @Point<T>) -> bool;
    /// checks if lhs is less than rhs
    fn lt_x(self: @Point<T>, other: @Point<T>) -> bool;
    fn lt_y(self: @Point<T>, other: @Point<T>) -> bool;
    /// primarily to not require PartialOrd in traits above
    fn distance_to_farther_x(self: @Point<T>, first: @Point<T>, second: @Point<T>) -> T;
    fn distance_to_farther_y(self: @Point<T>, first: @Point<T>, second: @Point<T>) -> T;
}

impl PointImpl<T, +Copy<T>, +Drop<T>, +PartialOrd<T>, +Add<T>, +Sub<T>, +Mul<T>> of PointTrait<T> {
    fn new(x: T, y: T) -> Point<T> {
        Point { x, y }
    }

    fn x(self: @Point<T>) -> @T {
        self.x
    }

    fn y(self: @Point<T>) -> @T {
        self.y
    }

    fn distance_squared(self: @Point<T>, other: @Point<T>) -> T {
        let x = match *self.x > *other.x {
            true => *self.x - *other.x,
            false => *other.x - *self.x
        };
        let y = match *self.x > *other.x {
            true => *self.x - *other.x,
            false => *other.x - *self.x
        };
        x * x + y * y
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

    fn distance_to_farther_x(self: @Point<T>, first: @Point<T>, second: @Point<T>) -> T {
        let first_x = match *self.x > *first.x {
            true => *self.x - *first.x,
            false => *first.x - *self.x
        };
        let second_x = match *self.x > *second.x {
            true => *self.x - *second.x,
            false => *second.x - *self.x
        };

        match first_x < second_x {
            true => first_x,
            false => second_x
        }
    }

    fn distance_to_farther_y(self: @Point<T>, first: @Point<T>, second: @Point<T>) -> T {
        let first_y = match *self.y > *first.y {
            true => *self.y - *first.y,
            false => *first.y - *self.y
        };
        let second_y = match *self.y > *second.y {
            true => *self.y - *second.y,
            false => *second.y - *self.y
        };

        match first_y < second_y {
            true => first_y,
            false => second_y
        }
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

    fn distance_squared(self: @Point<felt252>, other: @Point<felt252>) -> felt252 {
        let self_x: u256 = (*self.x).into();
        let other_x: u256 = (*other.x).into();

        let x = match self_x > other_x {
            true => *self.x - *other.x,
            false => *other.x - *self.x
        };

        let self_y: u256 = (*self.y).into();
        let other_y: u256 = (*other.y).into();
        let y = match self_y > other_y {
            true => *self.x - *other.x,
            false => *other.x - *self.x
        };

        x * x + y * y
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

    fn distance_to_farther_x(
        self: @Point<felt252>, first: @Point<felt252>, second: @Point<felt252>
    ) -> felt252 {
        let self_x: u256 = (*self.x).into();
        let first_x: u256 = (*first.x).into();
        let second_x: u256 = (*second.x).into();

        let first = match self_x > first_x {
            true => self_x - first_x,
            false => first_x - self_x
        };
        let second = match self_x > second_x {
            true => self_x - second_x,
            false => second_x - self_x
        };

        match first < second {
            true => first.try_into().unwrap(),
            false => second.try_into().unwrap()
        }
    }

    fn distance_to_farther_y(
        self: @Point<felt252>, first: @Point<felt252>, second: @Point<felt252>
    ) -> felt252 {
        let self_y: u256 = (*self.y).into();
        let first_y: u256 = (*first.y).into();
        let second_y: u256 = (*second.y).into();

        let first = match self_y > first_y {
            true => self_y - first_y,
            false => first_y - self_y
        };
        let second = match self_y > second_y {
            true => self_y - second_y,
            false => second_y - self_y
        };

        match first < second {
            true => first.try_into().unwrap(),
            false => second.try_into().unwrap()
        }
    }
}
