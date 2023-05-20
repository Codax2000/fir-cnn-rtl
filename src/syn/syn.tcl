
set TOOL_NAME "DC"

# begin timing
set start_time [clock seconds] ; echo [clock format ${start_time} -gmt false]
echo [pwd]

# Configuration                                                               #
#=============================================================================#

# Get configuration settings
source ../../src/syn/config.tcl

file mkdir ./$results
file mkdir ./$reports

# Read technology library                                                     #
#=============================================================================#
source -echo -verbose ../../src/syn/library.tcl

# Read design RTL                                                             #
#=============================================================================#
source -echo -verbose ../../src/syn/verilog.tcl

# Set design constraints                                                      #
#=============================================================================#
source -echo -verbose ../../src/syn/constraints.tcl

# Synthesize                                                                  #
#=============================================================================#

# Prevent assignment statements in the Verilog netlist.
set_fix_multiple_port_nets -all -buffer_constants

# Run topdown synthesis
# (this should be set already)
current_design $TOPLEVEL

# Set the compilation options
if {$DC_FLATTEN} {
   set_flatten true -effort $DC_FLATTEN_EFFORT
}
if {$DC_STRUCTURE} {
   set_structure true -timing $DC_STRUCTURE_TIMING -boolean $DC_STRUCTURE_LOGIC
}
set COMPILE_ARGS [list]
if {$DC_KEEP_HIER} {
    lappend COMPILE_ARGS "-no_autoungroup"
    lappend COMPILE_ARGS "-no_boundary_optimization"
}
if {$DC_REG_RETIME} {
    set_optimize_registers -async_transform $DC_REG_RETIME_XFORM \
	-sync_transform  $DC_REG_RETIME_XFORM
    lappend COMPILE_ARGS "-retime"
}


# Compile, first pass
eval compile_ultra $COMPILE_ARGS


# Second pass, if enabled
if {$DC_COMPILE_ADDITIONAL} {
   compile_ultra -incremental
}

# Reports generation                                                          #
#=============================================================================#
source -echo -verbose ../../src/syn/reports.tcl

# Generate design data                                                        #
#=============================================================================#
source -echo -verbose ../../src/syn/generate.tcl

# Report runtime and quit
#=============================================================================#

# Error/warning summary
print_message_info

# Print runtime
set end_time [clock seconds]; echo [string toupper inform:] End time [clock format ${end_time} -gmt false]
echo "[string toupper inform:] Time elapsed: [format %02d \
                     [expr ($end_time - $start_time)/86400]]d \
                    [clock format [expr ($end_time - $start_time)] \
                    -format %Hh%Mm%Ss -gmt true]"



