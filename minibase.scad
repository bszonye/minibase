// base     size of the base rim (diameter or [width, length])
// slope    horizontal component of the wall slope (number or xy-vector)
// height   height of the base
module minibase_hull(base=25, face=undef, slope=1, height=3.25) {
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

module minibase(base=25, height=3.25, slope=1, wall=1.25,
        magnet=[6,2], gap=0.1, sheath=0.5, washer=16, guide=2,
        top=undef, face=undef) {
    base_xy = is_num(base) ? [base, base] : base;
    slope_xy = is_num(slope) ? [slope, slope] : slope;
    face_xy = is_undef(face) ? base_xy - 2 * slope_xy : face;

    dbase = max(base_xy);
    dface = max(face_xy);
    dmax = max(dbase, dface);

    difference() {
        union() {
            // main shell of the base
            difference() {
                minibase_hull(base);
                translate([0, 0, is_undef(top) ? wall : top])
                    minibase_hull(base - wall);
            }
            // handle guides
            intersection() {
                minibase_hull(base);
                difference() {
                    union() {
                        cube([dmax, guide, 2*height], center=true);
                        cube([guide, dmax, 2*height], center=true);
                    }
                    cube([washer, washer, 3*height], center=true);
                }
            }
            // magnet sheath
            cylinder(d=magnet[0] + 2*gap + 2*sheath, h=height);
        }
        // magnet well
        translate([0, 0, height - magnet[1] - gap])
            cylinder(d=magnet[0] + 2*gap, height);
    }
}

// vim: ai si sw=4 et
