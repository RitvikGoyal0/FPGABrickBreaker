module main (

    //Inputs
    input       clk,
    input       btn_left,
    input       btn_right,
    input       btn_go,
    input       btn_rst,

    //Outputs
    output wire hsync,
    output wire vsync,
    output wire [1:0] r,
    output wire [1:0] g,
    output wire [1:0] b
);
    //STATE
    reg [1:0]       state;

    //VGA CLOCK GENERATOR
    wire vga_clk;

    //Create vga clock signal of 25.125 MHz
    // pll clk_multiplier (
    //     .inp_clk(clk),
    //     .out_clk(vga_clk)
    // );

    //Create Clock Multiplier here
    // clock_multiplier clk_multi (
    //     .inp_clk(clk),
    //     .out_clk(vga_clk)
    // );
    assign vga_clk = clk; //Simulation clock

    //VGA TIMING GENERATOR
    
    // wire hsync;
    // wire vsync;
    wire frame_tick;
    wire [9:0] pixel_x;
    wire [8:0] pixel_y;
    wire vga_active;

    vga vga_timer (
        .vga_clk(vga_clk),
        .hsync(hsync),
        .vsync(vsync),
        .frame_tick(frame_tick),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .active(vga_active)
    );

    //Game Piece Positions
    wire signed [10:0]   ball_pos_x;
    wire signed [9:0]    ball_pos_y;
    wire signed [10:0]   paddle_pos_x;
    wire signed [9:0]    paddle_pos_y;

    //GAME ELEMENT CONSTANTS
    //States
    localparam          STATE_IDLE      = 2'd0;
    localparam          STATE_START     = 2'd1;
    localparam          STATE_PLAY      = 2'd2;
    localparam          STATE_OVER      = 2'd3;

    //DEFAULT VALUES
    localparam          BALL_START_X      = 10'd320;
    localparam          BALL_START_Y      = 9'd240;
    localparam          BALL_START_DX     = 3;
    localparam          BALL_START_DY     = 3;
    localparam          PADDLE_START_X    = 10'd320;
    localparam          PADDLE_POS_Y      = 9'd260;
    localparam          START_LIVES       = 2'd3;
    localparam          BALL_RADIUS       = 3'd6;
    localparam          PADDLE_WIDTH      = 5'd30;
    localparam          PADDLE_HEIGHT     = 5'd6;
    localparam          PADDLE_DX         = 4'd3;

    //GAME LOGIC
    game_logic #(
        .STATE_IDLE(STATE_IDLE),
        .STATE_START(STATE_START),
        .STATE_PLAY(STATE_PLAY),
        .STATE_OVER(STATE_OVER),
        .BALL_START_X(BALL_START_X),
        .BALL_START_Y(BALL_START_Y),
        .BALL_START_DX(BALL_START_DX),
        .BALL_START_DY(BALL_START_DY),
        .PADDLE_START_X(PADDLE_START_X),
        .PADDLE_POS_Y(PADDLE_POS_Y),
        .START_LIVES(START_LIVES),
        .BALL_RADIUS(BALL_RADIUS),
        .PADDLE_WIDTH(PADDLE_WIDTH),
        .PADDLE_HEIGHT(PADDLE_HEIGHT),
        .PADDLE_DX(PADDLE_DX)
    )game(
        .frame_tick(frame_tick),
        .btn_go(btn_go),
        .btn_rst(btn_rst),
        .btn_left(btn_left),
        .btn_right(btn_right),
        .ball_pos_x(ball_pos_x),
        .ball_pos_y(ball_pos_y),
        .paddle_pos_x(paddle_pos_x),
        .state(state)
    );

    //PIXEL MUX
    mux #(
        .STATE_IDLE(STATE_IDLE),
        .STATE_START(STATE_START),
        .STATE_PLAY(STATE_PLAY),
        .STATE_OVER(STATE_OVER),
        .BALL_RADIUS(BALL_RADIUS),
        .PADDLE_WIDTH(PADDLE_WIDTH),
        .PADDLE_HEIGHT(PADDLE_HEIGHT),
        .PADDLE_POS_Y(PADDLE_POS_Y)
    )pixel_mux(
        .vga_clk(vga_clk),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .active(vga_active),
        .ball_pos_x(ball_pos_x),
        .ball_pos_y(ball_pos_y),
        .paddle_pos_x(paddle_pos_x),
        .state(state),
        .r(r),
        .g(g),
        .b(b)
    );



endmodule