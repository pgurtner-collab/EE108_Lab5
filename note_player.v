module note_player(
    input clk,
    input reset,
    input play_enable,  // When high we play, when low we don't.
    input [5:0] note_to_load,  // The note to play
    input [5:0] duration_to_load,  // The duration of the note to play
    input load_new_note,  // Tells us when we have a new note to load
    output done_with_note,  // When we are done with the note this stays high.
    input beat,  // This is our 1/48th second beat
    input generate_next_sample,  // Tells us when the codec wants a new sample
    output [15:0] sample_out,  // Our sample output
    output new_sample_ready  // Tells the codec when we've got a sample
);
    
    // Implementation goes here!
    
    //for counter
    wire [6:0] next;
    wire [6:0] count;
    
    //for freq_rom and sine_reader
    wire [5:0] curr_note;
	wire [19:0] sin_step;
	wire [19:0] freq_out;
    
    
    dffre #(7) counter_flip_flop (
        .clk(clk),
        .en(play_enable),
        .r(reset | count == duration_to_load), //also needs to reset the counter when count is equal to duration
        .d(next),
        .q(count)
    );
    
    assign next = beat ? 1'd1 + count : count; // if beat is hot increment count
    assign done_with_note = (count == duration_to_load); // if count is equal to the duration, we are done
                                        // and it should stop playing 
    
    dffre #(6) note_flip_flop (
        .clk(clk), 
        .r(reset), 
        .en(load_new_note), 
        .d(note_to_load), 
        .q(curr_note)
    );
    
    frequency_rom freq (
        .clk(clk), 
		.addr(curr_note), 
		.dout(freq_out)
    );
    
    sine_reader sin_read(
        .clk(clk), 
		.reset(reset), 
		.step_size(sin_step), 
		.generate_next(generate_next_sample), 
		.sample_ready(new_sample_ready), 
		.sample(sample_out));
    
    assign sin_step = play_enable ? freq_out : 20'b0;
    
    

endmodule
