use quadtree::QuadtreeTrait;
use quadtree::Felt252Quadtree;
use quadtree::Felt252QuadtreeImpl;
use quadtree::Felt252QuadtreeNode;
use quadtree::Felt252QuadtreeLeaf;
use quadtree::Felt252QuadtreeBranch;

#[test]
fn test_root() {
    // let _root = Felt252QuadtreeNode::Leaf(Felt252QuadtreeLeaf::<felt252> {
    //     value: 2137
    // });

    // let mut tree = QuadtreeTrait::<Felt252Quadtree::<Felt252QuadtreeNode::<felt252>>, Felt252QuadtreeNode::<felt252>>::new(root);
    // let mut tree = QuadtreeTrait::new(root);
    // let _v = quadtree::V { v: 2137 };
    let mut _tree = QuadtreeTrait::<felt252>::new();
    // let root = Felt252QuadtreeImpl::root(ref tree);
    // let leaf = match root {
    //     Felt252QuadtreeNode::Leaf(leaf) => leaf,
    //     _ => panic!("Root is not a leaf")
    // };
    // assert_eq!(leaf.value, 2137);
}