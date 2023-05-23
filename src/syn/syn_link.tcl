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
#source -echo -verbose ../../src/syn/verilog.tcl
