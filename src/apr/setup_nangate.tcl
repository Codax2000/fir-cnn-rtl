set results "results"
set reports "reports"

file mkdir ./$results
file mkdir ./$reports

# Project and design
# ==========================================================================
set CORNER "LOW"

# ICC runtime 
# ==========================================================================
# Silence the unholy number of warnings that are known to be harmless
#suppress_message "DPI-025"
#suppress_message "PSYN-485"

# Library setup
# ==========================================================================

set DESIGN_MW_LIB_NAME "design_lib"
# Logic libraries
set ADK_PATH [getenv "ADK_PATH"]
set TARGETCELLLIB_PATH "$ADK_PATH"
set ADDITIONAL_SEARCH_PATHS [list \
				 "$TARGETCELLLIB_PATH" \

				]
set TARGET_LIBS [list \
		     "stdcells.db" \
			 "stdcells-bc.db" \
			 "stdcells-wc.db"
		    ]
#Used by sdc 
set ADDITIONAL_TARGET_LIBS "./sram_2_16_freepdk45_TT_1p0V_25C.db"
set ADDITIONAL_SYMBOL_LIBS {}
set SYMBOL_LIB "stdcells.db"
set SYNOPSYS_SYNTHETIC_LIB "dw_foundation.sldb"

# Reference libraries
set MW_REFERENCE_LIBS "$ADK_PATH/stdcells.mwlib"
set MW_ADDITIONAL_REFERENCE_LIBS "./sram_2_16_freepdk45"

# # Worst case library
set LIB_WC_FILE   "stdcells-wc.db"
set LIB_WC_NAME   $LIB_WC_FILE:NangateOpenCellLibrary

# # Best case library
set LIB_BC_FILE   "stdcells-bc.db"
set LIB_BC_NAME   $LIB_BC_FILE:NangateOpenCellLibrary

# # Operating conditions
set LIB_WC_OPCON  "slow"
set LIB_BC_OPCON  "fast"

# Technology files
set MW_TECHFILE_PATH "$ADK_PATH"
set MW_TECHFILE "rtk-tech.tf"

# POWER NETWORK CONFIG
# ==========================================================================
set MESH_FILE "mesh.tpl"
set MESH_NAME "core_mesh"
#set CUSTOM_POWER_PLAN_SCRIPT "macro_power.tcl"

# FUNCTIONAL CONFIG
# ==========================================================================

set_route_zrt_common_options -global_max_layer_mode hard
if {$TOOL_NAME == "ICC"} {
    # Zroute and the common router do not respect macro blockage layers by default
    set_route_zrt_common_options \
	-read_user_metal_blockage_layer "true" \
	-wide_macro_pin_as_fat_wire "true"
}

set FILL_CELLS {FILLCELL_X32 FILLCELL_X16 FILLCELL_X8 FILLCELL_X4 FILLCELL_X2 FILLCELL_X1}
set TAP_CELLS {WELLTAP_X1}
set TIE_CELLS {LOGIC0_X1 LOGIC1_X1}
set ANTENNA_CELLS {ANTENNA_X1}

# RESULT GENERATION AND REPORTING
# ==========================================================================
set reports "reports" ; # Directory for reports
set results "results" ; # For generated design files
source ${SCRIPTS_DIR}/common_procs.tcl

