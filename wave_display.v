

module wave_display (
    input clk,
    input reset,
    input [10:0] x,  // [0..1279]
    input [9:0]  y,  // [0..1023]
    input valid,
    input [7:0] read_value,
    input read_index,
    output wire [8:0] read_address,
    output wire valid_pixel,
    output wire [7:0] r,
    output wire [7:0] g,
    output wire [7:0] b
);

// Read address: {read_index, 9th bit is 0 for quadrant 2 and 1 for quadrant 3, then we take x[7:1]
// as instructed
assign read_address = {read_index, x[9], x[7:1]};



wire [7:0] read_value_adjusted = (read_value >> 1) + 8'd32;

// take 8:1 bits of y for the y value
wire [7:0] y_val;
assign y_val = y[8:1];
// Logic, pixel is valid if 9th and 8th bit is 01 or 10, so we use xor. We also clip the first pixel
assign valid_pixel = (~y[9]) & (x[9] ^ x[8]) & valid & (x > 11'b00100000010);


// Flip-flop for address and value
wire [8:0] prev_addr;
dffr #(9) display_addr_flipflop(.clk(clk), .r(reset), .d(read_address), .q(prev_addr));
wire [7:0] prev_value;
dffre #(8) display_val_flipflop(.clk(clk), .r(reset), .en(read_address != prev_addr), .d(read_value_adjusted), .q(prev_value));


// Logic: If the current y_value is inbetween the current and previous rom_values, then
reg displayLine;
always @(*) begin
	if(y_val >= prev_value && y_val <= read_value_adjusted) displayLine = 1; //prev_value < read_value
	else if(y_val <= prev_value && y_val >= read_value_adjusted) displayLine = 1; //prev_value > read_value
	else displayLine = 0;
end

assign {r,g,b} = (displayLine & valid) ? 24'hFFFFFF : 24'h000000;

endmodule