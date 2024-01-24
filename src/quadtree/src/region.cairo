struct QuadtreePoint<T> {
    x: T,
    y: T,
}

struct QuadtreeRegion<T> {
    top_left: QuadtreePoint<T>,
    bottom_right: QuadtreePoint<T>,
}

trait QuadtreeArea<T> {
    fn new(top_left: QuadtreePoint<T>, width: T, height: T) -> QuadtreeRegion<T>;
    fn contains(self: @QuadtreeRegion<T>, point: @QuadtreePoint<T>) -> bool;
    fn intersects(self: @QuadtreeRegion<T>, other: @QuadtreeRegion<T>) -> bool;
}

impl QuadtreeAreaImpl of QuadtreeRegion<T> {
    fn new(top_left: QuadtreePoint<T>, width: T, height: T) -> QuadtreeRegion<T> {
        QuadtreeRegion {
            top_left: top_left,
            bottom_right: QuadtreePoint{ 
                x: top_left.x + width,
                y: top_left.y + height
            },
        }
    }
    
    fn contains(self: @QuadtreeRegion<T>, point: @QuadtreePoint<T>) -> bool {
        point.x >= self.top_left.x && point.x <= self.bottom_right.x &&
        point.y >= self.top_left.y && point.y <= self.bottom_right.y
    }

    fn intersects(self: @QuadtreeRegion<T>, other: @QuadtreeRegion<T>) -> bool {
        self.top_left.x <= other.bottom_right.x && self.bottom_right.x >= other.top_left.x &&
        self.top_left.y <= other.bottom_right.y && self.bottom_right.y >= other.top_left.y
    }
}
