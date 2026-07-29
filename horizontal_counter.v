module horizontal_counter (
    input            vga_clk,
    output reg       enable_v_counter = 0,
    output reg [9:0] h_count_value = 0
);


  always @(posedge vga_clk) begin
    if (h_count_value < 799) begin
      h_count_value <= h_count_value + 1;
      enable_v_counter <= 0;
    end else begin
      h_count_value <= 0;
      enable_v_counter <= 1;
    end
  end


endmodule
