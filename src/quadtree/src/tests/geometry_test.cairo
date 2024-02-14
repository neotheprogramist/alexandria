use quadtree::PointTrait;
use quadtree::AreaTrait;

#[test]
fn test_point() {
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
fn test_area_intersects() {
    let p = PointTrait::new(21, 37);
    let a = AreaTrait::<u32>::new(p, 10, 10);

    assert(a.intersects(@a), 'not intersecting with itself');
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

}


fn test_area_contains() {
    let p = PointTrait::new(21, 37);
    let a = AreaTrait::<u32>::new(p, 10, 10);

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