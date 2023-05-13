# ROUTE
# ==========================================================================

# Connect PG
derive_pg_connection -reconnect -all
verify_pg_nets

# Build buffer trees for high fanout nets.
remove_ideal_network -all
# Attempt to fix hold violations during routing
set_fix_hold [all_clocks]

# Route
set route_opt_args "-effort medium"
echo "route_opt $route_opt_args"
eval "route_opt $route_opt_args"

# Remove the blockage you created before clockopt
remove_routing_blockage [get_routing_blockage -type metal]
remove_routing_blockage [get_routing_blockage -type via]

# Insert filler
insert_stdcell_filler \
   -cell_with_metal $FILL_CELLS \
   -connect_to_power VDD \
   -connect_to_ground VSS \
   -respect_keepout

# Connect PG
derive_pg_connection -power_net VDD -power_pin VDD -ground_net VSS -ground_pin VSS
verify_pg_nets

# Check LVS/DRC
# ==========================================================================
verify_zrt_route
verify_lvs -ignore_min_area
