use core::nullable::{nullable_from_box, match_nullable, FromNullableResult};
use quadtree::QuadtreeTrait;
use quadtree::Felt252Quadtree;
use quadtree::Felt252QuadtreeImpl;
use quadtree::Felt252QuadtreeNode;
use quadtree::Felt252QuadtreeLeaf;
use quadtree::Felt252QuadtreeBranch;

#[test]
fn test_root() {
    let root = Felt252QuadtreeNode::Leaf(Felt252QuadtreeLeaf::<felt252> {
        value: 2137
    });
    let mut tree = QuadtreeTrait::new(root);
    let root = Felt252QuadtreeImpl::root(ref tree);
    let leaf = match root {
        Felt252QuadtreeNode::Leaf(leaf) => leaf,
        _ => panic!("Root is not a leaf")
    };
    assert_eq!(leaf.value, 2137);
}