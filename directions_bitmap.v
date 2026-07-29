module directions_bitmap (
    input [9:0] pixel_x,
    input [8:0] pixel_y,

    output directions_pixel_lit
);

  localparam SCALE = 4;  //Can change to a multiple of 2 to save logic cells later if needed
  localparam DIRECTIONS_W = 64 * SCALE;
  localparam DIRECTIONS_H = 8 * SCALE;
  localparam DIRECTIONS_X = (640 - DIRECTIONS_W) / 2;
  localparam DIRECTIONS_Y = (480 - DIRECTIONS_H) / 2;

  wire in_directions_box = (pixel_x >= DIRECTIONS_X) && (pixel_x < DIRECTIONS_X + DIRECTIONS_W) && (pixel_y >= DIRECTIONS_Y) && (pixel_y < DIRECTIONS_Y + DIRECTIONS_H);

  wire [3:0] directions_row = (pixel_y - DIRECTIONS_Y) / SCALE;
  wire [5:0] directions_col = (pixel_x - DIRECTIONS_X) / SCALE;
  wire [63:0] directions_row_bits;


  directions_rom directions_bitmap (
      .row(directions_row),
      .row_bits(directions_row_bits)
  );

  assign directions_pixel_lit = in_directions_box && directions_row_bits[63-directions_col];


endmodule
