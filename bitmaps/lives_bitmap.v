module lives_bitmap #(
    parameter INFO_HEIGHT = 6'd50
) (
    input       vga_clk,
    input [9:0] pixel_x,
    input [8:0] pixel_y,
    input [1:0] lives,

    output heart_pixel_lit
);

  localparam HEART_SCALE = 4;
  localparam HEART_SIZE = 8 * HEART_SCALE;
  localparam HEART_GAP = 6;
  localparam HEART_MARGIN = 10;
  localparam HEART_Y = (INFO_HEIGHT - HEART_SIZE) / 2;

  //Right-aligned heart x-values (0 - rightmost)
  localparam HEART0_X = HEART_MARGIN;
  localparam HEART1_X = HEART0_X + HEART_GAP + HEART_SIZE;
  localparam HEART2_X = HEART1_X + HEART_GAP + HEART_SIZE;

  wire in_heart0 = (lives > 0) && (pixel_x >= HEART0_X) && (pixel_x < HEART0_X + HEART_SIZE) && (pixel_y >= HEART_Y)  && (pixel_y < HEART_Y + HEART_SIZE);
  wire in_heart1 = (lives > 1) && (pixel_x >= HEART1_X) && (pixel_x < HEART1_X + HEART_SIZE) && (pixel_y >= HEART_Y)  && (pixel_y < HEART_Y + HEART_SIZE);
  wire in_heart2 = (lives > 2) && (pixel_x >= HEART2_X) && (pixel_x < HEART2_X + HEART_SIZE) && (pixel_y >= HEART_Y)  && (pixel_y < HEART_Y + HEART_SIZE);

  wire in_any_heart = in_heart0 || in_heart1 || in_heart2;

  wire [9:0] heart_local_x = in_heart0 ? (pixel_x - HEART0_X) : in_heart1 ? (pixel_x - HEART1_X) : (pixel_x - HEART2_X);
  wire [8:0] heart_local_y = pixel_y - HEART_Y;

  wire [2:0] heart_row = heart_local_y / HEART_SCALE;
  wire [2:0] heart_col = heart_local_x / HEART_SCALE;
  wire [7:0] heart_row_bits;

  chars_rom heart_font (
      .vga_clk(vga_clk),
      .char    (4'd10),          //heart glyph
      .row     (heart_row),
      .row_bits(heart_row_bits)
  );

  assign heart_pixel_lit = in_any_heart && heart_row_bits[heart_col];

endmodule
