use quadtree::area::Area;

#[derive(Drop)]
struct Felt252QuadtreeNode<T, C> {
    path: felt252,
    mask: felt252,
    region: Area<C>,
    values: Span<T>,
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
