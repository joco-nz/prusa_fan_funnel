/*
------------------------------------------------------------
       Fan Funnel
------------------------------------------------------------
*/
include <Libs.scad>
//libHelp();
ew=0.4;		// nominal extrusion width <<-- slicer program could set as larger
// Given we want solid funnels set the minimum perimiters in slicer to this value.
num_perimeters=10;

$fn=30;	// 2x the main circle diameter.

fan=[40,40,3];
fan_hole=37;
available_frame_offset=12;
extra_raise_of_base=1;

nozzle_tip_to_fan=50;
nozzle_tip_to_coldend=43;
nozzle_tip_angle=60;

extrude_height=50;
extrude_height_cut=58;

funnel_wall_thickness=3;
upper_funnel_wall_thickness=4;
funnel_wall_thickness_cut=8;

nozzle_end_scales=[0.14,0.4];		// X/Y
nozzle_end_scales_cut=[0.001,0.2];		// X/Y

funnel_seperator=2;

cooling_nozzle_dip=11;
lower_nozzle_offset=cooling_nozzle_dip+(fan[0]/2);

// Mounting holes.
mount_hole_size=3;
mount_hole_offset_from_edge=2.8+(mount_hole_size/2);
M3_NUT=5.45+ew;



module polyhole(h, d) {
    n = max(round(2 * d),3);
    rotate([0,0,180])
        cylinder(h = h, r = (d / 2) / cos (180 / n), $fn = n);
}


// Base frame
module base_frame() {
	difference()
	{
		translate([0,0,(fan[2]/2)+extra_raise_of_base]) roundRect(size=fan, round=1.5, center=true);
		translate([0,0,-fan[2]/2]) cylinder(d=fan_hole, h=fan[2]*2);
		// mount holes
		#translate([-fan[0]/2+mount_hole_offset_from_edge,fan[1]/2-mount_hole_offset_from_edge,-5])
			polyhole(h=fan[2]*5,d=mount_hole_size);
		#translate([-fan[0]/2+mount_hole_offset_from_edge,-fan[1]/2+mount_hole_offset_from_edge,-5])
			polyhole(h=fan[2]*5,d=mount_hole_size);
	}
}

// Upp funnel and frame cutouts
module upper_funnel_frame_cutout() {
	rotate([0,atan((0.5*((fan[0]-available_frame_offset)/2))/50),0])
		linear_extrude(height=60, center=false, convexity=10, scale=[0.4,0.4])
			translate([(fan[0]-available_frame_offset)/2,0])
				circle(d=fan[0]-upper_funnel_wall_thickness);
	// Main left hand chopper
	translate([fan[0]-available_frame_offset,0,0])
		cube([fan[0],fan[1]*2,fan[2]*50],center=true);
	// Choppers to clean up base of mount
	translate([0,0,-fan[2]+extra_raise_of_base])
		cube([fan[0]*2,fan[1]*2,fan[2]*2],center=true);
	translate([-fan[1],fan[1]/2,0])
		cube([fan[0]*2,5,10]);			// side chopper
	translate([-5-fan[1]/2,-fan[1],0])
		cube([5,fan[0]*2,10]);			// side chopper
	translate([-fan[1],-5-fan[1]/2,0])
		cube([fan[0]*2,5,10]);			// side chopper
	// Height limit chopper at: nozzle_tip_to_fan
	translate([0,-fan[1],nozzle_tip_to_coldend])
		#cube([fan[0],fan[1]*2,extrude_height],center=false);
	// Cut for the bearing mounts on upper duct
	// 3mm in the X and 14mm up from the fan base
	translate([(fan[0]/2-available_frame_offset-3),-fan[1]/2,1+14])
		#cube([3, fan[1], 50]);
	// make an M3 nut impression into the lower funnel
		#translate([-fan[0]/2+mount_hole_offset_from_edge,fan[1]/2-mount_hole_offset_from_edge,fan[2]+extra_raise_of_base])
		#hex(width=M3_NUT, height=3);
		#translate([-fan[0]/2+mount_hole_offset_from_edge,-fan[1]/2+mount_hole_offset_from_edge,fan[2]+extra_raise_of_base])
		#hex(width=M3_NUT, height=3);
	
}

module limit_markers() {
	// top
	translate([-fan[0],-fan[1],nozzle_tip_to_fan])
		%cube([fan[0]*2,fan[1]*2,2],center=false);
	translate([-(fan[0]/2)-13,-fan[1],0])
		%cube([2,fan[0]*2,fan[1]*2],center=false);
	
}

// Upper funnel
module upper_funnel() {
	rotate([0,atan((0.5*((fan[0]-available_frame_offset)/2))/50),0])
		linear_extrude(height=60, center=false, convexity=10, scale=[0.5,0.5])
	difference()
	{
		translate([(fan[0]-available_frame_offset)/2,0])
		difference()
		{
			circle(d=fan[0]);
			//circle(d=fan[0]-funnel_wall_thickness);
		}
		translate([fan[0]-available_frame_offset,0]) square([fan[0],fan[1]], center=true);
	}
}

// Lower funnel
module funnel_ring() {
	linear_extrude(height=1, center=false, convexity=2)
		difference()
		{
			circle(d=fan[0]+(funnel_wall_thickness_cut/2));
			// remove the inside of the funnel
			circle(d=fan[0]-funnel_wall_thickness);
		}
}

module lower_funnel() {
	// base shape
	for (z = [0:0.2:nozzle_tip_to_fan-7])
	{
		assign(x = 33*tan(z)*(z/nozzle_tip_to_fan), angle = nozzle_tip_angle*(z/nozzle_tip_to_fan), resize = (nozzle_tip_to_fan-(z/1.3))/nozzle_tip_to_fan)
		{
			translate([-x,0,z]) rotate([0,-angle,0]) scale([resize,resize,1]) funnel_ring();
		}
	}
}

difference()
{
	union()
	{
		base_frame();
		//translate([0,0,fan[2]])
		lower_funnel();
		upper_funnel();
	}
	upper_funnel_frame_cutout();
	limit_markers();
}

