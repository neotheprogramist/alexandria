#[cfg(test)]
mod tests;
mod area;
mod point;
mod quadtree;
mod node;

use quadtree::{AreaTrait, PointTrait, Area, Point};
use quadtree::{Felt252Quadtree, Felt252QuadtreeImpl};
use node::{QuadtreeNode, QuadtreeNodeTrait};

//! Quadree implementation.
//!
//! # Example
//! ```
//! // Create a root region at (0, 0) with a width and height of 4
//! let root_region = AreaTrait::new(PointTrait::new(0, 0), 4, 4);
//! // Create a new quadtree on that region
//! let mut tree = QuadtreeTrait::<felt252, felt252, u32>::new(root_region, 5)
//!
//! // Values can be inserted into the tree (at any place for now)
//! tree.insert_point(PointTrait::new(1, 2));
//! tree.insert_point(PointTrait::new(3, 4));
//! // and retrieved from it, in the same fashion
//! assert(*tree.points(1).at(0) == PointTrait::new(1, 2), 'Point 1, 2 not in the tree');
//! assert(*tree.points(1).at(1) == PointTrait::new(3, 4), 'Point 3, 44 not in the tree');
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
    fn remove_point(ref self: Felt252Quadtree<T, P, C>, point: Point<C>) -> Option<Point<C>>;
    fn insert_region(ref self: Felt252Quadtree<T, P, C>, value: T, region: Area<C>);
    /// Splits a region into 4 subregions at a given point.
    fn split(ref self: Felt252Quadtree<T, P, C>, path: P, point: Point<C>);
    fn exists(ref self: Felt252Quadtree<T, P, C>, path: P) -> bool;
}

#[test]
fn quadtree_usage() {
    let root_region = AreaTrait::new(PointTrait::new(0, 0), 4, 4);

    let mut tree = QuadtreeTrait::<felt252, felt252, u32>::new(root_region, 5);
    tree.insert_point(PointTrait::new(1, 2));
    tree.insert_point(PointTrait::new(3, 4));
    assert(*tree.points(1).at(0) == PointTrait::new(1, 2), 'Point 1, 2 not in the tree');
    assert(*tree.points(1).at(1) == PointTrait::new(3, 4), 'Point 3, 4 not in the tree');
}
