module title_rom (
    input        vga_clk,
    input  [5:0] row,     // 0-45
    output reg [127:0] row_bits
);

  reg [127:0] rom[0:45];

  initial begin
    $readmemh("title_rom.mem", rom);
  end

  always @(posedge vga_clk)
    row_bits <= rom[row];


endmodule
