module brick_collision #(
    parameter BALL_RADIUS  = 6,
    parameter BRICK_WIDTH  = 32,
    parameter BRICK_HEIGHT = 12,
    parameter BRICK_GAP_X  = 6,
    parameter BRICK_GAP_Y  = 4,
    parameter NUM_ROWS     = 8,
    parameter NUM_COLS     = (640 + 6) / (32 + 6),
    parameter FIRST_ROW_Y  = 100,
    parameter LAST_ROW_Y   = (100 + 8 * 16),
    parameter FIRST_COL_X  = 0,
    parameter DIAG_DIST    = 4                      // 181/256 or about 1/sqrt(2)

) (
    input signed [ 10:0] ball_pos_x,
    input signed [  9:0] ball_pos_y,
    input signed [  4:0] ball_dx,
    input signed [  4:0] ball_dy,
    input        [79:0]  brick_alive,

    output reg               collided,
    output reg        [ 7:0] brick_index,
    output reg        [ 1:0] collision_side,        //0 for x, 1 for y, 2 for diagonal
    output reg signed [10:0] collision_wall_pos_x,
    output reg signed [10:0] collision_wall_pos_y,
    output reg signed [ 4:0] new_ball_dx,
    output reg signed [ 4:0] new_ball_dy
);


  wire signed [10:0] potent_pos_x = ball_pos_x + ball_dx;
  wire signed [9:0] potent_pos_y = ball_pos_y + ball_dy;

  //Checks the brick to the left or right
  wire [10:0] colliding_edge_x = ball_dx > 0 ? potent_pos_x + BALL_RADIUS : potent_pos_x - BALL_RADIUS;

  wire [3:0] row_x = (potent_pos_y - FIRST_ROW_Y) >> 4; //Shift by 4 bits because dividing by 16: (BRICK_HEIGHT + BRICK_GAP_Y)
  wire [4:0] col_x = (colliding_edge_x - FIRST_COL_X) / (BRICK_WIDTH + BRICK_GAP_X);

  wire [8:0] brick_top_x_y = FIRST_ROW_Y + (row_x * (BRICK_HEIGHT + BRICK_GAP_Y));
  wire [9:0] brick_left_x_x = FIRST_COL_X + (col_x * (BRICK_WIDTH + BRICK_GAP_X));

  //Checks the brick to the top or bottom
  wire [9:0]  colliding_edge_y = ball_dy > 0 ? potent_pos_y + BALL_RADIUS : potent_pos_y - BALL_RADIUS;

  wire [3:0] row_y = (colliding_edge_y - FIRST_ROW_Y) >> 4; //Shift by 4 bits because dividing by 16: (BRICK_HEIGHT + BRICK_GAP_Y)
  wire [4:0] col_y = (potent_pos_x - FIRST_COL_X) / (BRICK_WIDTH + BRICK_GAP_X);

  wire [8:0] brick_top_y_y = FIRST_ROW_Y + (row_y * (BRICK_HEIGHT + BRICK_GAP_Y));
  wire [9:0] brick_left_y_x = FIRST_COL_X + (col_y * (BRICK_WIDTH + BRICK_GAP_X));

  //Checks the brick to the diagonal
  // wire [10:0] colliding_edge_d_x = ball_dx > 0 ? potent_pos_x + DIAG_DIST : potent_pos_x   - DIAG_DIST;
  // wire [9:0] colliding_edge_d_y = ball_dy > 0 ? potent_pos_y + DIAG_DIST : potent_pos_y - DIAG_DIST;

  // wire [3:0] row_d = (colliding_edge_d_y - FIRST_ROW_Y) >> 4; //Shift by 4 bits because dividing by 16: (BRICK_HEIGHT + BRICK_GAP_Y)
  // wire [4:0] col_d = (colliding_edge_d_x - FIRST_COL_X) / (BRICK_WIDTH + BRICK_GAP_X);

  // wire [8:0] brick_top_d_y = FIRST_ROW_Y + (row_d * (BRICK_HEIGHT + BRICK_GAP_Y));
  // wire [9:0] brick_left_d_x = FIRST_COL_X + (col_d * (BRICK_WIDTH + BRICK_GAP_X));


  always @(*) begin
    //If no collision
    collided             = 1'b0;
    brick_index          = 8'd0;
    collision_side       = 2'b0;
    collision_wall_pos_x = 11'sd0;
    collision_wall_pos_y = 11'sd0;
    new_ball_dx          = ball_dx;
    new_ball_dy          = ball_dy;

    // if (brick_alive[row_d * NUM_COLS + col_d] && (colliding_edge_d_y >= brick_top_d_y) && (colliding_edge_d_y <= brick_top_d_y + BRICK_HEIGHT) && (colliding_edge_d_x >= brick_left_d_x) && (colliding_edge_d_x <= brick_left_d_x + BRICK_WIDTH)) begin
    //   //If collided diagonally
    //   collided             = 1'b1;
    //   brick_index          = row_d * NUM_COLS + col_d;
    //   collision_side       = 2'd2;
    //   collision_wall_pos_x = ball_dx > 0 ? brick_left_d_x : brick_left_d_x + BRICK_WIDTH;
    //   collision_wall_pos_y = ball_dy > 0 ? brick_top_d_y : brick_top_d_y + BRICK_HEIGHT;
    //   new_ball_dx          = -ball_dx;
    //   new_ball_dy          = -ball_dy;
    // end else 
    if(brick_alive[row_x * NUM_COLS + col_x] && (potent_pos_y >= brick_top_x_y) && (potent_pos_y <= brick_top_x_y + BRICK_HEIGHT) && (colliding_edge_x >= brick_left_x_x) && (colliding_edge_x <= brick_left_x_x + BRICK_WIDTH)) begin
      //If collided left or right
      collided             = 1'b1;
      brick_index          = row_x * NUM_COLS + col_x;
      collision_side       = 1'b0;
      collision_wall_pos_x = ball_dx > 0 ? brick_left_x_x : brick_left_x_x + BRICK_WIDTH;
      new_ball_dx          = -ball_dx;
      new_ball_dy          = ball_dy;
    end else if (brick_alive[row_y * NUM_COLS + col_y] && (colliding_edge_y >= brick_top_y_y) && (colliding_edge_y <= brick_top_y_y + BRICK_HEIGHT) && (potent_pos_x >= brick_left_y_x) && (potent_pos_x <= brick_left_y_x + BRICK_WIDTH)) begin
      //If collided top or bottom
      collided             = 1'b1;
      brick_index          = row_y * NUM_COLS + col_y;
      collision_side       = 1'b1;
      collision_wall_pos_y = ball_dy > 0 ? brick_top_y_y : brick_top_y_y + BRICK_HEIGHT;
      new_ball_dx          = ball_dx;
      new_ball_dy          = -ball_dy;
    end
  end

endmodule
