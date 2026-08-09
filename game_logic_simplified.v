module game_logic_simplified #(
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
    parameter signed PADDLE_DX      = 4'd3,

    //Screen values
    parameter signed INFO_HEIGHT = 6'd50,
    parameter signed CEIL_Y      = INFO_HEIGHT + 5,

    //Brick Values
    parameter BRICK_WIDTH  = 32,
    parameter BRICK_HEIGHT = 16,
    parameter BRICK_GAP_X  = 0,
    parameter BRICK_GAP_Y  = 0,
    parameter NUM_ROWS     = 4,
    parameter NUM_COLS     = 20,
    parameter FIRST_ROW_Y  = 100,
    parameter LAST_ROW_Y   = (100 + 4 * 16),
    parameter FIRST_COL_X  = 0
) (
    input vga_clk,     // NEW: sequencer now runs on the free-running pixel
                       // clock instead of gating everything off frame_tick
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
    // output reg [13:0] score
);

  //Game Elements
  //ball
  reg signed [ 4:0] ball_dx = BALL_START_DX;
  reg signed [ 4:0] ball_dy = BALL_START_DY;

  wire signed [10:0] next_ball_pos_x = ball_pos_x + ball_dx;
  wire signed [9:0]  next_ball_pos_y = ball_pos_y + ball_dy;

  //Leading edge of the ball in its direction of travel, used for the brick
  //edge tests below.
  wire signed [10:0] colliding_edge_x = ball_dx > 0 ? next_ball_pos_x + BALL_RADIUS : next_ball_pos_x - BALL_RADIUS;
  wire signed [ 9:0] colliding_edge_y = ball_dy > 0 ? next_ball_pos_y + BALL_RADIUS : next_ball_pos_y - BALL_RADIUS;

  //---------------------------------------------------------------------
  // Brick collision is checked in two logical passes -- "did we clip a
  // brick from the left/right" and "did we clip a brick from top/bottom"
  // -- but both passes are really the same "is this point inside a live
  // brick" question. Previously this meant two full copies of the
  // row/col/boundary arithmetic running in parallel every frame. Since
  // this check only needs an answer once per frame_tick (~60Hz) but the
  // design runs on a ~25MHz pixel clock, there's no need to keep both
  // copies -- a single shared resolver is time-multiplexed across two
  // vga_clk cycles instead.
  //---------------------------------------------------------------------
  localparam SEQ_IDLE  = 2'd0;
  localparam SEQ_CHK_X = 2'd1;
  localparam SEQ_CHK_Y = 2'd2;
  localparam SEQ_APPLY = 2'd3;

  reg [1:0] seq_state = SEQ_IDLE;

  // Feed the shared resolver the x-edge point while checking for a
  // left/right hit, and the y-edge point while checking for a top/bottom
  // hit. Everything else just reuses potent_pos_x/y from above.
  wire signed [10:0] chk_px = (seq_state == SEQ_CHK_X) ? colliding_edge_x : next_ball_pos_x;
  wire signed [ 9:0] chk_py = (seq_state == SEQ_CHK_X) ? next_ball_pos_y  : colliding_edge_y;

  wire        brick_hit;
  wire [ 7:0] brick_hit_index;

  brick_collision_simplified #(
      .BRICK_WIDTH(BRICK_WIDTH),
      .BRICK_HEIGHT(BRICK_HEIGHT),
      .BRICK_GAP_X(BRICK_GAP_X),
      .BRICK_GAP_Y(BRICK_GAP_Y),
      .NUM_ROWS(NUM_ROWS),
      .NUM_COLS(NUM_COLS),
      .FIRST_ROW_Y(FIRST_ROW_Y),
      .LAST_ROW_Y(LAST_ROW_Y),
      .FIRST_COL_X(FIRST_COL_X)
  ) brick_collision0 (
      .px(chk_px),
      .py(chk_py),
      .brick_alive(brick_alive),
      .hit(brick_hit),
      .index(brick_hit_index)
  );

  // Latched results from each pass of the shared resolver
  reg        x_hit;
  reg [ 7:0] x_index;
  reg        y_hit;
  reg [ 7:0] y_index;

  //STATE MACHINE -- now clocked by vga_clk, gated by frame_tick, so the
  //sequencer above can spend a couple of extra vga_clk cycles resolving
  //brick collisions without needing frame_tick itself to stretch.
  always @(posedge vga_clk) begin
    if (btn_rst == 1'b1) begin
      state        <= STATE_IDLE;
      //default values
      ball_pos_x   <= BALL_START_X;
      ball_pos_y   <= BALL_START_Y;
      paddle_pos_x <= PADDLE_START_X;
      lives        <= START_LIVES;
    //   score        <= 14'd0;
      brick_alive  <= {(80) {1'b1}};
      seq_state    <= SEQ_IDLE;
      x_hit        <= 1'b0;
      y_hit        <= 1'b0;
      x_index      <= 8'd0;
      y_index      <= 8'd0;
    end else begin

      case (seq_state)

        //Waiting for the next frame tick. All non-collision state
        //transitions (IDLE/START/OVER) resolve immediately here, exactly
        //as before, since they don't need the shared resolver.
        SEQ_IDLE: begin
          if (frame_tick) begin
            case (state)

              //IDLE - Waiting for go button - Screen shows "Press start" -
              STATE_IDLE: begin
                if (btn_go == 1'b1) begin
                  ball_pos_x   <= BALL_START_X;
                  ball_pos_y   <= BALL_START_Y;
                  paddle_pos_x <= PADDLE_START_X;
                  lives        <= START_LIVES;
                //   score        <= 14'd0;
                  ball_dx      <= BALL_START_DX;
                  ball_dy      <= BALL_START_DY;
                  state        <= STATE_START;
                  brick_alive  <= {(80) {1'b1}};
                end
              end

              //GAME START - Waiting for go button to be pressed -
              STATE_START: begin
                if (btn_go == 1'b1) begin
                  state           <= STATE_PLAY;
                  ball_pos_x   <= BALL_START_X;
                  ball_pos_y   <= BALL_START_Y;
                  paddle_pos_x <= PADDLE_START_X;
                  lives        <= START_LIVES;
                  //   score        <= 14'd0;
                  seq_state    <= SEQ_IDLE;
                  x_hit        <= 1'b0;
                  y_hit        <= 1'b0;
                  x_index      <= 8'd0;
                  y_index      <= 8'd0;
                  ball_dx = BALL_START_DX;
                  ball_dy = BALL_START_DY;
                end
              end

              //GAME PLAY - Waiting for ball to hit the bottom - Manages
              //ball, paddle, and brick interactions
              STATE_PLAY: begin
                //Move Paddle
                if (btn_left ^ btn_right) begin
                  if (btn_left == 1'b1) begin
                    if (paddle_pos_x - PADDLE_DX - PADDLE_WIDTH <= 11'sd4) paddle_pos_x <= PADDLE_WIDTH+5;
                    else paddle_pos_x <= paddle_pos_x - PADDLE_DX;
                  end else begin
                    if (paddle_pos_x + PADDLE_DX + PADDLE_WIDTH > 11'sd639) paddle_pos_x <= 639 - PADDLE_WIDTH;
                    else paddle_pos_x <= paddle_pos_x + PADDLE_DX;
                  end
                end

                //Check cheap wall/paddle collisions immediately -- these
                //are plain comparisons, no row/col arithmetic, so there's
                //no benefit to time-multiplexing them.
                if (next_ball_pos_x <= 11'sd0 && ball_dx <= 0) begin  //LEFT WALL
                  ball_dx <= -ball_dx;
                end else if (next_ball_pos_x + BALL_RADIUS >= 11'sd640 && ball_dx > 0) begin  //RIGHT WALL
                  ball_dx <= -ball_dx;
                end else if (next_ball_pos_y - BALL_RADIUS <= CEIL_Y && ball_dy < 0) begin  //TOP WALL
                  ball_dy <= -ball_dy;
                end else if (next_ball_pos_y + BALL_RADIUS >= 480 && ball_dy > 0) begin  //BOTTOM WALL
                  //Ball dead
                  state <= STATE_START;
                //   lives <= lives - 1;
                //   if (lives - 1 > 0) begin
                //     state <= STATE_PLAY;
                //   end else begin
                //     state <= STATE_OVER;
                //   end
                end else if (next_ball_pos_y + BALL_RADIUS >= PADDLE_POS_Y && next_ball_pos_y + BALL_RADIUS <= PADDLE_POS_Y + PADDLE_HEIGHT && next_ball_pos_x >= paddle_pos_x - PADDLE_WIDTH && next_ball_pos_x <= paddle_pos_x + PADDLE_WIDTH && ball_dy > 0) begin  //PADDLE TOP
                  ball_dy <= -ball_dy;
                end else begin
                  //No cheap collision -- kick off the shared brick
                  //resolver. Ball position update is deferred to
                  //SEQ_APPLY once we know whether a brick was hit.
                  seq_state <= SEQ_CHK_X;
                end
              end

              //GAME OVER - Show game over for 5 sec and then back to IDLE
              STATE_OVER: begin
              end

              default: state <= STATE_IDLE;
            endcase
          end
        end

        //Pass 1: resolver is fed (colliding_edge_x, next_ball_pos_y) --
        //checks whether we've clipped a brick from the left or right.
        SEQ_CHK_X: begin
          x_hit     <= brick_hit;
          x_index   <= brick_hit_index;
          seq_state <= SEQ_CHK_Y;
        end

        //Pass 2: resolver is fed (next_ball_pos_x, colliding_edge_y) --
        //checks whether we've clipped a brick from the top or bottom.
        SEQ_CHK_Y: begin
          y_hit     <= brick_hit;
          y_index   <= brick_hit_index;
          seq_state <= SEQ_APPLY;
        end

        //Apply whichever brick result (if any) actually hit, preserving
        //the original left/right-takes-priority-over-top/bottom
        //ordering, then finally move the ball if nothing was hit at all.
        SEQ_APPLY: begin
          if (x_hit) begin
            brick_alive[x_index] <= 1'b0;
            ball_dx <= -ball_dx;
            // score   <= score + 1;
            // if (score + 1 == 9999) state <= STATE_OVER;
          end else if (y_hit) begin
            brick_alive[y_index] <= 1'b0;
            ball_dy <= -ball_dy;
            // score   <= score + 1;
            // if (score + 1 == 9999) state <= STATE_OVER;
          end else begin
            ball_pos_x <= next_ball_pos_x;
            ball_pos_y <= next_ball_pos_y;
          end
          seq_state <= SEQ_IDLE;
        end

        default: seq_state <= SEQ_IDLE;
      endcase
    end
  end

endmodule