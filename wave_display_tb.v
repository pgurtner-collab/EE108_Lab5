`timescale 1ns/1ps

module tb_wave_display;
  reg clk;
  reg reset;
  reg [10:0] x;
  reg [9:0] y;
  reg valid;
  reg [7:0] read_value;
  reg read_index;
  wire [8:0] read_address;
  wire valid_pixel;
  wire [7:0] r, g, b;

  wave_display dut (
    .clk(clk),
    .reset(reset),
    .x(x),
    .y(y),
    .valid(valid),
    .read_value(read_value),
    .read_index(read_index),
    .read_address(read_address),
    .valid_pixel(valid_pixel),
    .r(r),
    .g(g),
    .b(b)
  );

  wire [7:0] ram_dout;

  fake_sample_ram ram (
    .clk  (clk),
    .addr (read_address[7:0]),  //use fake ram
    .dout (ram_dout)
  );

  always @(*) begin
    read_value = ram_dout;
  end

  // clock

  initial begin
    clk = 0;
    forever #5 clk = ~clk;   // 100 MHz
  end

  initial begin
    reset      = 1;
    x          = 0;
    y          = 0;
    valid      = 0;
    read_index = 0;

    #40;
    reset = 0;
  end

  // check pixel colors

  integer errors = 0;

  // driving a pixel

  task drive_pixel;
    input [10:0] xi;
    input [9:0]  yi;
    input        v;
    begin
      @(negedge clk);
      x     = xi;
      y     = yi;
      valid = v;
    end
  endtask

  // check for valid bounding box

  integer xi, yi;

  initial begin
    @(negedge reset);
    repeat (4) @(posedge clk);

    for (yi = 0; yi < 512; yi = yi + 1) begin
      for (xi = 512; xi < 1280; xi = xi + 1) begin
        drive_pixel(xi, yi, 1'b1);
      end
    end

    drive_pixel(11'd0, 10'd0, 1'b1);
    if (valid_pixel) begin
      errors = errors + 1;
      $display("ERROR: valid_pixel outside X window");
    end

    drive_pixel(11'd600, 10'd700, 1'b1);
    if (valid_pixel) begin
      errors = errors + 1;
      $display("ERROR: valid_pixel outside Y window");
    end

    if (errors == 0)
      $display("\n=== tb_wave_display: PASS ===\n");
    else
      $display("\n=== tb_wave_display: FAIL (%0d errors) ===\n", errors);

    $finish;
  end

endmodule
