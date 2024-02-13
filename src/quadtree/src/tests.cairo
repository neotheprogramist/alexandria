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
fn test_spillover() {
    // Create a root region at (0, 0) with a width and height of 4
    let root_region = AreaTrait::new(PointTrait::new(0, 0), 12, 12);
    // Every node has at most 2 nodes
    let mut tree = QuadtreeTrait::<felt252, felt252, u64>::new(root_region, 2);

    // Values can be inserted into the tree (at any place for now)
    tree.insert_point(PointTrait::new(1, 1));
    tree.insert_point(PointTrait::new(1, 1));
    tree.insert_point(PointTrait::new(1, 1));

    assert(tree.points(1).len() == 3, 'invalid number in root');
    assert(!tree.exists(0b101), 'nw exists before split');

    tree.insert_point(PointTrait::new(1, 2));

    assert(tree.points(1).len() == 0, 'number in root not changed');
    assert(tree.exists(0b101), 'nw not existing after spill');
    assert(tree.points(0b101).len() == 4, 'invalid number in 0b101');
}

#[test]
fn test_root() {
    // Create a root region at (0, 0) with a width and height of 4
    let root_region = AreaTrait::new(PointTrait::new(0, 0), 4, 4);
    // Create a new quadtree on that region
    let mut tree = QuadtreeTrait::<felt252, felt252, u64>::new(root_region, 1);

    // Values can be inserted into the tree (at any place for now)
    tree.insert_at(42, 1);
    tree.insert_at(2137, 1);
    // and retrieved from it, in the same fashion
    assert_eq!(*tree.values(1).at(0), 42);
    assert_eq!(*tree.values(1).at(1), 2137);
}

#[test]
fn test_insert_point() {
    // Create a root region at (0, 0) with a width and height of 4
    let root_region = AreaTrait::new(PointTrait::new(0, 0), 4, 4);
    let mut tree = QuadtreeTrait::<felt252, felt252, u64>::new(root_region, 1);
    tree.split(1, PointTrait::new(2, 2));

    // Values can be inserted into the tree (at any place for now)
    tree.insert_point(PointTrait::new(1, 1));

    // and retrieved from it, in the same fashion
    assert(tree.points(0b101).get(0).is_some(), 'nw does not exist');
}

#[test]
fn test_insert_region() {
    // Create a root region at (0, 0) with a width and height of 4
    let root_region = AreaTrait::new(PointTrait::new(0, 0), 4, 4);
    let mut tree = QuadtreeTrait::<felt252, felt252, u64>::new(root_region, 1);
    tree.split(1, PointTrait::new(2, 2));
    tree.split(0b101, PointTrait::new(1, 1));

    // Should insert just into the nw region
    tree.insert_region(42, AreaTrait::new(PointTrait::new(0, 0), 2, 2));

    assert_eq!(*tree.values(0b101).get(0).unwrap().unbox(), 42);

    assert(tree.values(1).is_empty(), 'root node not empty');
    assert(tree.values(0b100).is_empty(), 'ne node not empty');
    assert(tree.values(0b110).is_empty(), 'se node not empty');
    assert(tree.values(0b111).is_empty(), 'sw node not empty');

    assert(tree.values(0b10100).is_empty(), 'ne of nw node not empty');
    assert(tree.values(0b10101).is_empty(), 'ne of nw node not empty');
    assert(tree.values(0b10110).is_empty(), 'se of nw node not empty');
    assert(tree.values(0b10111).is_empty(), 'sw of nw node not empty');
}

#[test]
fn test_rect_region() {
    // Create a root region at (0, 0) with a width and height of 4
    let root_region = AreaTrait::new(PointTrait::new(0, 0), 4, 4);
    let mut tree = QuadtreeTrait::<felt252, felt252, u64>::new(root_region, 1);
    tree.split(1, PointTrait::new(2, 2));
    tree.split(0b101, PointTrait::new(1, 1));

    // Should insert into the ne and right half of the nw region
    tree.insert_region(42, AreaTrait::new(PointTrait::new(1, 0), 3, 2));

    assert(tree.values(1).is_empty(), 'root node not empty');
    assert_eq!(*tree.values(0b100).get(0).unwrap().unbox(), 42);
    assert(tree.values(0b101).is_empty(), 'ne node not empty');
    assert(tree.values(0b110).is_empty(), 'se node not empty');
    assert(tree.values(0b111).is_empty(), 'sw node not empty');

    assert_eq!(*tree.values(0b10100).get(0).unwrap().unbox(), 42);
    assert(tree.values(0b10101).is_empty(), 'ne of nw node not empty');
    assert(tree.values(0b10110).is_empty(), 'se of nw node not empty');
    assert_eq!(*tree.values(0b10111).get(0).unwrap().unbox(), 42);
}

#[test]
fn test_query_regions() {
    // Create a root region at (0, 0) with a width and height of 4
    let root_region = AreaTrait::new(PointTrait::new(0, 0), 4, 4);
    let mut tree = QuadtreeTrait::<felt252, felt252, u64>::new(root_region, 1);
    tree.split(1, PointTrait::new(2, 2));
    tree.split(0b101, PointTrait::new(1, 1));

    tree.insert_region('whole', AreaTrait::new(PointTrait::new(0, 0), 4, 4));
    tree.insert_region('rect', AreaTrait::new(PointTrait::new(1, 0), 3, 2));
    tree.insert_region('nw', AreaTrait::new(PointTrait::new(0, 0), 2, 2));
    tree.insert_region('ne of nw', AreaTrait::new(PointTrait::new(1, 0), 1, 1));
    tree.insert_region('sw of nw', AreaTrait::new(PointTrait::new(0, 1), 1, 1));
    tree.insert_region('se of nw', AreaTrait::new(PointTrait::new(1, 1), 1, 1));
    tree.insert_region('se', AreaTrait::new(PointTrait::new(2, 2), 2, 2));

    let mut query_small = tree.query_regions(PointTrait::new(2, 1));
    assert(query_small.pop_front().unwrap() == 'whole', 'no region whole');
    assert(query_small.pop_front().unwrap() == 'nw', 'no region rect');
    assert(query_small.pop_front().unwrap() == 'rect', 'no region rect');
    assert(query_small.pop_front().unwrap() == 'ne of nw', 'no region ne of nw');
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


#[test]
fn test_point() {
    let p = @PointTrait::new(21, 37);
    assert_eq!(*p.x(), 21);
    assert_eq!(*p.y(), 37);

    assert(!p.between_x(@PointTrait::new(22, 37), @PointTrait::new(23, 37)), 'left contains');
    assert(p.between_x(@PointTrait::new(21, 37), @PointTrait::new(23, 37)), 'left barely contains');
    assert(p.between_x(@PointTrait::new(20, 37), @PointTrait::new(23, 37)), 'does not contain');
    assert(
        p.between_x(@PointTrait::new(20, 37), @PointTrait::new(21, 37)), 'right barely contains'
    );
    assert(!p.between_x(@PointTrait::new(19, 37), @PointTrait::new(20, 37)), 'right contains');

    assert(!p.between_y(@PointTrait::new(21, 38), @PointTrait::new(21, 39)), 'top contains');
    assert(p.between_y(@PointTrait::new(21, 37), @PointTrait::new(21, 39)), 'top barely contains');
    assert(p.between_y(@PointTrait::new(21, 36), @PointTrait::new(21, 39)), 'does not contain');
    assert(
        p.between_y(@PointTrait::new(21, 36), @PointTrait::new(21, 37)), 'bottom barely contains'
    );
    assert(!p.between_y(@PointTrait::new(21, 35), @PointTrait::new(21, 36)), 'bottom contains');
}


#[test]
fn test_area() {
    let p = PointTrait::new(21, 37);
    let a = AreaTrait::<u32>::new(p, 10, 10);

    assert(a.intersects(@a), 'not intersecting with itself');
    assert(!a.intersects(@AreaTrait::new(PointTrait::new(10, 37), 10, 10)), 'left intersects');
    assert(!a.intersects(@AreaTrait::new(PointTrait::new(32, 37), 10, 10)), 'right intersects');
    assert(!a.intersects(@AreaTrait::new(PointTrait::new(21, 26), 10, 10)), 'top intersects');
    assert(!a.intersects(@AreaTrait::new(PointTrait::new(21, 48), 10, 10)), 'bottom intersects');

    assert(
        !a.intersects(@AreaTrait::new(PointTrait::new(11, 37), 10, 10)), 'left barely intersect'
    );
    assert(
        !a.intersects(@AreaTrait::new(PointTrait::new(31, 37), 10, 10)), 'right barely intersect'
    );
    assert(!a.intersects(@AreaTrait::new(PointTrait::new(21, 27), 10, 10)), 'top barely intersect');
    assert(
        !a.intersects(@AreaTrait::new(PointTrait::new(21, 47), 10, 10)), 'bottom barely intersect'
    );

    assert(a.intersects(@AreaTrait::new(PointTrait::new(20, 36), 10, 10)), 'top left intersects');
    assert(a.intersects(@AreaTrait::new(PointTrait::new(30, 36), 10, 10)), 'top right intersects');
    assert(
        a.intersects(@AreaTrait::new(PointTrait::new(20, 46), 10, 10)), 'bottom left intersects'
    );
    assert(
        a.intersects(@AreaTrait::new(PointTrait::new(30, 46), 10, 10)), 'bottom right intersects'
    );

    assert(a.intersects(@AreaTrait::new(PointTrait::new(21, 37), 10, 10)), 'overlaps intersects');
    assert(
        a.intersects(@AreaTrait::new(PointTrait::new(16, 32), 20, 20)), 'greater overlap intersects'
    );
    assert(
        a.intersects(@AreaTrait::new(PointTrait::new(22, 38), 5, 5)), 'smaller overlap intersects'
    );

    assert(!a.contains(@PointTrait::new(20, 36)), 'top left contains');
    assert(!a.contains(@PointTrait::new(32, 36)), 'top right contains');
    assert(!a.contains(@PointTrait::new(20, 46)), 'bottom left contains');
    assert(!a.contains(@PointTrait::new(32, 46)), 'bottom right contains');

    assert(a.contains(@PointTrait::new(21, 37)), 'top left does not contains');
    assert(a.contains(@PointTrait::new(31, 37)), 'top right does not contains');
    assert(a.contains(@PointTrait::new(21, 47)), 'bottom left does not contains');
    assert(a.contains(@PointTrait::new(31, 47)), 'bottom right does not contains');
    assert(a.contains(@PointTrait::new(25, 41)), 'center does not contains');
}
