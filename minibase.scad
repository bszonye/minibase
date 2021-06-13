default_height = 3.25;
default_slope = 1;
default_wall = 1.25;
default_tray = 1;
default_magnet = [6, 2];
default_sheath = 0.5;
default_washer = 16;
default_guide = 2;
default_tolerance = 0.1;

// rim      size of base rim: diameter or [width, length]
// height   height of base
// slope    horizontal component of wall slope: number or xy-vector
module minibase_hull(rim, height=default_height, slope=default_slope,
        top=undef) {
    rim_xy = is_num(rim) ? [rim, rim] : rim;
    slope_xy = is_num(slope) ? [slope, slope] : slope;
    top_xy = is_undef(top) ? rim_xy - 2 * slope_xy : top;

    drim = max(rim_xy);
    dtop = max(top_xy);
    hull() {
        scale(rim_xy / drim) cylinder(d2=drim, d1=0, h=height);
        scale(top_xy / dtop) cylinder(d1=dtop, d2=0, h=height);
    }
}

// rim      rim dimensions: diameter or [width, length]
// height   height of base
// slope    horizontal component of wall slope: number or xy-vector
// wall     thickness of base walls
// magnet   magnet well dimensions: [diameter, height, optional tolerance]
// sheath   thickness of magnet sheath
// washer   diameter of washer gap
// guide    thickness of guide rails
// roof     thickness of base top (default=wall)
// top      top dimensions: diameter or [width, length] (default from slope)
module minibase(rim, height=default_height, slope=default_slope,
        wall=default_wall, magnet=default_magnet, sheath=default_sheath,
        washer=default_washer, guide=default_guide, roof=undef, top=undef) {
    // convert diameters & slope runs to xy-vectors
    rim_xy = is_num(rim) ? [rim, rim] : rim;
    slope_xy = is_num(slope) ? [slope, slope] : slope;
    top_xy = is_undef(top) ? rim_xy - 2 * slope_xy : top;
    wall_xy = [wall, wall];

    // base shell dimensions: rim, top, and maximum
    drim = max(rim_xy);
    dtop = max(top_xy);
    dmax = max(drim, dtop);

    // magnet dimensions: add tolerance to radius and height
    tolerance = len(magnet) < 3 ? default_tolerance : magnet[2];
    rmag = magnet[0] / 2 + tolerance;
    hmag = magnet[1] + tolerance;

    difference() {
        union() {
            // main shell of the base
            difference() {
                minibase_hull(rim_xy, height, top=top_xy);
                translate([0, 0, is_undef(roof) ? wall : roof])
                    minibase_hull(rim_xy-2*wall_xy, height, top=top_xy-2*wall_xy);
            }
            // handle guides
            intersection() {
                minibase_hull(rim);
                difference() {
                    // guide rails
                    union() {
                        cube([dmax, guide, 2*height], center=true);
                        cube([guide, dmax, 2*height], center=true);
                    }
                    // space for washer
                    cube([washer, washer, 3*height], center=true);
                }
            }
            // magnet sheath
            cylinder(r=rmag+sheath, h=height);
        }
        // magnet well
        translate([0, 0, height-hmag]) cylinder(r=rmag, height);
    }
}

module minibase_25mm(magnet=default_magnet, sheath=default_sheath,
        washer=default_washer, guide=default_guide) {
    minibase(25, height=default_height, slope=default_slope, wall=default_wall,
        magnet=magnet, sheath=sheath, washer=washer, guide=guide);
}

module minitray(rim, ranks=[3,2], space=25, wall=default_tray) {
    gap = default_tolerance;
    mx = rim + 2*gap;  // minimum spacing, also used for hypotenuse
    dx = max(rim + space, mx);
    theta = acos(dx/2 / mx);
    dy = mx * sin(theta);
    %cube([dx, space, wall]);
    for (i = [0:len(ranks)-1]) {
        rank = ranks[i];
        y = rim/2 + i * dy;
        for (j = [0:rank-1]) {
            shift = (i % 2) / 2;
            x = (j+shift) * dx;
            translate([x, y, wall]) cylinder(2*wall, r=rim/2+gap);
        }
    }
}

module minitray_32mm() {
    minitray(32);
}

// vim: ai si sw=4 et
