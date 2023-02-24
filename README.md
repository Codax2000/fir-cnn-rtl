# fir-cnn-rtl
SystemVerilog for implementing MATLAB neural net onto Xilinx RFSoC.

#### Alex Knowlton, Ahmed Arefaat, Elpida Karepepera

## Methodology
layers to implement:
- Fully-Connected Layer
- Convolutional Layer

The trick is to figure out how to quantize, parametrize, and store the neural net so that it can be efficiently implemented on the FPGA.

## Setting things up in Vivado
The idea is to avoid anything except the essentials in this repo, but eventually I would like to have a `.tcl` script that will create a Vivado project for us.

## Current Problems
- We need a block memory module that can be instantiated with a parameter that specifies the `.mif` or `.coe` file for the fully-connected nodes.
- A script or design flow to go from a Matlab module to Verilog will likely be essential.

## Notes
*Please add notes here*
2/01/2023: Created Repository (Alex)
2/18/2023: Switched to sequential design

## Conventions
- arrays are indexed by height, then width