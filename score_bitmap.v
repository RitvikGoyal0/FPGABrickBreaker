module score_bitmap #(
    parameter INFO_HEIGHT = 6'd50
) (
    input [ 9:0] pixel_x,
    input [ 8:0] pixel_y,
    input [13:0] score,

    output score_pixel_lit
);

  localparam SCORE_SCALE = 4;
  localparam SCORE_SIZE = 8 * SCORE_SCALE;
  localparam SCORE_GAP = 6;
  localparam SCORE_MARGIN = 10;
  localparam SCORE_Y = (INFO_HEIGHT - SCORE_SIZE) / 2;

  //Right-aligned heart x-values (0-ones, 1-tens, 2-hunds, 3-thous)
  localparam SCORE0_X = 640 - SCORE_MARGIN - SCORE_SIZE;
  localparam SCORE1_X = SCORE0_X - SCORE_GAP - SCORE_SIZE;
  localparam SCORE2_X = SCORE1_X - SCORE_GAP - SCORE_SIZE;
  localparam SCORE3_X = SCORE2_X - SCORE_GAP - SCORE_SIZE;

  wire [3:0] thousands;
  wire [3:0] hundreds;
  wire [3:0] tens;
  wire [3:0] ones;

  bcd score_bcd (
      .binary(score),
      .thousands(thousands),
      .hundreds(hundreds),
      .tens(tens),
      .ones(ones)
  );

  wire in_score0 = (pixel_x >= SCORE0_X) && (pixel_x < SCORE0_X + SCORE_SIZE) && (pixel_y >= SCORE_Y)  && (pixel_y < SCORE_Y + SCORE_SIZE);
  wire in_score1 = (pixel_x >= SCORE1_X) && (pixel_x < SCORE1_X + SCORE_SIZE) && (pixel_y >= SCORE_Y)  && (pixel_y < SCORE_Y + SCORE_SIZE);
  wire in_score2 = (pixel_x >= SCORE2_X) && (pixel_x < SCORE2_X + SCORE_SIZE) && (pixel_y >= SCORE_Y)  && (pixel_y < SCORE_Y + SCORE_SIZE);
  wire in_score3 = (pixel_x >= SCORE3_X) && (pixel_x < SCORE3_X + SCORE_SIZE) && (pixel_y >= SCORE_Y)  && (pixel_y < SCORE_Y + SCORE_SIZE);

  wire in_any_score = in_score0 || in_score1 || in_score2 || in_score3;

  wire [9:0] score_local_x = in_score0 ? (pixel_x - SCORE0_X) : in_score1 ? (pixel_x - SCORE1_X) : in_score2 ? (pixel_x - SCORE2_X) : (pixel_x - SCORE3_X);
  wire [8:0] score_local_y = pixel_y - SCORE_Y;

  wire [2:0] score_row = score_local_y / SCORE_SCALE;
  wire [2:0] score_col = score_local_x / SCORE_SCALE;
  wire [7:0] score_row_bits;

  wire [3:0] score_char = in_score0 ? ones : in_score1 ? tens : in_score2 ? hundreds : thousands;

  chars_rom score_font (
      .char    (score_char),     //score glyph
      .row     (score_row),
      .row_bits(score_row_bits)
  );

  assign score_pixel_lit = in_any_score && score_row_bits[score_col];

endmodule
