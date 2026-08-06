module title_bitmap (
    input       vga_clk,
    input       r_en,
    input [9:0] pixel_x,
    input [8:0] pixel_y,

    output title_pixel_lit
);

  localparam SCALE = 3;  //Can change to a multiple of 2 to save logic cells later if needed
  localparam TITLE_W = 128 * SCALE;
  localparam TITLE_H = 46 * SCALE;
  localparam TITLE_X = (640 - TITLE_W) / 2;
  localparam TITLE_Y = (480 - TITLE_H) / 2;

  wire in_title_box = (pixel_x >= TITLE_X) && (pixel_x < TITLE_X + TITLE_W) && (pixel_y >= TITLE_Y) && (pixel_y < TITLE_Y + TITLE_H);

  wire [5:0] title_row = (pixel_y - TITLE_Y) / SCALE;
  wire [6:0] title_col = (pixel_x - TITLE_X) / SCALE;
  wire [127:0] title_row_bits;


  title_rom title_bitmap (
      .vga_clk(vga_clk),
      .r_en(r_en),
      .row(title_row),
      .row_bits(title_row_bits)
  );

  assign title_pixel_lit = in_title_box && title_row_bits[127-title_col];


endmodule
