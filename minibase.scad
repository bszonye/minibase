// base     size of the base rim (diameter or [width, length])
// slope    horizontal component of the wall slope (number or xy-vector)
// height   height of the base
module base_hull(base=25, face=undef, slope=1, height=3.25) {
    base_xy = is_num(base) ? [base, base] : base;
    slope_xy = is_num(slope) ? [slope, slope] : slope;
    face_xy = is_undef(face) ? base_xy - 2 * slope_xy : face;

    dbase = max(base_xy);
    dface = max(face_xy);
    hull() {
        scale(base_xy / dbase) cylinder(d2=dbase, d1=0, h=height);
        scale(face_xy / dface) cylinder(d1=dface, d2=0, h=height);
    }
}

module base_linear(base=25, slope=1, height=3.25) {
    base_xy = is_num(base) ? [base, base] : base;
    slope_xy = is_num(slope) ? [slope, slope] : slope;
    face_xy = base_xy - 2 * slope_xy;

    d = max(face_xy);
    face_scale = face_xy / d;
    base_scale = [
        for (i = [0:1:len(base_xy)-1]) base_xy[i] / face_xy[i]
    ];
    linear_extrude(height=height, scale=base_scale)
        scale(face_scale) circle(d=d);
}

module crosshair(width=2, outside=25, height=3.25, gap=16) {
    difference() {
        union() {
            cube([outside, width, 2*height], center=true);
            cube([width, outside, 2*height], center=true);
        }
        cube([gap, gap, 3*height], center=true);
    }
}

// base_hull();
// base_hull(base=[60, 80], slope=-5);
// base_hull(base=[80, 60], slope=[60, 80]);

// base_linear();
// base_linear(base=[60, 80], slope=-5);
// base_linear(base=[60, 80], slope=[80, 60]);

// vim: ai si sw=4 et
