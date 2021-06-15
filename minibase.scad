default_height = 3.25;
default_slope = 1;
default_wall = 1.25;
default_magnet = [6, 2];
default_sheath = 0.5;
default_washer = 16;
default_guide = 2;
default_tolerance = 0.1;
inch = 25.4;
bit = 0.01;

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
// flat     thickness of base top (default=wall)
// top      top dimensions: diameter or [width, length] (default from slope)
module minibase(rim, height=default_height, slope=default_slope,
        wall=default_wall, magnet=default_magnet, sheath=default_sheath,
        washer=default_washer, guide=default_guide, flat=undef, top=undef) {
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
                translate([0, 0, is_undef(flat) ? wall : flat])
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

module minitray(rim, ranks=[3,2], space=23.8, height=3.2, wall=1.2, flat=1,
        margin=0.25, gutter=0.15, rh=0, rx1=1, rx2=1, rx3=1) {
    zigzag = space > wall;
    wmin = rim + gutter;  // gap between centered bases
    wmax = max(rim + space, wmin);
    adeep = asin(space/wmin);  // as deep as possible
    awide = acos(wmax/wmin/2);  // as wide as possible
    angle = max(30, awide);
    // dy = wmin * sin(angle);
    // dx = wmin * cos(angle) * 2;
    dx = wmax;
    dy = dx / cos(angle) * sin(angle) / 2;
    shell = wall ? wall + margin : 0;  // gap between bases and walls
    echo(angle, dx-rim, dy+shell);
    centers = [
        for (i = [0:len(ranks)-1], j = [0:ranks[i]-1])
            [(j + (i%2)/2)*dx, i*dy]
    ];
    module soften(softness) {
        offset(r=-softness) offset(r=softness) children();
    }
    module outline(softness) {
        soften(softness)
            for (center = centers) translate(center) circle(d=rim+2*shell);
    }

    translate([rim/2+shell, rim/2+shell]) {
        %union() {
            if (space) translate([dx/2, dy, -bit])
                cylinder(height+2*bit, r=rim/2+inch);
            for (center = centers) translate(center)
                translate([0, 0, flat+bit]) cylinder(height, d=rim);
        }
        *linear_extrude(height+bit) outline(0);
        indent = zigzag ?
            dy/sin(angle)/sin(angle)/2 - rim/2 - shell:
            rim/2 + shell;
        echo(indent);
        *translate([3/2*dx, dy-rim/2-shell-indent]) circle(r=indent);
        linear_extrude(flat) outline(max(indent, 3));
        if (wall) {
            linear_extrude(height) difference() {
                outline(max(indent, 3));
                offset(r=-wall) outline(zigzag ? 1 : 0.25);
            }
        } else {
            linear_extrude(height) soften(-1) difference() {
                outline(max(indent, 3));
                offset(r=margin) outline(0);
            }
        }
        // inner retainer
        if (rh) {
            rr1 = rim/2 - rx1;  // bottom radius
            rr2 = rr1 - rx2;  // top radius
            rr3 = rr2 - rx3;  // inside radius
            rr0 = rr1 + flat/rh*rx2;  // below surface radius
            echo(rh, rr0, rr1, rr2, rr3);
            for (center = centers) translate(center) difference() {
                cylinder(rh+flat, rr0, rr2);
                translate([0, 0, -1]) cylinder(h=rh+flat+2, r=rr3);
            }
        }
    }
}

module minitray_25mm() {
    minitray(25, space=0, wall=0, margin=0.1, gutter=0);
    translate([0, 50]) minitray(25, space=0, margin=0.1, gutter=0);
}

module minitray_32mm() {
    minitray(32, wall=0, rh=2);
    translate([0, 50]) minitray(32);
}

module minitray_40mm() {
    minitray(39.5, wall=0);
    translate([0, 60]) minitray(39.5);
}

// vim: ai si sw=4 et
