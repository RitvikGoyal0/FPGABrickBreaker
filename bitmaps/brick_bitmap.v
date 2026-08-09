module brick_bitmap #(
    parameter BRICK_WIDTH  = 32,
    parameter BRICK_HEIGHT = 16,
    parameter BRICK_GAP_X  = 0,
    parameter BRICK_GAP_Y  = 0,
    parameter NUM_ROWS     = 4,
    parameter NUM_COLS     = 20,
    parameter FIRST_ROW_Y  = 100,
    parameter LAST_ROW_Y   = (100 + 4 * 16)-1,
    parameter FIRST_COL_X  = 0

) (
    input [  9:0] pixel_x,
    input [  8:0] pixel_y,
    input [79:0]  brick_alive,

    output brick_pixel_lit
);

  wire in_brick_area = pixel_y >= FIRST_ROW_Y && pixel_y <= LAST_ROW_Y;

  wire [3:0] row = in_brick_area ? (pixel_y - FIRST_ROW_Y) >> 4 : 0; //Shift by 4 bits because dividing by 16: (BRICK_HEIGHT + BRICK_GAP_Y)
  wire [4:0] col = in_brick_area ? (pixel_x - FIRST_COL_X) >> 5 : 0;

  wire [8:0] brick_top_y = FIRST_ROW_Y + (row * (BRICK_HEIGHT + BRICK_GAP_Y));
  wire [9:0] brick_left_x = FIRST_COL_X + (col * (BRICK_WIDTH + BRICK_GAP_X));

  wire in_brick = in_brick_area && (pixel_y >= brick_top_y) && (pixel_y <= brick_top_y + BRICK_HEIGHT) && (pixel_x >= brick_left_x) && (pixel_x <= brick_left_x + BRICK_WIDTH);

  assign brick_pixel_lit = in_brick && brick_alive[row*NUM_COLS+col];

endmodule
