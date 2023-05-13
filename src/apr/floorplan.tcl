# ==========================================================================
# GENERAL ROUTING PARAMETERS
# ==========================================================================
# Set Min/Max Routing Layers and routing directions


#Then, once routing layer preferences have been established, place pins.
# set_fp_pin_constraints -hard_constraints {layer location} -block_level -use_physical_constraints on
#  set_pin_physical_constraints [all_inputs] \
#                   -side 1 \
#                   -width 0.1 \
#                   -depth 0.1 \
#                   -layers {metal2}

#  set_pin_physical_constraints [all_outputs] \
#                   -side 3 \
#                   -width 0.1 \
#                   -depth 0.1 \
#                   -layers {metal2}

#set_physical_constraints [all_inputs] \
#                    -side 1 \
#                    -width 0.1 \
#                    -depth 0.1 \
#                    -layers {metal2,metal4}
#
#set_physical_constraints [all_outputs] \
#                    -side 3 \
#                    -width 0.1 \
#                    -depth 0.1 \
#                    -layers {metal2,metal4}

derive_pg_connection -power_net VDD -power_pin VDD -ground_net VSS -ground_pin VSS
derive_pg_connection

if {[file isfile pin_placement.txt]} {
    exec python3 $SCRIPTS_DIR/gen_pin_placement.py -t pin_placement.txt -o pin_placement.tcl
    }

if {[file isfile pin_placement.tcl]} {
    # Fix the pin metal layer change problem
    set_fp_pin_constraints -hard_constraints {layer location} -block_level -use_physical_constraints on
    source pin_placement.tcl -echo
}

#### SET FLOORPLAN VARIABLES ######
set CELL_HEIGHT 1.4
set CORE_WIDTH_IN_CELL_HEIGHTS  50
set CORE_HEIGHT_IN_CELL_HEIGHTS 35
set POWER_RING_CHANNEL_WIDTH [expr 10*$CELL_HEIGHT]

set CORE_WIDTH  [expr $CORE_WIDTH_IN_CELL_HEIGHTS * $CELL_HEIGHT]
set CORE_HEIGHT [expr $CORE_HEIGHT_IN_CELL_HEIGHTS * $CELL_HEIGHT]

create_floorplan -control_type width_and_height \
                 -core_width  $CORE_WIDTH \
                 -core_height $CORE_HEIGHT \
                 -core_aspect_ratio 1.50 \
                 -left_io2core $POWER_RING_CHANNEL_WIDTH \
                 -right_io2core $POWER_RING_CHANNEL_WIDTH \
                 -top_io2core $POWER_RING_CHANNEL_WIDTH \
                 -bottom_io2core $POWER_RING_CHANNEL_WIDTH \
                 -flip_first_row


# Power straps are not created on the very top and bottom edges of the core, so to
# prevent cells (especially filler) from being placed there, later to create LVS
# errors, remove all the rows and then re-add them with offsets
cut_row -all
add_row \
   -within [get_attribute [get_core_area] bbox] \
   -top_offset $CELL_HEIGHT \
   -bottom_offset $CELL_HEIGHT
   #-flip_first_row \

# begin for loop here
set NUM_CONVOLUTIONAL_RAMS 256
set NUM_BN_RAMS 4
set NUM_HIDDEN_LAYER_RAMS 256
set NUM_OUTPUT_RAMS 10

# for loop 1: Convolutional RAMs
for {set i 0} {$i < $NUM_CONVOLUTIONAL_RAMS} {incr i} {

   # TODO: Update with name from synthesized toplevel module
   set RAM_CURRENT "genblk_insert_name_here"

   # Get height and width of RAM
   set RAM_CURRENT_HEIGHT [get_attribute $RAM_CURRENT height]
   set RAM_CURRENT_WIDTH  [get_attribute $RAM_CURRENT width] 

   # Set Origin of RAM
   set RAM_SEPARATION [expr 10*$CELL_HEIGHT]

   set RAM_CURRENT_LLX [expr [expr 14*$CELL_HEIGHT] + [expr $i*$RAM_SEPARATION]]
   set RAM_CURRENT_LLY [expr 14*$CELL_HEIGHT]
   # Derive URX and URY corner for placement blockage. "Width" and "Height" are along wrong axes because we rotated the RAM.
   set RAM_CURRENT_URX [expr $RAM_CURRENT_LLX + $RAM_CURRENT_HEIGHT]
   set RAM_CURRENT_URY [expr $RAM_CURRENT_LLY + $RAM_CURRENT_WIDTH]

   set GUARD_SPACING [expr 2*$CELL_HEIGHT]

   set_attribute $RAM_CURRENT orientation "E"

   set_cell_location \
      -coordinates [list [expr $RAM_CURRENT_LLX ] [expr $RAM_CURRENT_LLY]] \
      -fixed \
      $RAM_CURRENT

   # Create blockage for filler-cell placement. 
   create_placement_blockage \
      -bbox [list [expr $RAM_CURRENT_LLX - $GUARD_SPACING] [expr $RAM_CURRENT_LLY - $GUARD_SPACING] \
                  [expr $RAM_CURRENT_URX + $GUARD_SPACING] [expr $RAM_CURRENT_URY + $GUARD_SPACING]] \
      -type hard

   # Connect RAM power to power grid
   connect_net VDD [get_pins -all $RAM_CURRENT/vdd]
   connect_net VSS [get_pins -all $RAM_CURRENT/gnd]
}

