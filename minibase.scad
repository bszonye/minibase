default_magnet = [2, 6];
default_guide = 2;
default_tolerance = 0.1;
inch = 25.4;
bit = 0.01;

// h    height of base
// rim  rim dimensions: diameter or [width, length]
// top  top dimensions: diameter or [width, length]
module minibase_hull(h, rim, top, cut=0, center=false) {
    rim_xy = is_num(rim) ? [rim, rim] : rim;
    top_xy = is_num(top) ? [top, top] : top;

    drim = max(rim_xy);
    dtop = max(top_xy);
    difference() {
        hull() {
            scale(rim_xy / drim) cylinder(h, d1=drim, d2=0, center=center);
            scale(top_xy / dtop) cylinder(h, d1=0, d2=dtop, center=center);
        }
        if (cut) {
            cut_xy = is_num(cut) ? top_xy - 2*[cut, cut] : top_xy - 2*cut;
            minibase_hull(3*h, cut_xy, cut_xy, center=true);
        }
    }
}

module minibase_guide(h, d, guide=default_guide, cross=false, space=1000) {
    // magnet well and sheath dimensions
    gap = default_tolerance;
    hwell = h + gap;
    rwell = d/2 + gap;
    rsheath = rwell + guide;
    difference() {
        intersection() {
            union() {
                if (cross) {
                    cube([space, guide, space], center=true);
                    cube([guide, space, space], center=true);
                }
                cylinder(space, r=rsheath);
            }
            children();
        }
        cylinder(2*hwell, r=rwell, center=true);
    }
}

module minibase(magnet=default_magnet, guide=default_guide, cross=false,
        flip=true) {
    rotate(flip ? 180 : 0, [0, 1, 0]) {
        difference() {
            children(0);
            hull() {  // extend the interior below the base
                children(1);
                translate([0, 0, -1]) children(1);
            }
        }
        if (magnet)
            minibase_guide(magnet[0], magnet[1], guide, cross) children(0);
    }
}

module minitray(rim, ranks=[3,2], space=23.8, height=3.2, wall=1.2, flat=1.2,
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
        %if (space) translate([dx/2, dy, -bit])
            cylinder(height+2*bit, r=rim/2+inch);
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
        if ($children) for (center=centers) translate(center)
            translate([0, 0, flat]) children();
    }
}

// TODO: check measurements
module exterior_25mm(x=0) { minibase_hull(3.4, 25, 23, x); }
module interior_25mm(x=0) { minibase_hull(2.4, 22.5, 21, x); }
module exterior_32mm(x=0) { minibase_hull(4.2, 32, 29, x); }
module interior_32mm(x=0) { minibase_hull(2.8, 29, 27, x); }
module exterior_40mm(x=0) { minibase_hull(4.0, 39.25, 36.25, x); }
module interior_40mm(x=0) { minibase_hull(2.8, 37, 35.5, x); }

module minibase_25mm(magnet=default_magnet, guide=default_guide, cross=false,
        flip=true) {
    minibase(magnet=magnet, guide=guide, cross=cross, flip=flip) {
        exterior_25mm();
        interior_25mm();
    }
}

module minibase_32mm(magnet=default_magnet, guide=default_guide, cross=false,
        flip=true) {
    minibase(magnet=magnet, guide=guide, cross=cross, flip=flip) {
        exterior_32mm();
        interior_32mm();
    }
}

module minitray_25mm() {
    *minitray(25, [1], height=4, space=0, wall=0, margin=0.1, gutter=0) {
        translate([0, 0, -0.2]) interior_25mm(1);
        %translate([0, 0, bit]) exterior_25mm();
    }
    *minitray(25, height=4, space=0, wall=0, margin=0.1, gutter=0) {
        translate([0, 0, -0.2]) interior_25mm(1);
        %translate([0, 0, bit]) exterior_25mm();
    }
    *translate([0, 50]) minitray(25, space=0, margin=0.1, gutter=0) {
        %translate([0, 0, bit]) exterior_25mm();
    }
    minitray(25, space=0, margin=0.1, gutter=0) {
        %translate([0, 0, bit]) exterior_25mm();
    }
}

module minitray_32mm() {
    *minitray(32, [1], height=5, wall=0) {
        translate([0, 0, -0.2]) interior_32mm(1);
        %translate([0, 0, bit]) exterior_32mm();
    }
    *minitray(32, height=5, wall=0) {
        translate([0, 0, -0.2]) interior_32mm(1);
        %translate([0, 0, bit]) exterior_32mm();
    }
    *translate([0, 50]) minitray(32) {
        %translate([0, 0, bit]) exterior_32mm();
    }
    minitray(32) {
        %translate([0, 0, bit]) exterior_32mm();
    }
}

module minitray_40mm() {
    *minitray(39.5, [1], height=4.8, wall=0) {
        translate([0, 0, -0.2]) interior_40mm(1);
        %translate([0, 0, bit]) exterior_40mm();
    }
    *minitray(39.5, height=4.8, wall=0) {
        translate([0, 0, -0.2]) interior_40mm(1);
        %translate([0, 0, bit]) exterior_40mm();
    }
    *translate([0, 60]) minitray(39.5) {
        %translate([0, 0, bit]) exterior_40mm();
    }
    minitray(39.5) {
        %translate([0, 0, bit]) exterior_40mm();
    }
}

// vim: ai si sw=4 et
