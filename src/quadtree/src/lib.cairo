#[cfg(test)]
mod tests;
mod area;
mod point;
mod quadtree;
mod node;

use quadtree::{Point, Area, Felt252Quadtree};
use node::{QuadtreeNode, QuadtreeNodeTrait};

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
    /// Creates a new quadtree instance, all the points in the quadtree 
    /// have to be inside of passed region.
    /// If number of points in a regin exceeds the `spillover_threhold` the node 
    /// is split into 4 children, 2 means every node has at most 2 points.
    fn new(region: Area<C>, spillover_threhold: usize) -> Felt252Quadtree<T, P, C>;
    /// Gets values at the a given path.
    fn values(ref self: Felt252Quadtree<T, P, C>, path: P) -> Array<T>;
    fn points(ref self: Felt252Quadtree<T, P, C>, path: P) -> Array<Point<C>>;
    /// Closest points to a given point.
    fn closes_points(ref self: Felt252Quadtree<T, P, C>, point: Point<C>, n: usize) -> Array<T>;
    /// Queries the quadtree for the regions that contain a given point.
    fn query_regions(ref self: Felt252Quadtree<T, P, C>, point: Point<C>) -> Array<T>;
    /// Inserts a region into the quadtree.
    fn insert_point(ref self: Felt252Quadtree<T, P, C>, point: Point<C>);
    fn insert_region(ref self: Felt252Quadtree<T, P, C>, value: T, region: Area<C>);
    fn insert_at(ref self: Felt252Quadtree<T, P, C>, value: T, path: P);
    /// Splits a region into 4 subregions at a given point.
    fn split(ref self: Felt252Quadtree<T, P, C>, path: P, point: Point<C>);
    fn exists(ref self: Felt252Quadtree<T, P, C>, path: P) -> bool;
}
