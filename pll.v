module pll #(

    //Parameters
    parameter FEEDBACK_PATH = "SIMPLE",
    parameter DIVR          = 4'b0000,
    parameter DIVF          = 7'b1000010,
    parameter DIVQ          = 3'b101,
    parameter FILTER_RANGE  = 3'b001

) (

    //Inputs
    input inp_clk,

    //Outputs
    output out_clk
);

  //Instantiate PLL (25.125MHz)
  SB_PLL40_CORE #(
      .FEEDBACK_PATH(FEEDBACK_PATH),
      .PLLOUT_SELECT("GENCLK"),
      .DIVR(DIVR),
      .DIVF(DIVF),
      .DIVQ(DIVQ),
      .FILTER_RANGE(FILTER_RANGE)
  ) pll (
      .REFERENCECLK(inp_clk),  //INPUT CLK
      .PLLOUTCORE  (out_clk),  //OUTPUT CLK
      .LOCK        (),         //LOCKED SIG
      .RESETB      (1'b1),     //ACTIVE LOW RESET
      .BYPASS      (1'b0)      //No bypass, use pll signal
  );

endmodule
