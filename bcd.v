module bcd (
    input [13:0] binary,

    output reg [3:0] ones,
    output reg [3:0] tens,
    output reg [3:0] hundreds,
    output reg [3:0] thousands
);



  integer i;
  reg [29:0] shift;  // [29:14]=decimal [13:0]=binary

  always @(*) begin
    shift = 30'd0;
    shift[13:0] = binary;

    for (i = 0; i < 14; i = i + 1) begin
      if (shift[17:14] >= 5) shift[17:14] = shift[17:14] + 3;  //ones
      if (shift[21:18] >= 5) shift[21:18] = shift[21:18] + 3;  //tens
      if (shift[25:22] >= 5) shift[25:22] = shift[25:22] + 3;  //hundreds
      if (shift[29:26] >= 5) shift[29:26] = shift[29:26] + 3;  //thousands

      shift = shift << 1;
    end

    thousands = shift[29:26];
    hundreds  = shift[25:22];
    tens      = shift[21:18];
    ones      = shift[17:14];
  end
endmodule
