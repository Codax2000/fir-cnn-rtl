# fir-cnn-rtl
SystemVerilog for implementing MATLAB neural net onto Xilinx RFSoC.

#### Alex Knowlton, Ahmed Arefaat, Elpida Karepepera, Eugene Liu

## Setting things up in Vivado
To set this project up in Vivado:
1. Open Vivado to the front page
2. In the Tcl console, use the `cd` command to change to the folder where this repo is stored
3. In Vivado, under "Tools", select "Run Tcl Script"
4. Run the "zyNet.tcl" script
5. To confirm that the script ran properly, click "Simulation", then "Run behavioral simulation", and the testbench for the convolutional layer should pop up.
