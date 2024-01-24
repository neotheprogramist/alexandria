#[cfg(test)]
mod tests;

trait QuadtreeTrait<Q, N, T> {
    /// Creates a new Stack instance.
    fn new(root: T) -> Q;
    /// Creates a new Stack instance.
    fn root(ref self: Q) -> N;
    // /// Pushes a new value onto the stack.
    // fn push(ref self: S, value: T);
    // /// Removes the last item from the stack and returns it, or None if the stack is empty.
    // fn pop(ref self: S) -> Option<T>;
    // /// Returns the last item from the stack without removing it, or None if the stack is empty.
    // fn peek(ref self: S) -> Option<T>;
    // /// Returns the number of items in the stack.
    // fn len(self: @S) -> usize;
    // /// Returns true if the stack is empty.
    // fn is_empty(self: @S) -> bool;
}

struct Felt252Quadtree<N> {
    elements: Felt252Dict<N>,
}

#[derive(Drop, Copy)]
enum Felt252QuadtreeNode<T> {
    Leaf: Felt252QuadtreeLeaf<T>,
    Branch: Felt252QuadtreeBranch,
}

#[derive(Drop, Copy)]
struct Felt252QuadtreeLeaf<T> {
    value: T,
}

#[derive(Drop, Copy)]
struct Felt252QuadtreeBranch {
    path: felt252,
    mask: felt252,
}

impl Felt252QuadtreeImpl<
    T,
    +Copy<T>,
    +Drop<T>,
    +Felt252DictValue<Felt252QuadtreeNode<T>>,
> of QuadtreeTrait<Felt252Quadtree<Felt252QuadtreeNode<T>>, Felt252QuadtreeNode<T>, T> {
    fn new(root: T) -> Felt252Quadtree<Felt252QuadtreeNode<T>> {
        let node = Felt252QuadtreeNode::Leaf(
            Felt252QuadtreeLeaf {
                value: root,
            }
        );
        let mut elements = Default::default();
        elements.insert(0, node);
        Felt252Quadtree { elements }
    }

    fn root(ref self: Felt252Quadtree<Felt252QuadtreeNode<T>>) -> Felt252QuadtreeNode<T> {
        self.elements.get(0)
    }
}
