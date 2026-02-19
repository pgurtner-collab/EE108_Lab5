module wave_display (
    input clk,
    input reset,
    input [10:0] x,         
    input [9:0] y, 
    input valid,
    input [7:0] read_value,
    input read_index,
    output [8:0] read_address,
    output valid_pixel,
    output [7:0] r,
    output [7:0] g,
    output [7:0] b
);

    // combinational: check for possible placement
    wire possible = valid & (~y[9]) & ((x[9:8] == 2'b01) || (x[9:8] == 2'b10));

    // drop msb, LSB of y (2px tall)
    wire [7:0] y8 = y[8:1];

    //format for read_addr
    reg [7:0] sample_index;

    always @(*) begin
        case (x[9:8])
            2'b01:   sample_index = {1'b0, x[7:1]};
            2'b10:   sample_index = {1'b1, x[7:1]};
            default: sample_index = 8'h00; //don't care
        endcase
    end

    assign read_address = {read_index, sample_index};

    //ffs: delay possible, y alignment to match RAM access delay
    wire possible_delayed;
    wire [7:0] y8_delayed;

    dffr possible_delay (
        .clk(clk),
        .r(reset),
        .d(possible),
        .q(possible_delayed)
    );

    dffr #(8) y8_delay (
        .clk(clk),
        .r(reset),
        .d(y8),
        .q(y8_delayed)
    );

    // ff: read_address
    wire [8:0] read_address_delayed;

    dffr #(9) read_address_delay (
        .clk(clk),
        .r(reset),
        .d(read_address),
        .q(read_address_delayed)
    );

    wire addr_changed = (read_address != read_address_delayed); //checks for when we actually change the RAM addr
    //but, we need to delay that 1 cc
    wire addr_changed_delayed;
    dffr addr_changed_delay (
        .clk(clk),
        .r(reset),
        .d(addr_changed),
        .q(addr_changed_delayed)
    );

    wire accept_sample = addr_changed_delayed; //this is when we know to actually read the sample

    //adjustmentt
    wire [7:0] read_value_adjusted = (read_value >> 1) + 8'd32;

    // ff: sample and prev_sample update, en on accept_sample
    wire [7:0] curr_sample;
    wire [7:0] prev_sample;

    dffre #(8) curr_sample_get (
        .clk(clk),
        .r(reset),
        .en(accept_sample),
        .d(read_value_adjusted),
        .q(curr_sample)
    );

    dffre #(8) prev_sample_get (
        .clk(clk),
        .r(reset),
        .en(accept_sample),
        .d(curr_sample),
        .q(prev_sample)
    );

    // more combinational: valid_pixel logic
    wire [7:0] lo = (prev_sample <= curr_sample) ? prev_sample : curr_sample;
    wire [7:0] hi = (prev_sample <= curr_sample) ? curr_sample : prev_sample;

    assign valid_pixel =  possible_delayed & (y8_delayed >= lo) & (y8_delayed <= hi) & (y8_delayed > 8'd22) & (x > 11'd300); //crop artifacts

    //rgb
    assign r = valid_pixel ? 8'hFF : 8'h00;
    assign g = valid_pixel ? 8'hFF : 8'h00;
    assign b = valid_pixel ? 8'hFF : 8'h00;

endmodule
