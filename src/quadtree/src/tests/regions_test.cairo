use quadtree::AreaTrait;
use quadtree::PointTrait;
use quadtree::QuadtreeTrait;


#[test]
fn test_remove_region() {
    // create a root region at (0, 0) with a width and height of 4
    let root_region = AreaTrait::new(PointTrait::new(0, 0), 4, 4);
    let mut tree = QuadtreeTrait::<felt252, felt252, u64>::new(root_region, 1);

    let bigger = AreaTrait::new(PointTrait::new(0, 0), 2, 2);
    let smaller = AreaTrait::new(PointTrait::new(1, 1), 1, 1);

    // should insert into the ne and nwse
    tree.insert_region('nw', bigger);
    tree.insert_region('nwse', smaller);
    assert_eq!(*tree.values(0b101).get(0).unwrap().unbox(), 'nw');
    assert_eq!(*tree.values(0b10111).get(0).unwrap().unbox(), 'nwse');

    // removing a non existing region in existing node should not change anything
    assert(!tree.remove_region('nw', smaller), 'nw removed');
    assert(!tree.remove_region('nwse', bigger), 'nwse removed');

    // should remove from the ne and nwse
    assert(tree.remove_region('nw', bigger), 'nw not removed');
    assert(tree.remove_region('nwse', smaller), 'nwse not removed');
    assert(tree.values(0b101).is_empty(), 'nw not empty');
    assert(tree.values(0b10111).is_empty(), 'nwse not empty');
}

#[test]
#[should_panic]
fn test_remove_region_panicking() {
    let root_region = AreaTrait::new(PointTrait::new(0, 0), 4, 4);
    let mut tree = QuadtreeTrait::<felt252, felt252, u64>::new(root_region, 1);

    tree.remove_region('nw', AreaTrait::new(PointTrait::new(0, 0), 2, 2));
}


#[test]
fn test_insert_region() {
    // create a root region at (0, 0) with a width and height of 4
    let root_region = AreaTrait::new(PointTrait::new(0, 0), 4, 4);
    let mut tree = QuadtreeTrait::<felt252, felt252, u64>::new(root_region, 1);
    tree.split(1, PointTrait::new(2, 2));
    tree.split(0b101, PointTrait::new(1, 1));

    // should insert just into the nw region
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
fn test_query_regions() {
    // create a root region at (0, 0) with a width and height of 4
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
fn test_rect_region() {
    // create a root region at (0, 0) with a width and height of 4
    let root_region = AreaTrait::new(PointTrait::new(0, 0), 4, 4);
    let mut tree = QuadtreeTrait::<felt252, felt252, u64>::new(root_region, 1);
    tree.split(1, PointTrait::new(2, 2));
    tree.split(0b101, PointTrait::new(1, 1));

    // should insert into the ne and right half of the nw region
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
fn test_insert_region_splitting() {
    // create a root region at (0, 0) with a width and height of 8
    let root_region = AreaTrait::new(PointTrait::new(0, 0), 8, 8);
    // every node has at most 2 nodes
    let mut tree = QuadtreeTrait::<felt252, felt252, u64>::new(root_region, 2);

    // split at (4, 4)
    tree.insert_region(42, AreaTrait::new(PointTrait::new(2, 2), 4, 5));

    // in ne region just nesw
    assert(tree.exists(0b100), 'ne does not exist');
    assert(tree.exists(0b10010), 'nesw does not exist');
    assert(!tree.exists(0b1001000), 'nesw is split');
    assert(tree.values(0b10010).len() == 1, 'invalid in nesw');
    assert_eq!(*tree.values(0b10010).get(0).unwrap().unbox(), 42);
    assert(tree.values(0b10000).len() == 0, 'invalid in nene');
    assert(tree.values(0b10001).len() == 0, 'invalid in nenw');
    assert(tree.values(0b10011).len() == 0, 'invalid in nese');

    // in nw region just nwse
    assert(tree.exists(0b101), 'nw does not exist');
    assert(tree.exists(0b10111), 'nwse does not exist');
    assert(!tree.exists(0b1011100), 'nwse is split');
    assert(tree.values(0b10111).len() == 1, 'invalid in nwse');
    assert_eq!(*tree.values(0b10111).get(0).unwrap().unbox(), 42);
    assert(tree.values(0b10100).len() == 0, 'invalid in nwse');
    assert(tree.values(0b10101).len() == 0, 'invalid in nwse');
    assert(tree.values(0b10110).len() == 0, 'invalid in nwse');

    // in sw region swne, swsene and swsenw
    assert(tree.exists(0b110), 'sw does not exist');
    assert(tree.exists(0b11000), 'swne does not exist');
    assert(tree.exists(0b11011), 'swse does not exist');
    assert(tree.exists(0b1101100), 'swsene does not exist');
    assert(tree.exists(0b1101101), 'swsenw does not exist');
    assert(tree.values(0b11000).len() == 1, 'invalid in swne');
    assert(tree.values(0b1101100).len() == 1, 'invalid in swsene');
    assert(tree.values(0b1101101).len() == 1, 'invalid in swsenw');
    assert_eq!(*tree.values(0b11000).get(0).unwrap().unbox(), 42);
    assert_eq!(*tree.values(0b1101100).get(0).unwrap().unbox(), 42);
    assert_eq!(*tree.values(0b1101101).get(0).unwrap().unbox(), 42);
    assert(tree.values(0b11011).len() == 0, 'invalid in swse');
    assert(tree.values(0b1101110).len() == 0, 'invalid in swsesw');
    assert(tree.values(0b1101111).len() == 0, 'invalid in swsese');

    // in se region senw, seswnw and seswne
    assert(tree.exists(0b111), 'se does not exist');
    assert(tree.exists(0b11101), 'senw does not exist');
    assert(tree.exists(0b1111000), 'seswne does not exist');
    assert(tree.exists(0b1111001), 'seswnw does not exist');
    assert(!tree.exists(0b111100100), 'seswnw is split');
    assert(!tree.exists(0b111100100), 'seswnw is split');
    assert(tree.values(0b11101).len() == 1, 'invalid in sene');
    assert(tree.values(0b1111000).len() == 1, 'invalid in seswne');
    assert(tree.values(0b1111001).len() == 1, 'invalid in seswnw');
    assert_eq!(*tree.values(0b11101).get(0).unwrap().unbox(), 42);
    assert_eq!(*tree.values(0b1111000).get(0).unwrap().unbox(), 42);
    assert_eq!(*tree.values(0b1111001).get(0).unwrap().unbox(), 42);
    assert(tree.values(0b11100).len() == 0, 'invalid in swse');
    assert(tree.values(0b1111010).len() == 0, 'invalid in seswne');
    assert(tree.values(0b1111011).len() == 0, 'invalid in seswse');
}
