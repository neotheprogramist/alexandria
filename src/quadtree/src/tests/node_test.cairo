use quadtree::QuadtreeNode;
use quadtree::QuadtreeNodeTrait;
use quadtree::AreaTrait;
use quadtree::PointTrait;


#[test]
fn test_node_child_at() {
    let mut node = QuadtreeNodeTrait::<
        i32, u8, u32
    >::new(AreaTrait::new(PointTrait::new(0, 0), 4, 4), 1);

    assert(node.child_at(@PointTrait::new(1, 1)).is_none(), 'child before split');
    node.split_at(PointTrait::new(2, 2));

    assert(node.child_at(@PointTrait::new(3, 1)).unwrap() == 0b100, 'ne center');
    assert(node.child_at(@PointTrait::new(1, 1)).unwrap() == 0b101, 'nw center');
    assert(node.child_at(@PointTrait::new(1, 3)).unwrap() == 0b110, 'sw center');
    assert(node.child_at(@PointTrait::new(3, 3)).unwrap() == 0b111, 'se center');

    assert(node.child_at(@PointTrait::new(4, 0)).unwrap() == 0b100, 'ne corner');
    assert(node.child_at(@PointTrait::new(0, 0)).unwrap() == 0b101, 'nw corner');
    assert(node.child_at(@PointTrait::new(0, 4)).unwrap() == 0b110, 'sw corner');
    assert(node.child_at(@PointTrait::new(4, 4)).unwrap() == 0b111, 'se corner');

    assert(node.child_at(@PointTrait::new(2, 0)).unwrap() == 0b101, 'nw over ne');
    assert(node.child_at(@PointTrait::new(0, 2)).unwrap() == 0b101, 'nw over sw');
    assert(node.child_at(@PointTrait::new(2, 4)).unwrap() == 0b110, 'sw over se');
    assert(node.child_at(@PointTrait::new(4, 2)).unwrap() == 0b100, 'ne over se');
}

#[test]
fn test_node_split() {
    let mut root = QuadtreeNode::<
        i32, u8, u32
    > {
        path: 1,
        region: AreaTrait::new(PointTrait::new(0, 0), 4, 4),
        values: ArrayTrait::new().span(),
        members: ArrayTrait::new().span(),
        split: Option::None,
    };

    let children = root.split_at(PointTrait::new(2, 2));

    assert(children.len() == 4, 'There should be 4 children');
    let ne = children.at(0);
    let nw = children.at(1);
    let sw = children.at(2);
    let se = children.at(3);

    assert(*ne.path == 0b100, 'path ne invalid');
    assert(*nw.path == 0b101, 'path nw invalid');
    assert(*sw.path == 0b110, 'path sw invalid');
    assert(*se.path == 0b111, 'path se invalid');

    assert(ne.region.top() == 0, 'top ne invalid');
    assert(nw.region.top() == 0, 'top nw invalid');
    assert(sw.region.top() == 2, 'top sw invalid');
    assert(se.region.top() == 2, 'top se invalid');

    assert(ne.region.left() == 2, 'left ne invalid');
    assert(se.region.left() == 2, 'left se invalid');
    assert(nw.region.left() == 0, 'right nw invalid');
    assert(sw.region.left() == 0, 'right sw invalid');

    assert(ne.region.bottom() == 2, 'bottom ne invalid');
    assert(nw.region.bottom() == 2, 'bottom nw invalid');
    assert(sw.region.bottom() == 4, 'bottom sw invalid');
    assert(se.region.bottom() == 4, 'bottom se invalid');

    assert(ne.region.right() == 4, 'right ne invalid');
    assert(se.region.right() == 4, 'right se invalid');
    assert(nw.region.right() == 2, 'right nw invalid');
    assert(sw.region.right() == 2, 'right sw invalid');
}
