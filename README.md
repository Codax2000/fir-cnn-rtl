# fir-cnn-rtl
SystemVerilog for implementing MATLAB neural net onto Xilinx RFSoC.

#### Alex Knowlton, Ahmed Arefaat, Elpida Karepepera

## Methodology
layers to implement:
- Fully-Connected Layer
- Convolutional Layer

The trick is to figure out how to quantize, parametrize, and store the neural net so that it can be efficiently implemented on the FPGA.

## Setting things up in Vivado
To set this project up in Vivado:
1. Open Vivado to the front page
2. In the Tcl console, use the `cd` command to change to the folder where this repo is stored
3. In Vivado, under "Tools", select "Run Tcl Script"
4. Run the "fir-cnn-rtl.tcl" script
5. To confirm that the script ran properly, click "Simulation", then "Run behavioral simulation", and the testbench for the convolutional layer should pop up.

## Current Problems
- We need a block memory module that can be instantiated with a parameter that specifies the `.mif` or `.coe` file for the fully-connected nodes.
- A script or design flow to go from a Matlab module to Verilog will likely be essential.

## Notes
*Please add notes here*
2/01/2023: Created Repository (Alex)
2/18/2023: Switched to sequential design
