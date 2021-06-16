default_wall = 1.25;  // TODO: remove
default_magnet = [2, 6];
default_guide = 2;
default_tolerance = 0.1;
inch = 25.4;
bit = 0.01;

// h    height of base
// rim  rim dimensions: diameter or [width, length]
// top  top dimensions: diameter or [width, length]
module minibase_hull(h, rim, top, center=false) {
    rim_xy = is_num(rim) ? [rim, rim] : rim;
    top_xy = is_num(top) ? [top, top] : top;

    drim = max(rim_xy);
    dtop = max(top_xy);
    hull() {
        scale(rim_xy / drim) cylinder(h, d1=drim, d2=0, center=center);
        scale(top_xy / dtop) cylinder(h, d1=0, d2=dtop, center=center);
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

module minibase_25mm(magnet=default_magnet, guide=default_guide, cross=false,
        flip=true) {
    minibase(magnet=magnet, guide=guide, cross=cross, flip=flip) {
        minibase_hull(3.4, 25, 23);
        minibase_hull(2.4, 22.5, 21.5);
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
    // minitray(32, [2,1], height=5.2, wall=0);
    // minitray(32, wall=0, rh=2);
    // translate([0, 50]) minitray(32);
    minibase_hull(2.75, 29, 27.5);
}

module minitray_40mm() {
    minitray(39.5, wall=0);
    translate([0, 60]) minitray(39.5);
}

// vim: ai si sw=4 et
