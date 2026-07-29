module vertical_counter (

    input enable_v_counter = 0,
    input vga_clk,

    output reg [9:0] v_count_value = 0
);

  always @(posedge vga_clk) begin
    if (enable_v_counter == 1'b1) begin
      if (v_count_value < 524) begin
        v_count_value <= v_count_value + 1;
      end else begin
        v_count_value <= 0;
      end
    end
  end

endmodule
