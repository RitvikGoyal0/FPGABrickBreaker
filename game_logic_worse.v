module game_logic_worse #(
    //States
    parameter STATE_IDLE  = 2'd0,
    parameter STATE_START = 2'd1,
    parameter STATE_PLAY  = 2'd2,
    parameter STATE_OVER  = 2'd3,

    //DEFAULT VALUES
    parameter signed BALL_START_X   = 11'sd320,
    parameter signed BALL_START_Y   = 10'sd240,
    parameter signed BALL_START_DX  = 4'sd3,
    parameter signed BALL_START_DY  = 4'sd3,
    parameter signed PADDLE_START_X = 11'sd320,
    parameter signed PADDLE_POS_Y   = 10'sd260,
    parameter        START_LIVES    = 2'd3,
    parameter signed BALL_RADIUS    = 3'sd4,
    parameter signed PADDLE_WIDTH   = 6'sd30,
    parameter signed PADDLE_HEIGHT  = 5'sd6,
    parameter        PADDLE_DX      = 4'd3,

    //Screen values
    parameter signed INFO_HEIGHT = 6'd50,
    parameter signed CEIL_Y      = INFO_HEIGHT + 5,

    //Brick Values
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
    input frame_tick,
    input btn_left,
    input btn_right,
    input btn_rst,
    input btn_go,

    output reg signed [ 10:0] ball_pos_x,
    output reg signed [  9:0] ball_pos_y,
    output reg signed [ 10:0] paddle_pos_x,
    output reg        [  1:0] state,
    output reg        [79:0]  brick_alive,

    //lives
    output reg [ 1:0] lives,
    output reg [13:0] score
);


  //Internal storage elements

  wire               collided;
  wire        [ 7:0] brick_index;
  wire        [ 1:0] collision_side;  //0 for x, 1 for y
  wire signed [10:0] collision_wall_pos_x;
  wire signed [10:0] collision_wall_pos_y;
  wire signed [ 4:0] new_ball_dx;
  wire signed [ 4:0] new_ball_dy;
  wire               score_increment;


  //Game Elements
  //ball
  reg signed  [ 4:0] ball_dx = BALL_START_DX;
  reg signed  [ 4:0] ball_dy = BALL_START_DY;


  wire signed [10:0] next_ball_pos_x = ball_pos_x + ball_dx;
  wire signed [9:0]  next_ball_pos_y = ball_pos_y + ball_dy;

  localparam DIAG_DIST = (BALL_RADIUS * 181) >> 8;  // 181/256 or about 1/sqrt(2)


  brick_collision #(
      .BALL_RADIUS(BALL_RADIUS),
      .BRICK_WIDTH(BRICK_WIDTH),
      .BRICK_HEIGHT(BRICK_HEIGHT),
      .BRICK_GAP_X(BRICK_GAP_X),
      .BRICK_GAP_Y(BRICK_GAP_Y),
      .NUM_ROWS(NUM_ROWS),
      .NUM_COLS(NUM_COLS),
      .FIRST_ROW_Y(FIRST_ROW_Y),
      .LAST_ROW_Y(LAST_ROW_Y),
      .FIRST_COL_X(FIRST_COL_X),
      .DIAG_DIST(DIAG_DIST)
  ) brick_collision0 (
      .ball_pos_x(ball_pos_x),
      .ball_pos_y(ball_pos_y),
      .ball_dx(ball_dx),
      .ball_dy(ball_dy),
      .brick_alive(brick_alive),
      .collided(collided),
      .brick_index(brick_index),
      .collision_side(collision_side),
      .collision_wall_pos_x(collision_wall_pos_x),
      .collision_wall_pos_y(collision_wall_pos_y),
      .new_ball_dx(new_ball_dx),
      .new_ball_dy(new_ball_dy)
  );

  //STATE MACHINE
  always @(posedge frame_tick) begin
    if (btn_rst == 1'b1) begin
      state        <= STATE_IDLE;
      //default values
      ball_pos_x   <= BALL_START_X;
      ball_pos_y   <= BALL_START_Y;
      paddle_pos_x <= PADDLE_START_X;
      lives        <= START_LIVES;
      score        <= 14'd0;
      brick_alive  <= {(136) {1'b1}};
    end

    //On reset return to IDLE
    case (state)

      //IDLE - Waiting for go button - Screen shows "Press start" - 
      STATE_IDLE: begin
        if (btn_rst == 1'b1) begin
          //default values
          ball_pos_x   <= BALL_START_X;
          ball_pos_y   <= BALL_START_Y;
          paddle_pos_x <= PADDLE_START_X;
          lives        <= START_LIVES;
          score        <= 14'd0;
          brick_alive  <= {(136) {1'b1}};
        end else if (btn_go == 1'b1) begin
          ball_pos_x   <= BALL_START_X;
          ball_pos_y   <= BALL_START_Y;
          paddle_pos_x <= PADDLE_START_X;
          lives        <= START_LIVES;
          score        <= 14'd0;
          ball_dx      <= BALL_START_DX;
          ball_dy      <= BALL_START_DY;
          state        <= STATE_START;
          brick_alive  <= {(80) {1'b1}};
        end
      end

      //GAME START - Waiting for go button to be pressed - 
      STATE_START: begin
        if (btn_go == 1'b1) begin
          state            <= STATE_PLAY;
          brick_alive[60] <= 1'b0;
          brick_alive[63] <= 1'b0;
          brick_alive[60] <= 1'b0;
        end
      end

      //GAME PLAY - Waiting for ball to hit the bottom - Manages ball and paddle and brick interactions 
      //If lives remain - back to GAME START
      //If lives out go to GAME OVER
      STATE_PLAY: begin
        //Move Paddle
        if (btn_left ^ btn_right) begin
          if (btn_left == 1'b1) begin
            if (paddle_pos_x - PADDLE_DX - PADDLE_WIDTH < 0) paddle_pos_x <= PADDLE_WIDTH;
            else paddle_pos_x <= paddle_pos_x - PADDLE_DX;
          end else begin
            if (paddle_pos_x + PADDLE_DX + PADDLE_WIDTH > 639) paddle_pos_x <= 639 - PADDLE_WIDTH;
            else paddle_pos_x <= paddle_pos_x + PADDLE_DX;
          end
        end


        //Check collisions with walls
        if (next_ball_pos_x - BALL_RADIUS < 0 && ball_dx < 0) begin  //LEFT WALL
          ball_dx <= -ball_dx;
        end else if (next_ball_pos_x + BALL_RADIUS >= 640 && ball_dx > 0) begin  //RIGHT WALL
          ball_dx <= -ball_dx;
        end else if (next_ball_pos_y - BALL_RADIUS <= CEIL_Y && ball_dy < 0) begin  //TOP WALL
          ball_dy <= -ball_dy;
        end else if (next_ball_pos_y + BALL_RADIUS >= 480 && ball_dy > 0) begin  //BOTTOM WALL
          //Ball dead
          lives <= lives - 1;
          if(lives - 1 > 0) begin
            state <= STATE_START;
          end else begin
            state <= STATE_OVER;
          end
        end else if (next_ball_pos_y + BALL_RADIUS >= PADDLE_POS_Y && next_ball_pos_y + BALL_RADIUS <= PADDLE_POS_Y + PADDLE_HEIGHT && next_ball_pos_x >= paddle_pos_x - PADDLE_WIDTH && next_ball_pos_x <= paddle_pos_x + PADDLE_WIDTH && ball_dy > 0) begin //PADDLE TOP
          ball_dy <= -ball_dy;
        end else if (collided) begin
          if (collision_side == 2'd0) begin  //LEFT OR RIGHT SIDE OF BRICK
            brick_alive[brick_index] <= 1'b0;
            ball_dx <= new_ball_dx;
          end else if (collision_side == 2'd1) begin  //TOP OR BOTTOM OF BRICK
            brick_alive[brick_index] <= 1'b0;
            ball_dy <= new_ball_dy;
          end else if (collision_side == 2'd2) begin  //CORNER OF BRICK
            brick_alive[brick_index] <= 1'b0;
            ball_dx <= new_ball_dx;
            ball_dy <= new_ball_dy;
          end
          score <= score + 1;
          if (score + 1 == 9999) state <= STATE_OVER;
        end else begin
          ball_pos_x <= next_ball_pos_x;
          ball_pos_y <= next_ball_pos_y;
        end


      end

      //GAME OVER - Show game over for 5 sec and then back to IDLE
      STATE_OVER: begin

      end

      default: state <= STATE_IDLE;
    endcase
  end

endmodule
