use core::debug::PrintTrait;
use core::traits::Into;
use core::box::BoxTrait;
use core::option::OptionTrait;
use core::array::ArrayTrait;
use core::nullable::{nullable_from_box, match_nullable, FromNullableResult};
use quadtree::quadtree::{QuadtreeTrait, QuadtreeNode, Felt252QuadtreeImpl};
use quadtree::area::{Area, AreaTrait};
use quadtree::point::{Point, PointTrait};

#[test]
fn test_remove_point() {
    let root_region = AreaTrait::new(PointTrait::new(0, 0), 4, 4);
    let mut tree = QuadtreeTrait::<felt252, felt252, u64>::new(root_region, 2);
    tree.insert_point(PointTrait::new(1, 1));
    tree.insert_point(PointTrait::new(1, 2));
    tree.insert_point(PointTrait::new(2, 1));

    // at this point all the points are in the nw node
    assert(tree.points(0b101).len() == 3, 'invalid nw before');

    // remove a point that does not exist
    assert(tree.remove_point(PointTrait::new(1, 3)).is_none(), 'remove nonexisting other q');
    assert(tree.remove_point(PointTrait::new(2, 2)).is_none(), 'remove nonexisting same q');

    // remove the first node
    assert(tree.remove_point(PointTrait::new(1, 1)).is_some(), 'remove existing first');
    // remove the last node
    assert(tree.remove_point(PointTrait::new(2, 1)).is_some(), 'remove existing last');
    // remove the only remaining node
    assert(tree.remove_point(PointTrait::new(1, 2)).is_some(), 'remove existing only');
}

#[test]
fn test_spillover() {
    // create a root region at (0, 0) with a width and height of 12
    let root_region = AreaTrait::new(PointTrait::new(0, 0), 12, 12);
    // every node has at most 2 nodes
    let mut tree = QuadtreeTrait::<felt252, felt252, u64>::new(root_region, 2);

    // values can be inserted into the tree (at any place for now)
    tree.insert_point(PointTrait::new(1, 1));
    tree.insert_point(PointTrait::new(1, 1));
    tree.insert_point(PointTrait::new(1, 1));

    assert(tree.points(1).len() == 3, 'invalid root before');
    assert(!tree.exists(0b101), 'nw exists before');

    // this insert should split the root node at (6, 6)
    tree.insert_point(PointTrait::new(1, 2));

    assert(tree.points(1).len() == 0, 'nonempty root after');
    assert(tree.exists(0b101), 'nw nonexisting after');
    assert(tree.points(0b101).len() == 4, 'invalid in 0b101 after');
    assert(!tree.exists(0b10101), 'nwnw exists after');

    // this insert should split the root node at (3, 3)
    tree.insert_point(PointTrait::new(4, 4));

    assert(tree.points(1).len() == 0, 'nonempty root after 2');
    assert(tree.points(0b101).len() == 0, 'invalid nw after 2');
    assert(tree.exists(0b10101), 'nonexisting nwnw after 2');
    assert(tree.points(0b10101).len() == 4, 'invalid nwnw after 2');
    assert(tree.exists(0b10111), 'nonexisting nwse after 2');
    assert(tree.points(0b10111).len() == 1, 'invalid nwse after 2');
}


#[test]
fn test_insert_point() {
    // create a root region at (0, 0) with a width and height of 4
    let root_region = AreaTrait::new(PointTrait::new(0, 0), 4, 4);
    let mut tree = QuadtreeTrait::<felt252, felt252, u64>::new(root_region, 1);
    tree.split(1, PointTrait::new(2, 2));

    // balues can be inserted into the tree (at any place for now)
    tree.insert_point(PointTrait::new(1, 1));

    // and retrieved from it, in the same fashion
    assert(tree.points(0b101).get(0).is_some(), 'nw does not exist');
}


#[test]
fn test_split() {
    let root_region = AreaTrait::new(PointTrait::new(0, 0), 4, 4);
    let mut tree = QuadtreeTrait::<felt252, felt252, u64>::new(root_region, 100);
    tree.split(1, PointTrait::new(1, 1));
    tree.split(0b101, PointTrait::new(1, 1));

    assert(tree.values(1).is_empty(), 'root does not exist');

    assert(tree.values(0b100).is_empty(), 'ne does not exist');
    assert(tree.values(0b101).is_empty(), 'nw does not exist');
    assert(tree.values(0b101).is_empty(), 'se does not exist');
    assert(tree.values(0b111).is_empty(), 'sw does not exist');

    assert(tree.values(0b10100).is_empty(), 'ne of se does not exist');
    assert(tree.values(0b10101).is_empty(), 'nw of se does not exist');
    assert(tree.values(0b10110).is_empty(), 'se of se does not exist');
    assert(tree.values(0b10111).is_empty(), 'sw of se does not exist');
}

#[test]
#[should_panic]
fn test_split_too_many() {
    let root_region = AreaTrait::new(PointTrait::new(0, 0), 4, 4);
    let mut tree = QuadtreeTrait::<felt252, felt252, u64>::new(root_region, 1);
    tree.split(1, PointTrait::new(1, 1));

    assert(tree.values(8).is_empty(), 'out of bounds exists');
}
