use <minibase.scad>

$fa = 1;
$fs = 0.4;

base = 25;
height = 3.25;
wall = 1.25;
ceiling = 1.25;
tolerance = 0.1;
magnet = [6, 2];
sheath = 1.0;

difference() {
    union() {
        // base
        difference() {
            base_hull(base);
            translate([0, 0, ceiling])
                base_hull(base - wall);
        }
        // handle guides
        intersection() {
            base_hull(base);
            crosshair();
        }
        // magnet sheath
        cylinder(d=magnet[0] + 2*tolerance + sheath, h=height);
    }
    // magnet well
    translate([0, 0, height - magnet[1] - tolerance])
        cylinder(d=magnet[0] + 2*tolerance, height);
}

// vim: ai si sw=4 et
