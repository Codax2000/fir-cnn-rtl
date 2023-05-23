
set NUM_CONVOLUTIONAL_COLUMNS 12
set NUM_CONVOLUTIONAL_ROWS 18
set NUM_CONVOLUTIONAL_RAMS [expr $NUM_CONVOLUTIONAL_COLUMNS*$NUM_CONVOLUTIONAL_ROWS]

set NUM_BN_COLUMNS 2
set NUM_BN_ROWS 2
set NUM_BN_RAMS [expr $NUM_BN_COLUMNS*$NUM_BN_ROWS]

set NUM_HIDDEN_COLUMNS 8
set NUM_HIDDEN_ROWS 32
set NUM_HIDDEN_RAMS [expr $NUM_HIDDEN_COLUMNS*$NUM_HIDDEN_ROWS]

set NUM_OUTPUT_COLUMNS 5
set NUM_OUTPUT_ROWS 2
set NUM_OUTPUT_RAMS [expr $NUM_OUTPUT_COLUMNS*$NUM_OUTPUT_ROWS]

# get convolutional RAM width for offset measurement
set CONV_RAM "kernel/genblk1_0__weight_mem/internal_rom/genblk1_genblk1_ram"
set RAM_CONV_WIDTH [get_attribute $CONV_RAM width]
set RAM_CONV_HEIGHT [get_attribute $CONV_RAM height]


# for loop 1: Convolutional RAMs
set INDEX 0
for {set i 0} {$i < $NUM_CONVOLUTIONAL_COLUMNS} {incr i} {
    for {set j 0} {$j < $NUM_CONVOLUTIONAL_ROWS} {incr j} {
        if {$INDEX < $NUM_CONVOLUTIONAL_RAMS} {
            echo $INDEX
            set RAM_CURRENT "kernel/genblk1_${INDEX}__weight_mem/internal_rom/genblk1_genblk1_ram"

            # Get height and width of RAM
            set RAM_CURRENT_HEIGHT [get_attribute $RAM_CURRENT height]
            set RAM_CURRENT_WIDTH  [get_attribute $RAM_CURRENT width] 

            # Set Origin of RAM
            set RAM_SEPARATION_X [expr 73*$CELL_HEIGHT]
            set RAM_SEPARATION_Y [expr 68*$CELL_HEIGHT]

            set RAM_CURRENT_LLX [expr [expr $i*$RAM_CURRENT_WIDTH] + [expr [expr $i+1]*$RAM_SEPARATION_X]]
            set RAM_CURRENT_LLY [expr [expr $j*$RAM_CURRENT_HEIGHT] + [expr [expr $j+1]*$RAM_SEPARATION_Y]]
            # Derive URX and URY corner for placement blockage. "Width" and "Height" are along wrong axes because we rotated the RAM.
            set RAM_CURRENT_URX [expr $RAM_CURRENT_LLX + $RAM_CURRENT_HEIGHT]
            set RAM_CURRENT_URY [expr $RAM_CURRENT_LLY + $RAM_CURRENT_WIDTH]

            set GUARD_SPACING [expr 2*$CELL_HEIGHT]

            set_attribute $RAM_CURRENT orientation "E"

            set_cell_location \
                -coordinates [list [expr $RAM_CURRENT_LLX ] [expr $RAM_CURRENT_LLY]] \
                -fixed \
                $RAM_CURRENT

            # Create blockage for filler-cell placement. 
            create_placement_blockage \
                -bbox [list [expr $RAM_CURRENT_LLX - $GUARD_SPACING] [expr $RAM_CURRENT_LLY - $GUARD_SPACING] \
                            [expr $RAM_CURRENT_URX + $GUARD_SPACING] [expr $RAM_CURRENT_URY + $GUARD_SPACING]] \
                -type hard

            # Connect RAM power to power grid
            connect_net VDD [get_pins -all $RAM_CURRENT/vdd]
            connect_net VSS [get_pins -all $RAM_CURRENT/gnd]
            incr INDEX
        }
    }
}


# for loop 2: fully-connected RAMs
set INDEX 0
for {set i 0} {$i < $NUM_HIDDEN_COLUMNS} {incr i} {
    for {set j 0} {$j < $NUM_HIDDEN_ROWS} {incr j} {
        if {$INDEX < $NUM_HIDDEN_RAMS} {
            echo $INDEX
            set RAM_CURRENT "hidden_layer/genblk1_${INDEX}__neuron/weight_and_bias_mem/internal_rom/genblk1_genblk1_ram"

            # Get height and width of RAM
            set RAM_CURRENT_HEIGHT [get_attribute $RAM_CURRENT height]
            set RAM_CURRENT_WIDTH  [get_attribute $RAM_CURRENT width] 

            # Set Origin of RAM
            set RAM_SEPARATION_X [expr 40*$CELL_HEIGHT]
            set RAM_SEPARATION_Y [expr 20*$CELL_HEIGHT]

            set RAM_CURRENT_LLX [expr [expr 2670*$CELL_HEIGHT] - [expr 10*$CELL_HEIGHT] - $RAM_CURRENT_HEIGHT - [expr $i*$RAM_CURRENT_HEIGHT] - [expr $i*$RAM_SEPARATION_X]]
            set RAM_CURRENT_LLY [expr [expr 2670*$CELL_HEIGHT] - [expr 10*$CELL_HEIGHT] - $RAM_CURRENT_WIDTH - [expr $j*$RAM_CURRENT_WIDTH] - [expr $j*$RAM_SEPARATION_Y]]
            # Derive URX and URY corner for placement blockage. "Width" and "Height" are along wrong axes because we rotated the RAM.
            set RAM_CURRENT_URX [expr $RAM_CURRENT_LLX + $RAM_CURRENT_HEIGHT]
            set RAM_CURRENT_URY [expr $RAM_CURRENT_LLY + $RAM_CURRENT_WIDTH]

            set GUARD_SPACING [expr 2*$CELL_HEIGHT]

            set_attribute $RAM_CURRENT orientation "E"

            set_cell_location \
                -coordinates [list [expr $RAM_CURRENT_LLX ] [expr $RAM_CURRENT_LLY]] \
                -fixed \
                $RAM_CURRENT

            # Create blockage for filler-cell placement. 
            create_placement_blockage \
                -bbox [list [expr $RAM_CURRENT_LLX - $GUARD_SPACING] [expr $RAM_CURRENT_LLY - $GUARD_SPACING] \
                            [expr $RAM_CURRENT_URX + $GUARD_SPACING] [expr $RAM_CURRENT_URY + $GUARD_SPACING]] \
                -type hard

            # Connect RAM power to power grid
            connect_net VDD [get_pins -all $RAM_CURRENT/vdd]
            connect_net VSS [get_pins -all $RAM_CURRENT/gnd]
            incr INDEX
        }
    }
}



# for loop 3: output RAMs (seems like it should be BN but this is easier to set first)
set INDEX 0
for {set i 0} {$i < $NUM_OUTPUT_COLUMNS} {incr i} {
    for {set j 0} {$j < $NUM_OUTPUT_ROWS} {incr j} {
        if {$INDEX < $NUM_HIDDEN_RAMS} {
            echo $INDEX
            set RAM_CURRENT "fc_layer_1/genblk1_${INDEX}__neuron/weight_and_bias_mem/internal_rom/genblk1_genblk1_ram"

            # Get height and width of RAM
            set RAM_CURRENT_HEIGHT [get_attribute $RAM_CURRENT height]
            set RAM_CURRENT_WIDTH  [get_attribute $RAM_CURRENT width] 

            # Set Origin of RAM
            set RAM_SEPARATION_X [expr 40*$CELL_HEIGHT]
            set RAM_SEPARATION_Y [expr 40*$CELL_HEIGHT]

            set RAM_CURRENT_LLX [expr 15*$CELL_HEIGHT + [expr $i+1]*$RAM_SEPARATION_X + $i*$RAM_CURRENT_HEIGHT]
            set RAM_CURRENT_LLY [expr 2670*$CELL_HEIGHT - 15*$CELL_HEIGHT - [expr [expr $j + 1]*$RAM_CURRENT_WIDTH] - $j*$RAM_SEPARATION_Y]
            # Derive URX and URY corner for placement blockage. "Width" and "Height" are along wrong axes because we rotated the RAM.
            set RAM_CURRENT_URX [expr $RAM_CURRENT_LLX + $RAM_CURRENT_HEIGHT]
            set RAM_CURRENT_URY [expr $RAM_CURRENT_LLY + $RAM_CURRENT_WIDTH]

            set GUARD_SPACING [expr 2*$CELL_HEIGHT]

            set_attribute $RAM_CURRENT orientation "E"

            set_cell_location \
                -coordinates [list [expr $RAM_CURRENT_LLX ] [expr $RAM_CURRENT_LLY]] \
                -fixed \
                $RAM_CURRENT

            # Create blockage for filler-cell placement. 
            create_placement_blockage \
                -bbox [list [expr $RAM_CURRENT_LLX - $GUARD_SPACING] [expr $RAM_CURRENT_LLY - $GUARD_SPACING] \
                            [expr $RAM_CURRENT_URX + $GUARD_SPACING] [expr $RAM_CURRENT_URY + $GUARD_SPACING]] \
                -type hard

            # Connect RAM power to power grid
            connect_net VDD [get_pins -all $RAM_CURRENT/vdd]
            connect_net VSS [get_pins -all $RAM_CURRENT/gnd]
            incr INDEX
        }
    }
}


set BN_NAME_LIST {"scale_mem" "variance_mem" "mean_mem" "offset_mem"}
# for loop 3: output RAMs (seems like it should be BN but this is easier to set first)
set INDEX 0
for {set i 0} {$i < $NUM_OUTPUT_COLUMNS} {incr i} {
    for {set j 0} {$j < $NUM_OUTPUT_ROWS} {incr j} {
        if {$INDEX < $NUM_HIDDEN_RAMS} {
            echo $INDEX
            set CURRENT_NAME [lindex $BN_NAME_LIST $INDEX]
            echo $CURRENT_NAME
            set RAM_CURRENT "bn_layer_0/${CURRENT_NAME}/internal_rom/genblk1_ram"

            # Get height and width of RAM
            set RAM_CURRENT_HEIGHT [get_attribute $RAM_CURRENT height]
            set RAM_CURRENT_WIDTH  [get_attribute $RAM_CURRENT width] 

            # Set Origin of RAM
            set RAM_SEPARATION_X [expr 40*$CELL_HEIGHT]
            set RAM_SEPARATION_Y [expr 40*$CELL_HEIGHT]

            set RAM_CURRENT_LLX [expr 15*$CELL_HEIGHT + [expr $i+1]*$RAM_SEPARATION_X + $i*$RAM_CURRENT_HEIGHT + 5*$RAM_CURRENT_HEIGHT + 15*$RAM_SEPARATION_X]
            set RAM_CURRENT_LLY [expr 2670*$CELL_HEIGHT - 15*$CELL_HEIGHT - [expr [expr $j + 1]*$RAM_CURRENT_WIDTH] - $j*$RAM_SEPARATION_Y]
            # Derive URX and URY corner for placement blockage. "Width" and "Height" are along wrong axes because we rotated the RAM.
            set RAM_CURRENT_URX [expr $RAM_CURRENT_LLX + $RAM_CURRENT_HEIGHT]
            set RAM_CURRENT_URY [expr $RAM_CURRENT_LLY + $RAM_CURRENT_WIDTH]

            set GUARD_SPACING [expr 2*$CELL_HEIGHT]

            set_attribute $RAM_CURRENT orientation "E"

            set_cell_location \
                -coordinates [list [expr $RAM_CURRENT_LLX ] [expr $RAM_CURRENT_LLY]] \
                -fixed \
                $RAM_CURRENT

            # Create blockage for filler-cell placement. 
            create_placement_blockage \
                -bbox [list [expr $RAM_CURRENT_LLX - $GUARD_SPACING] [expr $RAM_CURRENT_LLY - $GUARD_SPACING] \
                            [expr $RAM_CURRENT_URX + $GUARD_SPACING] [expr $RAM_CURRENT_URY + $GUARD_SPACING]] \
                -type hard

            # Connect RAM power to power grid
            connect_net VDD [get_pins -all $RAM_CURRENT/vdd]
            connect_net VSS [get_pins -all $RAM_CURRENT/gnd]
            incr INDEX
        }
    }
}