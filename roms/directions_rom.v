module directions_rom (
    input        vga_clk,
    input        r_en,
    input  [3:0] row,     // 0-7
    output reg [63:0] row_bits
);

  reg [63:0] rom[0:7];

  initial begin
    rom[0] = {8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};
    rom[1] = {8'h79, 8'he7, 8'hcf, 8'h3c, 8'h1e, 8'hf9, 8'hcf, 8'h3e};
    rom[2] = {8'h45, 8'h14, 8'h10, 8'h40, 8'h20, 8'h22, 8'h28, 8'h88};
    rom[3] = {8'h45, 8'h17, 8'h8e, 8'h38, 8'h1c, 8'h22, 8'h28, 8'h88};
    rom[4] = {8'h79, 8'he4, 8'h01, 8'h04, 8'h02, 8'h23, 8'hef, 8'h08};
    rom[5] = {8'h41, 8'h17, 8'hde, 8'h78, 8'h3c, 8'h22, 8'h28, 8'h88};
    rom[6] = {8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};
    rom[7] = {8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};
  end

  always @(posedge vga_clk)
    if (r_en == 1'b1) begin
      row_bits <= rom[row];
    end

endmodule
