# FAST Lab ZyNet
SystemVerilog for implementing MATLAB neural net onto Xilinx RFSoC.

#### Xichen Li Ahmed Arefaat, Elpida Karepepera, Eugene Liu, Alex Knowlton

## Setting Things Up in Vivado
1. Clone the repo into a directory.
2. Make sure that your Vivado installation has the ZCU216 evaluation board installed, or this will likely not work.
3. In Vivado, select 'open project' and open the `zyNet/` directory, where you should be able to open the `.xpr` file to open the entire project.
4. Re-synthesize the out-of-context IPs so that testbenches will run.
5. To ensure that things are set up, run the `conv_to_fc_tb` simulation and make sure all test cases pass (they should show in tcl console).
6. If you want, run the other testbenches to ensure things are working.
7. Before running the `sim_1` testbench (the toplevel), make sure you run `python ./Scripts/python/actual_outputs_to_mif.py` in the toplevel to make sure your memory file for 'expected' outputs in the toplevel is up to date.
8. If you want to run other testbenches, check the `zyNet/zyNet.srcs/unused_testbenches` folder for other testbenches you can run.

## Running Synopsis Synthesis and APR
1. Switch to the `70-need-synopsis-flow` branch. Note that the hierarchy is different. This is because the structure was updated for Synopsis, and it is no longer cleanly compatible with Vivado. **DO NOT** merge this branch with main.
2. You can now run commands for synthesis and APR from the toplevel directory with `make`. The RTL is very similar (some compatibility modifications).
Here is a table of `make` commands:
| Command | Result |
| !--- | !--- |
|`make syn` | run synthesis in DC compiler |
|`make apr` | run apr in IC compiler |
|`make syn-link` | run synthesis up to linking |
|`make apr-to-floorplan` | run APR up to floorplanning script |
|`make clean-syn` | clean out the synthesis directory |
|`make clean-apr` | clean out the apr directory |
|`make clean` | _should_ clean out both synthesis and apr directories |

Be aware that synthesis has taken about 4 hours in the past. APR takes close to a week.

## Python Scripts
There are several python scripts used for text processing and data analysis. Most of them are legacies and were run once. They should be run using an environment that has `pandas` installed, and run in the top-level directory of this repo. There are only two that still apply:
1. `actual_outputs_to_mif.py` is used for converting the `csv` file that the matlab testbench produces to an 'expected' `mif` file for the toplevel testbench.
2. `error_histogram.py` is used to plot the errors produced by the matlab testbench on a histogram.


## Helpful Links
- YouTube tutorial on [fully-connected neural nets](https://www.youtube.com/watch?v=rw_JITpbh3k&list=PLJePd8QU_LYKZwJnByZ8FHDg5l1rXtcIq)
- About [SVA Assertions](https://www.systemverilog.io/verification/sva-basics/#:~:text=SystemVerilog%20Assertions%20%28SVA%29%20is%20essentially%20a%20language%20construct,in%20a%20SystemVerilog%20format%20which%20tools%20can%20understand.)
- Xilinx [documentation on testbenches](https://www.xilinx.com/content/dam/xilinx/support/documents/university/Vivado-Teaching/HDL-Design/2015x/Verilog/docs-pdf/lab4.pdf)
- Xilinx [Design Constraints](https://www.xilinx.com/content/dam/xilinx/support/documents/sw_manuals/xilinx2022_2/ug945-vivado-using-constraints-tutorial.pdf)
- Xilinx [Language Support](https://www.xilinx.com/content/dam/xilinx/support/documents/sw_manuals/xilinx2022_2/ug901-vivado-synthesis.pdf)