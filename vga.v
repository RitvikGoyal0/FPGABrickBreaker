module vga (
    input vga_clk,

    output wire       hsync,
    output wire       vsync,
    output reg        frame_tick,
    output wire [9:0] pixel_x,
    output wire [8:0] pixel_y,
    output wire       active
);

  wire       enable_v_counter;
  wire [9:0] h_count_value;
  wire [9:0] v_count_value;

  horizontal_counter vga_horiz (
      .vga_clk(vga_clk),
      .enable_v_counter(enable_v_counter),
      .h_count_value(h_count_value)
  );

  vertical_counter vga_vert (
      .vga_clk(vga_clk),
      .enable_v_counter(enable_v_counter),
      .v_count_value(v_count_value)
  );

  //Outputs
  assign hsync = (h_count_value < 96) ? 1'b1 : 1'b0;
  assign vsync = (v_count_value < 2) ? 1'b1 : 1'b0;

  reg vsync_prev;

  always @(posedge vga_clk) begin
      vsync_prev <= vsync;
      frame_tick <= (vsync && !vsync_prev);  // pulses exactly one vga_clk cycle on vsync's rising edge
  end

  assign active = (h_count_value < 784 && h_count_value > 143 && v_count_value < 515 && v_count_value>34);
  assign pixel_x = active ? h_count_value - 144 : 10'd0;
  assign pixel_y = active ? v_count_value - 35 : 10'd0;

endmodule
