module brick_collision_simplified #(
    parameter BRICK_WIDTH  = 32,
    parameter BRICK_HEIGHT = 16,
    parameter BRICK_GAP_X  = 0,
    parameter BRICK_GAP_Y  = 0,
    parameter NUM_ROWS     = 4,
    parameter NUM_COLS     = 20,
    parameter signed FIRST_ROW_Y  = 100,
    parameter signed LAST_ROW_Y   = (100 + 4 * 16),
    parameter signed FIRST_COL_X  = 0
) (
    // Single (x, y) point to test against the brick grid. This block is
    // shared/time-multiplexed by the caller: it is fed the "x-edge" point
    // on one cycle and the "y-edge" point on the next, rather than having
    // two parallel copies of this arithmetic as before.
    input signed [10:0] px,
    input signed [ 9:0] py,
    input        [79:0] brick_alive,

    output hit,
    output [ 7:0] index
);

  wire in_brick_area = py >= FIRST_ROW_Y && py <= LAST_ROW_Y;

  // Shift by 4 because pitch is (BRICK_HEIGHT + BRICK_GAP_Y) == 16 (power of 2)
  wire [3:0] row_raw = (py - FIRST_ROW_Y) >> 4;
  wire [3:0] row = in_brick_area ? ((row_raw >= NUM_ROWS) ? NUM_ROWS - 1 : row_raw) : 4'd0;
  // Shift by 5 because pitch is (BRICK_WIDTH + BRICK_GAP_X) == 32 (power of 2)
  wire [4:0] col_raw = (px - FIRST_COL_X) >> 5;
  wire [4:0] col = in_brick_area ? ((col_raw >= NUM_COLS) ? NUM_COLS[4:0] - 1 : col_raw) : 5'd0;

  wire signed [9:0]  brick_top_y  = FIRST_ROW_Y + (row * (BRICK_HEIGHT + BRICK_GAP_Y));
  wire signed [10:0] brick_left_x = FIRST_COL_X + (col * (BRICK_WIDTH + BRICK_GAP_X));

  wire in_box = in_brick_area &&
                (py >= brick_top_y) && (py <= brick_top_y + BRICK_HEIGHT) &&
                (px >= brick_left_x) && (px <= brick_left_x + BRICK_WIDTH);

  assign index = row * NUM_COLS + col;
  assign hit   = in_box && brick_alive[index];

endmodule