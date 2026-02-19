module song_reader(
    input clk,
    input reset,
    input play,
    input [1:0] song,
    input note_done,
    output song_done,
    output [5:0] note,
    output [5:0] duration,
    output new_note
);
    
    //4 states:
    //REST (idle),
    //LOAD-ROM (1-cycle delay to load addr and fetch data 
    //SEND-NOTE (1-cycle delay that sends new_note to note player)
    //HOLD_NOTE (holds until note_done)
    
    //7-bit addr with [2'song, 5'note]
    wire [4:0] song_note_idx;
    wire [6:0] rom_addr = {song, song_note_idx};
    
    //12-bit return data with [6'note, 6'duration] 
    wire [11:0] rom_data;
    wire [5:0] note_pitch = rom_data [11:6];
    wire [5:0] note_dur = rom_data [5:0];
    
    //ROM init
    song_rom rom(
        .clk(clk),
        .addr(rom_addr),
        .dout(rom_data)
    );
    
    assign note = note_pitch;
    assign duration = note_dur;
    
    //FFs for: STATE, SONG_NOTE_IDX, SONG CHANGING
    parameter IDLE = 2'b00;
    parameter LOAD_ROM = 2'b01;
    parameter SEND_NOTE = 2'b10;
    parameter HOLD_NOTE = 2'b11;
    
    wire [1:0] state;
    reg [1:0] next_state;
    dffr #(2) state_machine(
        .clk(clk),
        .r(reset),
        .d(next_state),
        .q(state)
    );
    
    reg [4:0] next_note_idx;
    dffr #(5) idx_control(
        .clk(clk),
        .r(reset),
        .d(next_note_idx),
        .q(song_note_idx)
    );
    
    //if song changed, we need to head to idle and note 0 for the next song 
    wire [1:0] prev_song;
    reg [1:0] prev_song_in; 
    dffr #(2) prev_song_check(
        .clk(clk),
        .r(reset),
        .d(prev_song_in),
        .q(prev_song)
    ); //this will be diff from song for 1 cycle on a change 
    
    
    //FSM logic
    assign new_note = (state == SEND_NOTE) && play; //play = 0: pause, goto IDLE 
    //song ends in 2 cases: either we encounter a note with dur 0 in SEND_NOTE, or idx = 31 and note_done in HOLD_NOTE
    assign song_done = ((state == SEND_NOTE) && play && (note_dur == 6'd0)) || ((state == HOLD_NOTE) && note_done && (song_note_idx == 5'd31));
    
    always @(*) begin
        //defaults: inputs = outputs
        next_state = state;
        prev_song_in = song;
        next_note_idx = song_note_idx;
        
        //if song changed, we need to head to idle and note 0 for the next song 
        if (prev_song != song) begin
            next_state = IDLE;
            next_note_idx = 5'd0;
        end else begin
            case (state)
                IDLE: begin
                    if (play) begin
                        next_state = LOAD_ROM;
                    end
                end LOAD_ROM: begin
                    if (!play) begin
                        next_state = IDLE; //pause 
                    end else begin
                        next_state = SEND_NOTE; //1 CC delay 
                    end
                end SEND_NOTE: begin
                    if (!play) begin
                        next_state = IDLE; //pause 
                    end else if (note_dur == 6'b0) begin 
                        next_state = IDLE; 
                        next_note_idx = 5'd0; //pulse song_done
                    end else begin 
                        next_state = HOLD_NOTE;
                    end
                end HOLD_NOTE: begin
                    //no !play logic here, hold until the note is done then check in other states 
                    if (note_done) begin 
                        if (song_note_idx == 5'd31) begin
                            next_state = IDLE;
                            next_note_idx = 5'b0; //we also pulse song_done here
                        end else begin
                            next_state = LOAD_ROM;
                            next_note_idx = song_note_idx + 1; //increment idx since we know we're not yet at the end
                        end
                    end
                end default: begin
                    next_state = IDLE;
                end
            endcase
        end
    end 
endmodule

