use core::option::OptionTrait;
use core::array::ArrayTrait;
use core::nullable::{nullable_from_box, match_nullable, FromNullableResult};
use quadtree::quadtree::{QuadtreeTrait, Felt252QuadtreeNode, Felt252QuadtreeImpl};
use quadtree::area::{Area, AreaTrait};
use quadtree::point::{Point, PointTrait};


#[test]
fn test_root() {
    // Create a root region at (0, 0) with a width and height of 4
    let root_region = AreaTrait::new(PointTrait::new(0, 0), 4, 4);
    // Create a new quadtree on that region
    let mut tree = QuadtreeTrait::<felt252, felt252, u64>::new(root_region);

    // Values can be inserted into the tree (at any place for now)
    tree.insert_at(42, 1);
    tree.insert_at(2137, 1);
    // and retrieved from it, in the same fashion
    assert_eq!(*tree.values(1).at(0), 42);
    assert_eq!(*tree.values(1).at(1), 2137);
}

#[test]
fn test_split() {
    let root_region = AreaTrait::new(PointTrait::new(0, 0), 4, 4);
    let mut tree = QuadtreeTrait::<felt252, felt252, u64>::new(root_region);
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
    let mut tree = QuadtreeTrait::<felt252, felt252, u64>::new(root_region);
    tree.split(1, PointTrait::new(1, 1));

    assert(tree.values(8).is_empty(), 'out of bounds exists');
}


#[test]
fn point_test() {
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
fn area_test() {
    let p = PointTrait::new(21, 37);
    let a = AreaTrait::new(p, 10, 10);

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
