//module wave_display (
//    input clk,
//    input reset,
//    input [10:0] x,  // [0..1279]
//    input [9:0]  y,  // [0..1023]
//    input valid,
//    input [7:0] read_value,
//    input read_index,
//    output wire [8:0] read_address,
//    output wire valid_pixel,
//    output wire [7:0] r,
//    output wire [7:0] g,
//    output wire [7:0] b
//);
//    wire [10:0] prev_x;
//    wire [9:0] prev_y;
    
//      // I think you can just use RAM[X-1] since it all stays stored so don't need to track X
////    dffr #(11) x_tracker (
////        .clk(clk),
////        .r(reset),
////        .d(x),
////        .q(prev_x)
////    );
    
//    wire [7:0] prev_value;
//    wire [7:0] prev_address;
    
//    dffre #(8) value_flipflop(
//        .clk(clk), 
//        .r(reset), 
//        .en(read_address != prev_address),
//        .d(read_value),
//        .q(prev_value)
//    );
    
//    dffr #(8) address_flipflop(
//        .clk(clk), 
//        .r(reset), 
//        .d(read_addr),
//        .q(prev_address)
//    );
    
    
//    dffr #(10) y_tracker (
//        .clk(clk),
//        .r(reset),
//        .d(y),
//        .q(prev_y)
//    );
    
//    // r b and g are all wires so can't use ifs or always statements
//    assign r = (x > 11'd600 && x < 11'd800 && y > 10'd400 && y < 10'd600 && valid) ? 8'b11111111 : 8'b00000000;
//    assign g = (x > 11'd600 && x < 11'd800 && y > 10'd400 && y < 10'd600 && valid) ? 8'b11111111 : 8'b00000000;
//    assign b = (x > 11'd600 && x < 11'd800 && y > 10'd400 && y < 10'd600 && valid) ? 8'b11111111 : 8'b00000000;
    
//    always @(*) begin
////        if (x > 11'd600 && x < 11'd800 && y > 10'd400 && y < 10'd600 && valid) begin
////            r = 8'd
////            {r, g, b} = 24'h00FF00;
////        else
////            {r, g, b} = 24'h000000;
////        end
        
////        case(x)
////        11'b000xxxxxxxx: begin
            
////        endcase
            
//    end

//// Implement me!
//endmodule


//module wave_display (
//    input clk,
//    input reset,
//    input [10:0] x,  // [0..1279]
//    input [9:0]  y,  // [0..1023]
//    input valid,
//    input [7:0] read_value,
//    input read_index,
//    output wire [8:0] read_address,
//    output wire valid_pixel,
//    output wire [7:0] r,
//    output wire [7:0] g,
//    output wire [7:0] b
//);

//    //combinational block 1
//    wire in_top_half      = ~y[9];
//    wire in_mid_quadrants = (x[10:9] == 2'b10) || (x[10:9] == 2'b01);
//    wire possible        =  valid & in_top_half & in_mid_quadrants;

//    //drop msb/lsb of y
//    wire [7:0] y8 = y[8:1];

//    reg  [7:0] sample_index; //determines read_addr

//    always @(*) begin
//        case (x[10:9])
//            2'b01:   sample_index = {1'b0, x[7:1]};
//            2'b10:   sample_index = {1'b1, x[7:1]};
//            default: sample_index = 8'h00; //dont care
//        endcase
//    end

//    assign read_address = {read_index, sample_index};
   
//    //FFs
//    //checks for validity and y must be 1-cycle delayed to match ram delay; need FFs
//    wire       possible_delayed;
//    wire [7:0] y8_delayed;

//    dffr possible_delay
//    (.clk(clk),
//    .r(reset),
//    .d(possible),
//    .q(possible_delayed));
   
//    dffr #(8) y8_delay
//    (.clk(clk),
//    .r(reset),
//    .d(y8),        
//    .q(y8_delayed));

//    //we also need an FF for read_addr to detect address changes every other cc
//    wire [8:0] read_address_delayed;
//    dffr #(9) read_address_delay
//    (.clk(clk),
//    .r(reset),
//    .d(read_address),
//    .q(read_address_delayed));

//    wire addr_changed = (read_address != read_address_delayed);
   
//    //and we need to delay addr_changed by 1 cc to line up with new ram data
//    wire addr_changed_delayed;
//    dffr addr_changed_delay
//    (.clk(clk),
//    .r(reset),
//    .d(addr_changed),
//    .q(addr_changed_delayed));

//    wire accept_sample = addr_changed_delayed; //this tells us when we should take in a new sample

//    wire [7:0] read_value_adjusted = (read_value >> 1) + 8'd32; //view window alignment

//    //actual sample FF, need enable by accept_sample
//    wire [7:0] curr_sample;
//    wire [7:0] prev_sample;

//    // curr_sample from read_value_adjusted
//    dffre #(8) curr_sample_get
//    (.clk(clk),
//    .r(reset),
//    .en(accept_sample),
//    .d(read_value_adjusted),
//    .q(curr_sample));

//    // prev_sample from curr_sample
//    dffre #(8) prev_sample_get
//    (.clk(clk),
//    .r(reset),
//    .en(accept_sample),
//    .d(curr_sample),
//    .q(prev_sample));
   
//    //prevent display from rendering first 2 accepted samples to avoid initial artifacts
//    wire [1:0] sample_count;
//    wire [1:0] sample_count_next =
//        (sample_count == 2'd2) ? 2'd2 : (sample_count + 2'd1); //1 at 0, 2 at 1

//    dffre #(2) sample_count_check
//    (.clk(clk),
//    .r(reset),
//    .en(accept_sample),
//    .d(sample_count_next),
//    .q(sample_count));

//    wire have_two_samples = (sample_count == 2'd2);

//    // combinational block 2
//    wire [7:0] lo = (prev_sample <= curr_sample) ? prev_sample : curr_sample; //min
//    wire [7:0] hi = (prev_sample <= curr_sample) ? curr_sample : prev_sample; //max

//    assign valid_pixel = (have_two_samples) & (possible_delayed) & (y8_delayed >= lo) & (y8_delayed <= hi);

//    //rgb: white when on, black when off
//    assign r = valid_pixel ? 8'hFF : 8'h0;
//    assign g = valid_pixel ? 8'hFF : 8'h0;
//    assign b = valid_pixel ? 8'hFF : 8'h0;

//endmodule

