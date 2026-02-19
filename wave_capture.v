`define ARMED 2'b00
`define ACTIVE 2'b01
`define WAIT 2'b10
module wave_capture (
    input clk,
    input reset,
    input new_sample_ready,
    input [15:0] new_sample_in,
    input wave_display_idle,

    output wire [8:0] write_address,
    output wire write_enable,
    output wire [7:0] write_sample,
    output wire read_index
);

    wire [1:0] curr_state;
    reg [1:0] next_state;
    
    dffr #(2) state_flip_flop(
        .clk(clk),
        .r(reset),
        .d(next_state),
        .q(curr_state)
    );
    
    //reg [15:0] curr_sample;
    wire [15:0] prev_sample;
    
    wire zero_cross;
    assign zero_cross = (prev_sample[15] == 1) && (new_sample_in[15] == 0); //changed new_sample_in from curr_sample
    //most significant bit is the pos/neg bit
    
    
    dffre #(16) sample_flipflop_new(
        .clk(clk), 
        .r(reset), 
        .en(new_sample_ready), 
        .d(new_sample_in), 
        .q(prev_sample) //changed from curr_sample
   );
   
//   // need second flip flop to hold old sample 
//   dffre #(16) sample_flipflop_old(
//        .clk(clk), 
//        .r(reset), 
//        .en(new_sample_ready), 
//        .d(curr_sample), 
//        .q(prev_sample)
//   );
   
    wire [8:0] curr_count;
    reg [8:0] next_count;
   
    dffre #(9) address_flip_flop(
        .clk(clk),
        .r(reset),
        .en(new_sample_ready),
        .d(next_count),
        .q(curr_count)
    );
    
    reg new_read_index;
    
    dffr #(1) index_flip_flop(
        .clk(clk),
        .r(reset),
        .d(new_read_index),
        .q(read_index)
    );
    
    always @(*) begin
        case(curr_state)
            //Armed
            `ARMED: begin
                next_state = zero_cross ? `ACTIVE : `ARMED;
                next_count =  0;
                new_read_index = read_index;
            end
            `ACTIVE: begin
                next_state = (curr_count == 9'd255) ? `WAIT : `ACTIVE;
                new_read_index = read_index;
                // will only store values at a new address if the new_sample_ready is hot otherwise 
                // it will just keep putting the same note back into the memory like it should
                if (new_sample_ready) begin
                    next_count = curr_count + 1;
                end
                else begin
                    next_count = curr_count;
                end
                
            end
            `WAIT: begin
                next_state = wave_display_idle ? `ARMED : `WAIT;
                next_count = curr_count;
                new_read_index = wave_display_idle ? ~read_index : read_index;
            end
            default : begin 
		      next_state = `ARMED;
		      next_count = 0;
		      new_read_index = read_index;
	end
        endcase
    end
    
    assign write_address = {~read_index, curr_count}; //it is ~read_index so when read_index is hot
    // it's going to 0-255 and when it's low it's going to 256-511. Explained in double buffering part
    assign write_enable = (curr_state == `ACTIVE); //will only store valyes if
    //assign write_sample = new_sample_in[15:8];
    assign write_sample = {~new_sample_in[15], new_sample_in[14:8]};
    
    
    
// Implement me!
endmodule
