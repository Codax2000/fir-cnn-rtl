# Clean slate in case we are rerunning
remove_power_plan_regions -all

# Create a power plan region for the core
set core_ppr_name "ppr_core"
create_power_plan_regions $core_ppr_name \
   -core

# Generate the power ring
# =============================
#Plan your power. The outer ring extends out to hit the pin and inner stripe shrinks to cover the core.
# Set the strategies for the rings
set hlay    metal6      ; # horizontal ring layer
set vlay    metal7      ; # vertical ring layer
set rw      3 ; # ring width
set vss_os  1.2 ; # offset relative to core edge
set vdd_os [expr $vss_os+ $rw + 2]; #offset of the vdd relative to the core edge. 

set vss_ring_strategy_name "vss_ring"
set vdd_ring_strategy_name "vdd_ring"

set_power_ring_strategy $vss_ring_strategy_name \
   -power_plan_regions $core_ppr_name \
   -nets {VSS} \
   -template ${SCRIPTS_DIR}/rings.tpl:core_ring_vss($hlay,$vlay,$rw,$vss_os)
set_power_ring_strategy $vdd_ring_strategy_name \
   -power_plan_regions $core_ppr_name \
   -nets {VDD} \
   -template ${SCRIPTS_DIR}/rings.tpl:core_ring_vdd($hlay,$vlay,$rw,$vdd_os)

# Constrain the core meshes
# =============================

#### FIRST BLOCK POWER METALS FROM ROUTING OVER YOUR RAM ######
# Grab the area for each RAM in your design. Create power plan region around them.
set RAM_cells [get_cells -regexp -hierarchical -filter "ref_name =~ sram_2_16_freepdk45"]

# Create some lists defining macros with M4, and their regions. 
set m4_macros [concat $RAM_cells]
set m4_macro_regions {}

# Loop: Every RAM cell, create power plan region and expand.
set i 1
foreach_in_collection cell $m4_macros {
    set name1 macro_region_m4_$i
    create_power_plan_regions $name1 \
      -group_of_macros $cell \
      -expand [list $CELL_HEIGHT $CELL_HEIGHT] 
    lappend m4_macro_regions macro_region_m4_$i
    incr i 1
}

# Set power mesh blockage for RAM cells. 
lappend core_mesh_blockages [list \
          [list "power_plan_regions:" $m4_macro_regions] \
          [list "layers:" {metal1 metal2 metal3 metal4}] \
         ]


# Specify the mesh (only reaches to up to the core boundary)
set num_m1m2 [expr int($CORE_HEIGHT_IN_CELL_HEIGHTS/2)]
set mesh_strategy_name "mesh"
set_power_plan_strategy $mesh_strategy_name \
    -power_plan_regions $core_ppr_name \
    -nets {VDD VSS} \
    -extension { {nets:"VDD VSS"} {stop: outermost_ring} } \
    -template ${SCRIPTS_DIR}/${MESH_FILE}:${MESH_NAME}(0,$num_m1m2) \
    -blockage $core_mesh_blockages

# Create the core rings
compile_power_plan -ring -strategy $vss_ring_strategy_name
compile_power_plan -ring -strategy $vdd_ring_strategy_name

# Compile the power mesh
compile_power_plan -strategy $mesh_strategy_name


create_preroute_vias \
   -nets {VDD VSS} \
   -from_object_strap \
   -to_object_strap \
   -from_layer metal2 \
   -to_layer   metal1 \
   -advanced_via_rule


