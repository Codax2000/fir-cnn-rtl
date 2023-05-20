set design_name "zyNet"  ;  # Name of the design
set design_dir  "synth_files" ;

# CONFIGURATION
# ==========================================================================
set TOOL_NAME "ICC"
# directory where tcl src is located 
set SCRIPTS_DIR "../../src/apr"


# Configure design, libraries
# ==========================================================================
source ${SCRIPTS_DIR}/setup_nangate.tcl -echo
source ${SCRIPTS_DIR}/library.tcl -echo

# READ DESIGN
# ==========================================================================
# Read in the verilog, uniquify and save the CEL view.
import_designs $design_dir/$design_name.syn.v -format verilog -top $design_name
link

# TIMING CONSTRAINTS
# ==========================================================================
read_sdc ./$design_dir/$design_name.syn.sdc
check_timing

# FLOORPLAN CREATION
# =========================================================================
# Create core shape and pin placement
source ${SCRIPTS_DIR}/floorplan.tcl -echo

start_gui