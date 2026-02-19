
`define NEXT_STATE 2'd1
`define WAITING 2'd0
`define GENERATING 2'd2

module sine_reader(
    input clk,
    input reset,
    input [19:0] step_size,
    input generate_next,

    output sample_ready,
    output wire [15:0] sample
);

    // for flip flops
    wire [21:0] curr_addr;
	reg [21:0]  next_addr;
	wire [15:0] rom_out;
	
	//State flip flop
	wire [1:0] state;
	reg [1:0] next_state;
	//for

    //implementation goes here!
    sine_rom s_rom(
        .clk(clk),
        .addr(curr_addr[19:10]),
        .dout(rom_out)
    );
        
    dffre #(22) rom_flipflop(
        .clk(clk),
        .r(reset),
        .en(generate_next),
        .d(next_addr),
        .q(curr_addr)
    );
    
	
    dffr #(2) counter(
        .clk(clk),
        .r(reset),
        .d(next_state),
        .q(state)
    );
    
    
    always @(*) begin
		case(curr_addr[20])
			0 : begin 
			                             //this is the max value before overflow so check it doesn't overflow,                                             this is equal to 1
				next_addr[19:0] = ((20'b11111111111111111111 - step_size) < curr_addr[19:0]) ? (20'b11111111111111111111 - (curr_addr[19:0] + step_size + 20'b00000000010000000000)) : (curr_addr[19:0] + step_size);
				next_addr[21:20] = ((20'b11111111111111111111 - step_size) <= curr_addr[19:0]) ? curr_addr[21:20] + 2'd1 : curr_addr[21:20];
			end			
			
			1 : begin 
				next_addr[19:0] = (step_size > curr_addr[19:0]) ? (20'd0 - (curr_addr[19:0] - step_size - 20'b00000000010000000000)) : (curr_addr[19:0] - step_size);
				next_addr[21:20] = (step_size >= curr_addr[19:0]) ? curr_addr[21:20] + 2'd1 : curr_addr[21:20];
			end			

			default: begin
				next_addr = curr_addr;
			end
		endcase
	end
	
//	always @(*) begin
//	   case(curr_addr[20])
//	       0: begin
//	           if ((20'b11111111111111111111 - step_size) < curr_addr[19:0]) begin
//	               next_addr[19:0] = 0;
//	       end
//	end

    reg next_sign;
	wire sign;
	dffr #(1) sign_flipflop(
	   .clk(clk),
	   .r(reset), 
	   .d(next_sign), 
	   .q(sign));
	   
	assign sample = (sign) ? (16'd0 - rom_out) : (rom_out);
	
	always @(*) begin
		case(state)
			`NEXT_STATE : begin
				next_state = (generate_next) ? `GENERATING : `WAITING;
				next_sign = curr_addr[21];
			end
			
			`WAITING : begin 
				next_state = (generate_next) ? `GENERATING : `WAITING;
				next_sign = sign;
			end
			`GENERATING : begin 
				next_state = `NEXT_STATE;
				next_sign = curr_addr[21];
			end
			default: begin
				next_state = `WAITING;
				next_sign = sign;
			end
		endcase
	end
	
	assign sample_ready = (state == `NEXT_STATE);
    
endmodule
