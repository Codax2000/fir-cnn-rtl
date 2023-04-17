# FAST Lab ZyNet
SystemVerilog for implementing MATLAB neural net onto Xilinx RFSoC.

#### Xichen Li Ahmed Arefaat, Elpida Karepepera, Eugene Liu, Alex Knowlton

## Setting things up in Vivado
To set this project up in Vivado:
1. Open Vivado to the front page
2. Make sure that the ZCU104 evaluation board is installed in your devices
   1. To check, go to "Help > Add Design Tools or Devices" and make sure to install the "SoC > Zynq UltraScale+ MPSoCs" folder, in addition to the RFSoCs folder
   2. This is to make sure that this project is compatible across all devices, even though it is not the board that we are eventually going to use.
3. In the Tcl console, use the `cd` command to change to the folder where this repo is stored
4. In Vivado, under "Tools", select "Run Tcl Script"
5. Run the "zyNet.tcl" script
6. To confirm that the script ran properly, click "Simulation", then "Run behavioral simulation", and the testbench for the convolutional layer should pop up.

## Using Version Control
When using git, please use the following convention to document code changes. When you are working on something,
1. Please raise an [issue](https://github.com/Codax2000/fir-cnn-rtl/issues) to document the high-level version of what you are working on. Pictures can be added here
2. On the right side, assign yourself under "assignees" and create a new branch under "development". Name it whatever you like, but descriptive branch names help
3. On the GitHub desktop app, switch to the branch you just made and make your changes
4. In Vivado, select "File > Project > Write Tcl" and replace the "zyNet.tcl" script in the local directory
5. Commit your changes and push to your branch
6. When you are finished with your changes, create a [pull request](https://github.com/Codax2000/fir-cnn-rtl/pulls) to merge your branch back with main

## Vivado Tips and Tricks
1. Keep the same directory structure as this directory
2. Write all verilog in one directory and link to it from the project, don't store verilog files in the Vivado project directory. File structure should look like this:
```
zyNet
   | mem
   | RTL
      | submodules
      | testbenches
   | Waveform Configurations
   | zyNet // this folder ignored by .gitignore file
      | zyNet.cache
      | zyNet.hw
      | zyNet.ip_user_files
      | zyNet.sim
   | zyNet.tcl // run this file in tcl terminal to recreate project
```
3. For each testbench, create a separate simulation set, just for that testbench, so that we can easily switch back to it if we need
4. Use calls to `assert` instead of inspecting waveforms visually, makes for easier re-testing after some time or after a change

## Helpful Links
- YouTube tutorial on [fully-connected neural nets](https://www.youtube.com/watch?v=rw_JITpbh3k&list=PLJePd8QU_LYKZwJnByZ8FHDg5l1rXtcIq)
- About [SVA Assertions](https://www.systemverilog.io/verification/sva-basics/#:~:text=SystemVerilog%20Assertions%20%28SVA%29%20is%20essentially%20a%20language%20construct,in%20a%20SystemVerilog%20format%20which%20tools%20can%20understand.)
- Xilinx [documentation on testbenches](https://www.xilinx.com/content/dam/xilinx/support/documents/university/Vivado-Teaching/HDL-Design/2015x/Verilog/docs-pdf/lab4.pdf)
- Xilinx [Design Constraints](https://www.xilinx.com/content/dam/xilinx/support/documents/sw_manuals/xilinx2022_2/ug945-vivado-using-constraints-tutorial.pdf)
- Xilinx [Language Support](https://www.xilinx.com/content/dam/xilinx/support/documents/sw_manuals/xilinx2022_2/ug901-vivado-synthesis.pdf)