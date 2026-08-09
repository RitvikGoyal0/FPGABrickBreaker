module mux #(
    //States
    parameter STATE_IDLE  = 2'd0,
    parameter STATE_START = 2'd1,
    parameter STATE_PLAY  = 2'd2,
    parameter STATE_OVER  = 2'd3,

    //DEFAULT VALUES
    parameter BALL_RADIUS   = 3'd6,
    parameter signed PADDLE_WIDTH  = 6'd30,
    parameter PADDLE_HEIGHT = 5'd6,
    parameter PADDLE_POS_Y  = 9'd260,

    //INFO BAR
    parameter INFO_HEIGHT = 6'd50,
    parameter CEIL_Y      = INFO_HEIGHT + 5,

    parameter BRICK_WIDTH  = 32,
    parameter BRICK_HEIGHT = 12,
    parameter BRICK_GAP_X  = 6,
    parameter BRICK_GAP_Y  = 4,
    parameter NUM_ROWS     = 8,
    parameter NUM_COLS     = (640 + 6) / (32 + 6),
    parameter FIRST_ROW_Y  = 100,
    parameter LAST_ROW_Y   = (100 + 8 * 16),
    parameter FIRST_COL_X  = 0
) (
    input vga_clk,

    input [9:0] pixel_x,
    input [8:0] pixel_y,
    input       active,

    input signed [ 10:0] ball_pos_x,
    input signed [  9:0] ball_pos_y,
    input signed [ 10:0] paddle_pos_x,
    input        [  1:0] state,
    input        [79:0]  brick_alive,

    input [ 1:0] lives,
    // input [13:0] score,

    output reg [1:0] r,
    output reg [1:0] g,
    output reg [1:0] b
);

  //COLORS OF EACH GAME PIECE
  localparam TITLE_COLOR_G = 2'b11;
  localparam TITLE_COLOR_R = 2'b11;
  localparam TITLE_COLOR_B = 2'b11;

  localparam BALL_COLOR_R = 2'b11;
  localparam BALL_COLOR_G = 2'b11;
  localparam BALL_COLOR_B = 2'b11;

  localparam PADDLE_COLOR_R = 2'b11;
  localparam PADDLE_COLOR_G = 2'b11;
  localparam PADDLE_COLOR_B = 2'b11;

  localparam BORDER_COLOR_R = 2'b11;
  localparam BORDER_COLOR_G = 2'b11;
  localparam BORDER_COLOR_B = 2'b11;

  localparam HEART_COLOR_R = 2'b11;
  localparam HEART_COLOR_G = 2'b11;
  localparam HEART_COLOR_B = 2'b11;

  localparam SCORE_COLOR_G = 2'b11;
  localparam SCORE_COLOR_R = 2'b11;
  localparam SCORE_COLOR_B = 2'b11;

  localparam BRICK_COLOR_G = 2'b11;
  localparam BRICK_COLOR_R = 2'b11;
  localparam BRICK_COLOR_B = 2'b11;

  localparam BKGRND_COLOR_R = 2'b00;
  localparam BKGRND_COLOR_G = 2'b00;
  localparam BKGRND_COLOR_B = 2'b00;


  //TITLE SCREEN BITMAP PLACEMENT (128x46, centered on a 640x480 screen)
  wire title_pixel_lit;

  title_bitmap title_bitmap0 (
      .vga_clk(vga_clk),
      .pixel_x(pixel_x),
      .pixel_y(pixel_y),
      .title_pixel_lit(title_pixel_lit)
  );

  //DIRECTIONS BITMAP PLACEMENT (128x46, centered on a 640x480 screen)
  wire directions_pixel_lit;

  directions_bitmap directions_bitmap0 (
      .vga_clk(vga_clk),
      .pixel_x(pixel_x),
      .pixel_y(pixel_y),
      .directions_pixel_lit(directions_pixel_lit)
  );


  // //LIVES DISPLAY top-left
  wire heart_pixel_lit;

  lives_bitmap #(
      .INFO_HEIGHT(INFO_HEIGHT)
  ) lives_bitmap0 (
      .vga_clk(vga_clk),
      .pixel_x(pixel_x),
      .pixel_y(pixel_y),
      .lives(lives),
      .heart_pixel_lit(heart_pixel_lit)
  );

  // //SCORE DISPLAY top-right
  wire score_pixel_lit;

  score_bitmap #(
      .INFO_HEIGHT(INFO_HEIGHT)
  ) score_bitmap0 (
      .vga_clk(vga_clk),
      .pixel_x(pixel_x),
      .pixel_y(pixel_y),
      .score(score),
      .score_pixel_lit(score_pixel_lit)
  );

  //BRICKS DISPLAY
  wire brick_pixel_lit;

  brick_bitmap #(
      .BRICK_WIDTH(BRICK_WIDTH),
      .BRICK_HEIGHT(BRICK_HEIGHT),
      .BRICK_GAP_X(BRICK_GAP_X),
      .BRICK_GAP_Y(BRICK_GAP_Y),
      .NUM_ROWS(NUM_ROWS),
      .NUM_COLS(NUM_COLS),
      .FIRST_ROW_Y(FIRST_ROW_Y),
      .LAST_ROW_Y(LAST_ROW_Y),
      .FIRST_COL_X(FIRST_COL_X)
  ) brick_bitmap0 (
      .pixel_x(pixel_x),
      .pixel_y(pixel_y),
      .brick_alive(brick_alive),
      .brick_pixel_lit(brick_pixel_lit)
  );

  //Ball Distance
  reg signed [11:0] dx, dy;
  //reg [23:0] dist_sq;

  always @(*) begin
    dx = pixel_x - ball_pos_x;
    dy = pixel_y - ball_pos_y;
    //dist_sq = dx * dx + dy * dy;
  end


  always @(posedge vga_clk) begin
    //On reset return to IDLE
    case (state)

      //IDLE - Waiting for go button - Screen shows "Press start" - 
      STATE_IDLE: begin
        if (active) begin
          if (title_pixel_lit) begin
            r <= TITLE_COLOR_R;
            g <= TITLE_COLOR_G;
            b <= TITLE_COLOR_B;
          end else begin
            r <= BKGRND_COLOR_R;
            g <= BKGRND_COLOR_G;
            b <= BKGRND_COLOR_B;
          end
        end else begin
          r <= 2'b00;
          g <= 2'b00;
          b <= 2'b00;
        end
      end

      //GAME START - Waiting for go button to be pressed - 
      STATE_START: begin
        if (active) begin
          if ($unsigned(dx) <= (BALL_RADIUS) && $unsigned(dy) <= (BALL_RADIUS)) begin  //BALL
            r <= BALL_COLOR_R;
            g <= BALL_COLOR_G;
            b <= BALL_COLOR_B;
          end else if (pixel_x >= paddle_pos_x - PADDLE_WIDTH && pixel_x <= paddle_pos_x + PADDLE_WIDTH && pixel_y >= PADDLE_POS_Y && pixel_y <= PADDLE_POS_Y + PADDLE_HEIGHT) begin // Paddle
            r <= PADDLE_COLOR_R;
            g <= PADDLE_COLOR_G;
            b <= PADDLE_COLOR_B;
          end else if (pixel_y >= INFO_HEIGHT && pixel_y <= CEIL_Y) begin  //Border
            r <= BORDER_COLOR_R;
            g <= BORDER_COLOR_G;
            b <= BORDER_COLOR_B;
          end 
          else if (heart_pixel_lit) begin
            r <= HEART_COLOR_R;
            g <= HEART_COLOR_G;
            b <= HEART_COLOR_B;
          end else if (score_pixel_lit) begin
            r <= SCORE_COLOR_R;
            g <= SCORE_COLOR_G;
            b <= SCORE_COLOR_B;
          end else if (brick_pixel_lit) begin
            r <= BRICK_COLOR_R;
            g <= BRICK_COLOR_G;
            b <= BRICK_COLOR_B;
          end else if (directions_pixel_lit) begin
            r <= TITLE_COLOR_R;
            g <= TITLE_COLOR_G;
            b <= TITLE_COLOR_B;
          end 
          else begin
            r <= BKGRND_COLOR_R;
            g <= BKGRND_COLOR_G;
            b <= BKGRND_COLOR_B;
          end
        end else begin
          r <= 2'b00;
          g <= 2'b00;
          b <= 2'b00;
        end
      end

      //GAME PLAY - Waiting for ball to hit the bottom - Manages ball and paddle and brick interactions 
      //If lives remain - back to GAME START
      //If lives out go to GAME OVER
      STATE_PLAY: begin
        if (active) begin
          if ($unsigned(dx) <= (BALL_RADIUS) && $unsigned(dy) <= (BALL_RADIUS)) begin
            r <= BALL_COLOR_R;
            g <= BALL_COLOR_G;
            b <= BALL_COLOR_B;
          end else if (pixel_x >= paddle_pos_x - PADDLE_WIDTH && pixel_x <= paddle_pos_x + PADDLE_WIDTH && pixel_y >= PADDLE_POS_Y && pixel_y <= PADDLE_POS_Y + PADDLE_HEIGHT) begin
            r <= PADDLE_COLOR_R;
            g <= PADDLE_COLOR_G;
            b <= PADDLE_COLOR_B;
          end else if (pixel_y >= INFO_HEIGHT && pixel_y <= CEIL_Y) begin  //Border
            r <= BORDER_COLOR_R;
            g <= BORDER_COLOR_G;
            b <= BORDER_COLOR_B;
          end 
          else if (heart_pixel_lit) begin
            r <= HEART_COLOR_R;
            g <= HEART_COLOR_G;
            b <= HEART_COLOR_B;
          end else if (score_pixel_lit) begin
            r <= SCORE_COLOR_R;
            g <= SCORE_COLOR_G;
            b <= SCORE_COLOR_B;
          end else if (brick_pixel_lit) begin
            r <= BRICK_COLOR_R;
            g <= BRICK_COLOR_G;
            b <= BRICK_COLOR_B;
          end else begin
            r <= BKGRND_COLOR_R;
            g <= BKGRND_COLOR_G;
            b <= BKGRND_COLOR_B;
          end
        end else begin
          r <= 2'b00;
          g <= 2'b00;
          b <= 2'b00;
        end

      end

      //GAME OVER - Show game over for 5 sec and then back to IDLE
      STATE_OVER: begin

      end

      default: begin
        r <= 2'b00;
        g <= 2'b00;
        b <= 2'b00;
      end
    endcase

  end



  //Check whether pixel is within ball and display white
  //Check whether pixel is in paddle and display white
  //Check whether

endmodule
