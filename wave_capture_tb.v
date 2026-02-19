`timescale 1ns/1ps

module wave_capture_tb;

    reg clk;
      reg reset;
      reg new_sample_ready;
      reg [15:0] new_sample_in; //need to assign fresh values to this each time
      reg wave_display_idle;
    wire [8:0] write_address;
    wire write_enable;
    wire read_index;
    wire [7:0] write_sample;
      reg [7:0] addr;
      
   
   
    wire [15:0] prev_sample;
   
    dff #(16) sample_flip_flop(
        .clk(clk),
        .d(new_sample_in),
        .q(prev_sample)
    );

    wave_capture capture_sim (
        .clk(clk),
        .reset(reset),
        .new_sample_ready(new_sample_ready),
        .new_sample_in(new_sample_in),
        .wave_display_idle(wave_display_idle),
        .write_address(write_address),
        .write_enable(write_enable),
        .write_sample(write_sample),
        .read_index(read_index)
    );

    // Clock and reset
    initial begin
            addr = 0;
        clk = 1'b0;
        reset = 1'b1;
        repeat (4) #5 clk = ~clk;
        reset = 1'b0;
        forever #1 clk = ~clk;
    end
   
   
   
    initial begin
    wave_display_idle = 1;
        @(negedge reset);
        @(negedge clk);

    //check reset
    reset = 1;
    new_sample_ready = 0;
    wave_display_idle = 0;
    new_sample_in = 0;
    #5;
    reset = 0;

    // check zero crossing
    new_sample_ready = 1;
    new_sample_in = 16'h3333; //pos [15] = 0
    #1;
    new_sample_ready = 0;
    #9;
   
    new_sample_ready = 1;
    new_sample_in = 16'h2173; //pos [15] = 0
    #1;
    new_sample_ready = 0;
    #9;
   
    new_sample_ready = 1;
    new_sample_in = 16'h8080; //neg [15] = 1
    #1;
    new_sample_ready = 0;
    #9;
   
    new_sample_ready = 1;
    new_sample_in = 16'h0000; //pos [15] = 0 zero cross should trigger
    #1;
    new_sample_ready = 0;
    #9;
   
//    #10 new_sample_in = 16'h3333; //pos [15] = 0
//    #10 new_sample_in = 16'h2173; //pos [15] = 0
//    #10 new_sample_in = 16'h8080; //neg [15] = 1
//    //goes positive, positive, negative so shouldn't go live and state should still be armed
//    #20 new_sample_in = 16'h0001; //pos
//    //zero cross should activiate here
   
    //go up to 256 then try a couple extra to make sure it's not updating those while in wait
    repeat (260) begin
        new_sample_ready = 1;
        //new_sample_in = prev_sample + 16'd1; this is incrementing the least important so
        //write_sample isn't changing
        new_sample_in = {prev_sample[15:8]+1,8'd0};
        #2;
        new_sample_ready = 0;
        #2;
       
    end
   
   
    #20 new_sample_in = 16'd0;
    //count shouldn't update (stays at 255) and
    wave_display_idle = 1;
    #5
    wave_display_idle = 0;

    //Should go back to ARMED
    #20
    //should show that read_index is now flipped
    $display(read_index);

    $stop;
end
      
      
endmodule
