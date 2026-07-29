module main (

    //Inputs
    input clk,
    input btn_left,
    input btn_right,
    input btn_go,
    input btn_rst,

    //Outputs
    output wire hsync,
    output wire vsync,
    output wire [1:0] r,
    output wire [1:0] g,
    output wire [1:0] b
);
  //STATE
  reg  [1:0] state;

  //VGA CLOCK GENERATOR
  wire       vga_clk;

  //Create vga clock signal of 25.125 MHz
  // pll clk_multiplier (
  //     .inp_clk(clk),
  //     .out_clk(vga_clk)
  // );

  assign vga_clk = clk;  //Simulation clock

  //VGA TIMING GENERATOR

  // wire hsync;
  // wire vsync;
  wire frame_tick;
  wire [9:0] pixel_x;
  wire [8:0] pixel_y;
  wire vga_active;

  vga vga_timer (
      .vga_clk(vga_clk),
      .hsync(hsync),
      .vsync(vsync),
      .frame_tick(frame_tick),
      .pixel_x(pixel_x),
      .pixel_y(pixel_y),
      .active(vga_active)
  );

  //Game Piece Positions
  wire signed [ 10:0] ball_pos_x;
  wire signed [  9:0] ball_pos_y;
  wire signed [ 10:0] paddle_pos_x;

  wire        [135:0] brick_alive;

  wire        [  1:0] lives;
  wire        [ 13:0] score;

  //GAME ELEMENT CONSTANTS
  //States
  localparam STATE_IDLE = 2'd0;
  localparam STATE_START = 2'd1;
  localparam STATE_PLAY = 2'd2;
  localparam STATE_OVER = 2'd3;

  //DEFAULT VALUES
  localparam signed BALL_START_X = 11'sd283;
  localparam signed BALL_START_Y = 10'sd231;
  localparam signed BALL_START_DX = -4'sd3;
  localparam signed BALL_START_DY = -4'sd3;
  localparam signed PADDLE_START_X = 11'sd320;  //Middle of paddle
  localparam signed PADDLE_POS_Y = 10'sd400;  //Top of paddle
  localparam START_LIVES = 2'd3;
  localparam signed BALL_RADIUS = 4'd6;
  localparam signed PADDLE_WIDTH = 6'd30;  //Half the width
  localparam signed PADDLE_HEIGHT = 5'd6;  //Full Height
  localparam signed PADDLE_DX = 4'd3;
  localparam INFO_HEIGHT = 7'd50;
  localparam signed CEIL_Y = INFO_HEIGHT + 5;

  //BRICK DEFAULT VALUES
  localparam BRICK_WIDTH = 32;
  localparam BRICK_HEIGHT = 12;
  localparam BRICK_GAP_X = 6;
  localparam BRICK_GAP_Y = 4;

  localparam NUM_ROWS = 8;
  localparam NUM_COLS = (640 + BRICK_GAP_X) / (BRICK_WIDTH + BRICK_GAP_X);
  localparam FIRST_ROW_Y = 100;
  localparam LAST_ROW_Y = (100 + NUM_ROWS * 16);
  localparam FIRST_COL_X = 0;



  //GAME LOGIC
  game_logic #(
      .STATE_IDLE(STATE_IDLE),
      .STATE_START(STATE_START),
      .STATE_PLAY(STATE_PLAY),
      .STATE_OVER(STATE_OVER),
      .BALL_START_X(BALL_START_X),
      .BALL_START_Y(BALL_START_Y),
      .BALL_START_DX(BALL_START_DX),
      .BALL_START_DY(BALL_START_DY),
      .PADDLE_START_X(PADDLE_START_X),
      .PADDLE_POS_Y(PADDLE_POS_Y),
      .START_LIVES(START_LIVES),
      .BALL_RADIUS(BALL_RADIUS),
      .PADDLE_WIDTH(PADDLE_WIDTH),
      .PADDLE_HEIGHT(PADDLE_HEIGHT),
      .PADDLE_DX(PADDLE_DX),
      .INFO_HEIGHT(INFO_HEIGHT),
      .CEIL_Y(CEIL_Y),
      .BRICK_WIDTH(BRICK_WIDTH),
      .BRICK_HEIGHT(BRICK_HEIGHT),
      .BRICK_GAP_X(BRICK_GAP_X),
      .BRICK_GAP_Y(BRICK_GAP_Y),
      .NUM_ROWS(NUM_ROWS),
      .NUM_COLS(NUM_COLS),
      .FIRST_ROW_Y(FIRST_ROW_Y),
      .LAST_ROW_Y(LAST_ROW_Y),
      .FIRST_COL_X(FIRST_COL_X)
  ) game (
      .frame_tick(frame_tick),
      .btn_go(btn_go),
      .btn_rst(btn_rst),
      .btn_left(btn_left),
      .btn_right(btn_right),
      .ball_pos_x(ball_pos_x),
      .ball_pos_y(ball_pos_y),
      .paddle_pos_x(paddle_pos_x),
      .state(state),
      .brick_alive(brick_alive),
      .lives(lives),
      .score(score)
  );

  //PIXEL MUX
  mux #(
      .STATE_IDLE(STATE_IDLE),
      .STATE_START(STATE_START),
      .STATE_PLAY(STATE_PLAY),
      .STATE_OVER(STATE_OVER),
      .BALL_RADIUS(BALL_RADIUS),
      .PADDLE_WIDTH(PADDLE_WIDTH),
      .PADDLE_HEIGHT(PADDLE_HEIGHT),
      .PADDLE_POS_Y(PADDLE_POS_Y),
      .INFO_HEIGHT(INFO_HEIGHT),
      .CEIL_Y(CEIL_Y),
      .BRICK_WIDTH(BRICK_WIDTH),
      .BRICK_HEIGHT(BRICK_HEIGHT),
      .BRICK_GAP_X(BRICK_GAP_X),
      .BRICK_GAP_Y(BRICK_GAP_Y),
      .NUM_ROWS(NUM_ROWS),
      .NUM_COLS(NUM_COLS),
      .FIRST_ROW_Y(FIRST_ROW_Y),
      .LAST_ROW_Y(LAST_ROW_Y),
      .FIRST_COL_X(FIRST_COL_X)
  ) pixel_mux (
      .vga_clk(vga_clk),
      .pixel_x(pixel_x),
      .pixel_y(pixel_y),
      .active(vga_active),
      .ball_pos_x(ball_pos_x),
      .ball_pos_y(ball_pos_y),
      .paddle_pos_x(paddle_pos_x),
      .state(state),
      .brick_alive(brick_alive),
      .lives(lives),
      .score(score),
      .r(r),
      .g(g),
      .b(b)
  );



endmodule
