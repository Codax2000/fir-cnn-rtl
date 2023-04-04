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

## Helpful Links
- About [SVA Assertions](https://www.systemverilog.io/verification/sva-basics/#:~:text=SystemVerilog%20Assertions%20%28SVA%29%20is%20essentially%20a%20language%20construct,in%20a%20SystemVerilog%20format%20which%20tools%20can%20understand.)
- YouTube tutorial on [fully-connected neural nets](https://www.youtube.com/watch?v=rw_JITpbh3k&list=PLJePd8QU_LYKZwJnByZ8FHDg5l1rXtcIq)
- [Xilinx documentation on testbenches](https://www.xilinx.com/content/dam/xilinx/support/documents/university/Vivado-Teaching/HDL-Design/2015x/Verilog/docs-pdf/lab4.pdf)
- 

## Using Version Control
When using git, please use the following convention to document code changes. When you are working on something,
1. Please raise an [issue](https://github.com/Codax2000/fir-cnn-rtl/issues) to document the high-level version of what you are working on. Pictures can be added here
2. On the right side, assign yourself under "assignees" and create a new branch under "development". Name it whatever you like, but descriptive branch names help
3. On the GitHub desktop app, switch to the branch you just made
4. When you are finished with your changes, create a [pull request](https://github.com/Codax2000/fir-cnn-rtl/pulls) to merge your branch back with main