`timescale 1ns / 1ps

module main_tb ();

  reg clk = 1'b0;
  reg btn_left = 1'b0;
  reg btn_right = 1'b0;
  reg btn_go = 1'b0;
  reg btn_rst = 1'b0;

  wire hsync, vsync;
  wire [1:0] r, g, b;

  // Raw 12 MHz oscillator into main.v's `clk` input (period ~83.33ns).
  // With pll.v compiled using -DSIM, the PLL is bypassed and this signal
  // is unused downstream -- kept here so the testbench still matches
  // real hardware timing if a true PLL sim model is swapped in later.
  always #19.9 clk = ~clk;

  // One frame = 800 x 525 = 420000 vga_clk cycles at 25.125 MHz
  // = 420000 * (1 / 25.125MHz) =~ 16,716,418 ns (~16.7 ms)
  localparam real FRAME_NS = 35000321.667;
  localparam NUM_FRAMES = 4;

  main uut (
      .clk(clk),
      .btn_left(btn_left),
      .btn_right(btn_right),
      .btn_go(btn_go),
      .btn_rst(btn_rst),
      .hsync(hsync),
      .vsync(vsync),
      .r(r),
      .g(g),
      .b(b)
  );

  // Log game state once per frame (hierarchical refs into main's internals)
  always @(posedge uut.frame_tick) begin
    $display("t=%0t ns | state=%0d | ball=(%0d,%0d) | paddle_x=%0d", $time, uut.state,
             uut.ball_pos_x, uut.ball_pos_y, uut.paddle_pos_x);
  end

  initial begin
    //dumpfile("main_tb.vcd");
    $dumpvars(1, main_tb);


    // Sit in IDLE a couple frames, then press GO -> STATE_START
    // #(FRAME_NS*3);
    btn_go  = 1'b1;
    #(FRAME_NS);  // hold across at least one frame_tick edge
    btn_go = 1'b0;

    // Press GO again -> STATE_PLAY
    btn_go = 1'b1;
    #(FRAME_NS);
    btn_go = 1'b0;

    // Exercise paddle movement
    btn_right = 1'b0;
    #(FRAME_NS * 2);
    btn_right = 1'b0;

    // Let the ball bounce around and watch collisions in the log/vcd
    #(FRAME_NS * NUM_FRAMES);

    $display("Finished!");
    $finish;
  end

endmodule
