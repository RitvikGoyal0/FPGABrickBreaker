module chars_rom (
    input        vga_clk,
    input  [3:0] char,    //0-9 and 10 for heart
    input  [2:0] row,     // 0-7
    output reg [7:0] row_bits // 8 bits per row
);

  reg [63:0] rom[0:10];

  initial begin
    rom[0]  = 64'h3c66666e76663c00;
    rom[1]  = 64'h7e1818181c181800;
    rom[2]  = 64'h7e060c3060663c00;
    rom[3]  = 64'h3c66603860663c00;
    rom[4]  = 64'h30307e3234383000;
    rom[5]  = 64'h3c6660603e067e00;
    rom[6]  = 64'h3c66663e06663c00;
    rom[7]  = 64'h1818183030667e00;
    rom[8]  = 64'h3c66663c66663c00;
    rom[9]  = 64'h3c66607c66663c00;
    rom[10] = 64'h10387cfefeee4400;
  end

  always @(posedge vga_clk)
    row_bits <= rom[char][(row*8+7)-:8];

endmodule
