module mcu(
    input clk,
    input reset,
    input play_button,
    input next_button,
    output play,
    output reset_player,
    output [1:0] song,
    input song_done
);

    // Implementation goes here!
    //State control: PAUSED/PLAYSONG
    reg next; //next state 
    wire cur_state;
    
    parameter PAUSED = 1'b0;
    parameter PLAYSONG = 1'b1;

    dffr state_control(
        .clk (clk),
        .r (reset),
        .d (next), 
        .q (cur_state)
    );
    
    //State control: SONG IDX
    reg [1:0] next_song;
    
    dffr #(2) song_control(
        .clk (clk),
        .r (reset),
        .d (next_song), 
        .q (song)
    ); 
      
    //State control: RESET_PLAYER
    //Reset_player is a one-pulse cycle on song_done or next, so long as reset button isn't pressed 
    wire reset_player_d;
    assign reset_player_d = (song_done | next_button) & ~reset;

    dffr reset_player_control (
        .clk(clk),
        .r(reset),
        .d(reset_player_d),
        .q(reset_player)
    );
    
    assign play = (cur_state == PLAYSONG);
    
    //Combinational logic for given state
    always @* begin
        
        //Do nothing if nothing pressed, song not done
        next = cur_state; //also enabled implicit reset logic - on reset, cur_state holds 0 for 1 cycle, which makes next 0
        next_song = song; //ditto
        
        //Song_done or next_button logic is the same 
        if (song_done | next_button) begin
            next_song = song + 1; //wraps around without mod bc 2 bits long
            next = PAUSED;
        end else begin
        //Play button logic
        case (cur_state)
            PAUSED: if (play_button) next = PLAYSONG; //no need for else bc next always defined at top
            PLAYSONG: if (play_button) next = PAUSED; //ditto 
            default: next = PAUSED;
        endcase
        end
    end
endmodule