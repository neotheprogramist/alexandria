#[cfg(test)]
mod tests;
mod area;
mod point;
mod quadtree;

use quadtree::{Point, Area, Felt252Quadtree, Felt252QuadtreeNode};


//! Quadree implementation.
//!
//! # Example
//! ```
//! // Create a root region at (0, 0) with a width and height of 4
//! let root_region = AreaTrait::new(PointTrait::new(0, 0), 4, 4);
//! // Create a new quadtree on that region
//! let mut tree = QuadtreeTrait::<felt252, felt252>::new(root_region);
//!
//! // Values can be inserted into the tree (at any place for now)
//! tree.insert(0, 42);
//! tree.insert(0, 2137);
//! // and retrieved from it, in the same fashion
//! assert_eq!(*tree.values(0).at(0), 42);
//! assert_eq!(*tree.values(0).at(1), 2137);
//! ```

/// The Quadtree trait takes 3 generic parameters:
/// - T: The type of the value stored in the quadtree
/// - P: The type of the dictionary key used to access the quadtree
trait QuadtreeTrait<T, P, C> {
    /// Creates a new uadtree instance.
    fn new(region: Area<C>) -> Felt252Quadtree<T, P, C>;
    /// Gets the value at the root of the quadtree.
    fn values(ref self: Felt252Quadtree<T, P, C>, path: P) -> Array<T>;
    /// Inserts a region into the quadtree.
    fn insert_point(ref self: Felt252Quadtree<T, P, C>, value: T, point: Point<C>);
    fn insert_region(ref self: Felt252Quadtree<T, P, C>, value: T, region: Area<C>);
    fn insert_at(ref self: Felt252Quadtree<T, P, C>, value: T, path: P);
    /// Splits a region into 4 subregions at a given point.
    fn split(ref self: Felt252Quadtree<T, P, C>, path: P, point: Point<C>);
}
