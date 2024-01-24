use quadtree::Felt252Quadtree;
use quadtree::Felt252QuadtreeImpl;
use quadtree::Felt252QuadtreeNode;

#[test]
fn test_root() {
    let mut tree: Felt252Quadtree<Felt252QuadtreeNode<felt252>> = Felt252QuadtreeImpl::new(2137);
    let root = Felt252QuadtreeImpl::root(ref tree);
    let leaf = match root {
        Felt252QuadtreeNode::Leaf(leaf) => leaf,
        _ => panic!("Root is not a leaf")
    };
    assert_eq!(leaf.value, 2137);
}