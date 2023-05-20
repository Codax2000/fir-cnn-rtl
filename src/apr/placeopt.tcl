# PLACEMENT OPTIMIZATION
# ================================

add_tap_cell_array -master_cell_name WELLTAP_X1 -distance 80 \
   -ignore_soft_blockage false -connect_power_name VDD -connect_ground_name VSS \
   -respect_keepout -pattern stagger_every_other_row -tap_cell_identifier WELLTAP

# Optimize
set place_opt_args "-effort low -congestion"

echo "place_opt $place_opt_args"
eval "place_opt $place_opt_args"

connect_tie_cells -objects [get_cells *] -obj_type cell_inst -tie_high_lib_cell LOGIC1_X1 -tie_low_lib_cell LOGIC0_X1

# insert_stdcell_filler \
#    -cell_with_metal $FILL_CELLS \
#    -respect_keepout

# Connect all power and ground pins
derive_pg_connection -all -reconnect -create_ports all
verify_pg_nets
