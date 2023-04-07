/**
Alex Knowlton
4/3/2023

Rewritten fully-connected layer for readability and functionality, since this supports
layers of differing sizes. Assumes FIFO on both input and output.
*/

module fc_layer #(
    parameter WORD_SIZE=16,
    parameter LAYER_HEIGHT=5,
    parameter PREVIOUS_LAYER_HEIGHT=4,
    parameter LAYER_NUMBER=1 ) (
    
    // demanding interface
    input logic [WORD_SIZE-1:0] data_i,
    input logic empty_i,
    output logic ren_o,
    
    // demanding interface
    output logic valid_i,
    input logic ready_o,
    output logic [LAYER_HEIGHT-1:0][WORD_SIZE-1:0] data_o,

    input logic reset_i,
    input logic clk_i,

    // input for back-propagation, not currently used
    input logic [LAYER_HEIGHT-1:0][WORD_SIZE-1:0] weight_i,
    input logic mem_wen_i
    );

    // manage inputs internally and pass them to neurons
    // send neurons control signals, they are just a datapath
    logic add_bias, sum_en;
    logic [$clog2(PREVIOUS_LAYER_HEIGHT+1)-1:0] mem_addr;

    // FSM for control signals
    enum logic {eBUSY, eDONE} ps, ns;

    // next state logic
    always_comb begin
        case (ps)
            eBUSY:
                if (mem_addr == (LAYER_HEIGHT + 1)) // computation is done
                    ns = eDONE;
                else
                    ns = eBUSY;
            eDONE:
                // if handshake happens, then go back to busy
                if (valid_i && ready_o)
                    ns = eBUSY;
                else
                    ns = eDONE;
        endcase
    end

    // transition logic
    always_ff @(posedge clk_i) begin
        if (reset_i)
            ps <= eBUSY;
        else
            ps <= ns;
    end

    // internal control logic
    assign add_bias = (mem_addr == LAYER_HEIGHT + 1) && !empty_i;
    assign sum_en = (ps == eBUSY) && !empty_i;

    // memory address counter with enable signal
    // start on first cycle of busy cycle
    logic start_mem_counter;
    always_ff @(posedge clk_i)
        start_mem_counter <= (ps == eDONE) && (ns == eBUSY);

    up_counter_enabled #(
        .WORD_SIZE($clog2(PREVIOUS_LAYER_HEIGHT+1)),
        .INPUT_MAX(LAYER_HEIGHT + 1)
    ) mem_addr_counter (
        .start_i(start_mem_counter),
        .clk_i,
        .reset_i,
        .en_i(!empty_i && ps == eBUSY),
        .data_o(mem_addr)
    );

    // TODO: Generate neurons
    genvar i;
    generate
        for (i = 0; i < LAYER_HEIGHT; i = i + 1) begin
            fc_neuron #( 
                .WORD_SIZE(WORD_SIZE),
                .PREVIOUS_LAYER_HEIGHT(PREVIOUS_LAYER_HEIGHT),
                .MEM_INIT_FILE("fc_node_test.mif") // concatenate init file name together, not sure if this works
            ) neuron (
                .data_i,

                // control signals
                .mem_addr_i(mem_addr),
                .sum_en,
                .add_bias,

                .reset_i(reset_i || (ps == eDONE && ns == eDONE)),
                .clk_i,

                .data_o(data_o[i])
            );
        end
    endgenerate

endmodule