##########################################################
################### GENERATE COLLATERAL ##################
##########################################################
# Case sensitive (avoid issues with spice)
define_name_rules STANDARD -case
change_names -rules STANDARD

# Verilog
write_verilog ./$results/$design_name.apr.v \
    -pg \
    -unconnected_ports \
    -no_core_filler_cells \
    -diode_ports \
    -supply_statement "none"
# Verilog with no power grid or physical cells (aside from tie cells)
write_verilog ./$results/$design_name.apr_no_phys_pwr.v \
    -no_pg \
    -unconnected_ports \
    -no_core_filler_cells \
    -force_no_output_references "$TAP_CELLS $FILL_CELLS"
    -diode_ports \
    -supply_statement "none"

# SDF
write_sdf -context verilog -version 1.2 ./$results/$design_name.apr.sdf
# SDC
write_sdc -version 1.7 -nosplit $results/$design_name.apr.sdc
#DEF
write_def -lef may_need_for_rotated_vias.lef \
          -output "./$results/$design_name.def"\
          -all_vias


##########################################################
################### GENERATE REPORTS #####################
##########################################################
# Timing
check_timing > "./$reports/check_timing.rpt"
report_constraints -all_violators -verbose -nosplit > "./$reports/constraints.rpt"
report_timing -path end  -delay max -max_paths 200 -nosplit > "./$reports/paths.max.rpt"
report_timing -path full -delay max -max_paths 50  -nosplit > "./$reports/full_paths.max.rpt"
report_timing -path end  -delay min -max_paths 200 -nosplit > "./$reports/paths.min.rpt"
report_timing -path full -delay min -max_paths 50  -nosplit > "./$reports/full_paths.min.rpt"

# Area
report_area -physical -hier -nosplit > "./$reports/area.rpt"

# Power and backannotation
report_power -verbose -hier -nosplit > "./$reports/power.hier.rpt"
report_power -verbose -nosplit > "./$reports/power.rpt"
report_saif -hier > "./$reports/saif_anno.rpt"
report_saif -missing >> "./$reports/saif_anno.rpt"

# Floorplanning and placement
report_fp_placement > "./$reports/placement.rpt"

# Clocking
report_clock_tree -nosplit > "./$reports/clocktree.rpt"

# QoR
report_qor -nosplit > "./$reports/qor.rpt"
