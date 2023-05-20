
# ==========================================================================
# FIRST SETUP PREFERRED ROUTING DIRECTION
# ==========================================================================

set MAX_ROUTING_LAYER "metal6"
set MIN_ROUTING_LAYER "metal1"
set HORIZONTAL_ROUTING_LAYERS "metal2 metal4 metal6 metal8"
set VERTICAL_ROUTING_LAYERS "metal3 metal5 metal7"
set_preferred_routing_direction \
    -layers $HORIZONTAL_ROUTING_LAYERS \
    -direction horizontal

set_preferred_routing_direction \
    -layers $VERTICAL_ROUTING_LAYERS \
    -direction vertical

if { $MAX_ROUTING_LAYER != ""} {set_ignored_layers -max_routing_layer $MAX_ROUTING_LAYER}
if { $MIN_ROUTING_LAYER != ""} {set_ignored_layers -min_routing_layer $MIN_ROUTING_LAYER}

# ==========================================================================
# CTS & CLOCK ROUTING
# ==========================================================================

# Make sure placement is good before CTS
check_legality -verbose

# Set options for compile_clock_tree (all are pretty much default, except the routing rule)
set_clock_tree_options \
   -layer_list_for_sinks {metal1 metal2 metal3 metal4 metal5} \
   -layer_list {metal1 metal2 metal3 metal4 metal5} \
   -use_leaf_routing_rule_for_sinks 0 \
   -max_transition 0.080 \
   -leaf_max_transition 0.080 \
   -use_leaf_max_transition_on_exceptions TRUE \
   -use_leaf_max_transition_on_macros TRUE \
   -max_capacitance 0.08 \
   -max_fanout 12 \
   -target_early_delay 0.000 \
   -target_skew 0.000

#Block off metal layers from being routed
create_metal_blockage 8 10

#Run the clock!
set_fix_hold [all_clocks]
clock_opt

# Fix hold violations
#psynopt -only_hold_time
verify_zrt_route

# Save current design (checkpoint)
save_mw_cel -as ${design_name}_postclk
