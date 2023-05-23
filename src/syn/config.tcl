
# Project and design
# ==========================================================================
set TOPLEVEL "zyNet"
set PROJECT_DIR "../.."

set PROCESS "45GP"; # 45GP
set CORNER "LOW"

# Source files 
# ==========================================================================
set BASE "$PROJECT_DIR/src/verilog"

set RTL_SOURCE_FILES [list \
   "$BASE/zyNet.sv" \
   "$BASE/submodules/abs_layer.sv" \
   "$BASE/submodules/bn_layer.sv" \
   "$BASE/submodules/conv_layer.sv" \
   "$BASE/submodules/fc_layer.sv" \
   "$BASE/submodules/fc_neuron.sv" \
   "$BASE/submodules/fc_output_layer.sv" \
   "$BASE/submodules/gap_layer.sv" \
   "$BASE/submodules/relu_layer.sv" \
   "$BASE/submodules/ROM_neuron.sv" \
   "$BASE/submodules/ROM_inferred.sv" \
   "$BASE/submodules/utils/single_fifo.sv" \
   "$BASE/submodules/utils/logical_unit.sv" \
   "$BASE/submodules/utils/safe_alu.sv" \
   "$BASE/submodules/utils/shift_register.sv" \
   "$BASE/submodules/utils/single_fifo_ctrl.sv" \
   "$BASE/submodules/utils/up_counter_enabled.sv" \
   "$PROJECT_DIR/macro_prep/sram_16_64_freepdk45/sram_16_64_freepdk45.v" \
   "$PROJECT_DIR/macro_prep/sram_16_512_freepdk45/sram_16_512_freepdk45.v" \
   "$PROJECT_DIR/macro_prep/sram_21_256_freepdk45/sram_21_256_freepdk45.v" \
   "$PROJECT_DIR/macro_prep/sram_16_256_freepdk45/sram_16_256_freepdk45.v"
]

set RTL_DEFINES "SYNOPSIS"

# Runtime options 
# ==========================================================================

# Multicore acceleration
if {$TOOL_NAME != "PTPX"} {
   set_host_options -max_cores 8 ;   
}

# Silence the unholy number of warnings that are known to be harmless
#suppress_message "DPI-025"
#suppress_message "PSYN-485"

# Check for latches in RTL
set_app_var hdlin_check_no_latch true

# Library setup
# ==========================================================================

# Design libraries 
set DESIGN_MW_LIB_NAME "design_lib"

if {$PROCESS == "45GP"} {
   # Logic libraries 
   set ADK_PATH [getenv "ADK_PATH"]
   set TARGETCELLLIB_PATH "$ADK_PATH"
   set ADDITIONAL_SEARCH_PATHS [list \
      "$TARGETCELLLIB_PATH"
   ]
      #"$synopsys_root/libraries/syn"

   # Technology files
   set MW_TECHFILE_PATH "$ADK_PATH"

   # Reference libraries 
   set MW_REFERENCE_LIBS "$ADK_PATH/stdcells.mwlib"
   set MW_ADDITIONAL_REFERENCE_LIBS "./sram_16_64_freepdk45 ./sram_16_512_freepdk45 ./sram_21_256_freepdk45 ./sram_16_256_freepdk45"
   set SYNOPSYS_SYNTHETIC_LIB "dw_foundation.sldb"

   set SYMBOL_LIB "stdcells-wc.db"
   set ADDITIONAL_TARGET_LIBS [list \
      "sram_16_64_freepdk45_TT_1p0V_25C.db" \
      "sram_16_512_freepdk45_TT_1p0V_25C.db" \
      "sram_21_256_freepdk45_TT_1p0V_25C.db" \
      "sram_16_256_freepdk45_TT_1p0V_25C.db" 
   ]

   # BC - 1.25 V
   # TC - 1.1 V
   # WC - 0.95 V
   if {$CORNER == "LOW"} {
      # Target corners
      set TARGET_LIBS [list \
         "stdcells-wc.db" \
         "stdcells-bc.db"
      ]
      # Worst case library
      set LIB_WC_FILE   "stdcells-wc.db"
      set LIB_WC_NAME   $LIB_WC_FILE:NangateOpenCellLibrary
      # Best case library
      # Operating conditions
      set LIB_WC_OPCON  "slow"
   # TC - 1.1V
   } elseif {$CORNER == "HIGH"} {
      # Target corners
      set TARGET_LIBS [list \
         "stdcells.db" \
         "stdcells-bc.db"
      ]
      # Worst case library
      set LIB_WC_FILE   "stdcells.db"
      set LIB_WC_NAME   $LIB_WC_FILE:NangateOpenCellLibrary
      # Operating conditions
      set LIB_WC_OPCON  "typical"
   }
}

set LIB_BC_FILE   "stdcells-bc.db"
set LIB_BC_NAME   $LIB_BC_FILE:NangateOpenCellLibrary
set LIB_BC_OPCON  "fast"

#set TECH2ITF_MAP_FILE "star.map_9M"
set MW_TECHFILE "rtk-tech.tf"

# nand2 gate name for area size calculation
set NAND2_NAME    "NAND2_X1"

# Clock 
# ==========================================================================
#  - Assumes a single clock

# Name of the port
set CLK_PORT   "clk_i"

# Frequency 
set CLK_PERIOD 40

# Timing uncertainties
set clk_critical_range 0.010
set clk_setup_uncertainty 0.050
set clk_hold_uncertainty 0.010

# Transition
set clk_trans 0.050

# General timing
# ==========================================================================
# - simplified timing constraints

set max_fanout 32
set max_trans 1.000

set blanket_output_delay 0.100
set blanket_input_delay 0.100

set blanket_output_drive "${LIB_WC_NAME}/INV_X1/ZN"
set blanket_input_load "${LIB_WC_NAME}/INV_X16/A"


# DC compile options
# ==========================================================================

# Reduce runtime
set DC_PREFER_RUNTIME 0

# Preserve design hierarchy
set DC_KEEP_HIER 1

# Register retiming
set DC_REG_RETIME 0
set DC_REG_RETIME_XFORM "multiclass"

# Logic flattening
set DC_FLATTEN 0
set DC_FLATTEN_EFFORT "medium"

# Logic structuring
set DC_STRUCTURE 0
set DC_STRUCTURE_TIMING "true"
set DC_STRUCTURE_LOGIC  "true"

set DC_GLOBAL_CLK_GATING 1

# Do an additional incremental compile for better results
set DC_COMPILE_ADDITIONAL 1

# Result generation and reporting
# ==========================================================================
set results "results"
set reports "reports"



