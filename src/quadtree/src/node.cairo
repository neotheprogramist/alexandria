use quadtree::area::Area;

#[derive(Drop, Copy)]
enum Felt252QuadtreeNode<T, C> {
    Branch: Felt252QuadtreeBranch,
    Leaf: Felt252QuadtreeLeaf<T, C>,
    Empty: (),
}

#[derive(Drop, Copy)]
struct Felt252QuadtreeLeaf<T, C> {
    area: Area<C>,
    value: T,
}

#[derive(Drop, Copy)]
struct Felt252QuadtreeBranch {
    path: felt252,
    mask: felt252,
}

