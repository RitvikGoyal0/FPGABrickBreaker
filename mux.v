module mux#(
    //States
    parameter          STATE_IDLE,
    parameter          STATE_START,
    parameter          STATE_PLAY,
    parameter          STATE_OVER,

    //DEFAULT VALUES
    parameter          BALL_RADIUS,
    parameter          PADDLE_WIDTH,
    parameter          PADDLE_HEIGHT,
    parameter          PADDLE_POS_Y
)(
    input                 vga_clk,

    input       [9:0]     pixel_x,
    input       [8:0]     pixel_y,
    input                 active,
    
    input signed [10:0]   ball_pos_x,
    input signed [9:0]    ball_pos_y,
    input signed [10:0]   paddle_pos_x,
    input        [1:0]    state,

    output reg  [1:0]     r,
    output reg  [1:0]     g,
    output reg  [1:0]     b
);

    //COLORS OF EACH GAME PIECE
    localparam          BALL_COLOR_R = 2'b11;
    localparam          BALL_COLOR_G = 2'b00;
    localparam          BALL_COLOR_B = 2'b00;

    localparam          PADDLE_COLOR_R = 2'b00;
    localparam          PADDLE_COLOR_G = 2'b11;
    localparam          PADDLE_COLOR_B = 2'b00;

    localparam          BKGRND_COLOR_R = 2'b00;
    localparam          BKGRND_COLOR_G = 2'b00;
    localparam          BKGRND_COLOR_B = 2'b11;

    reg signed [11:0] dx, dy;
    reg [23:0] dist_sq;

    always @(*) begin
        dx = pixel_x - ball_pos_x;
        dy = pixel_y - ball_pos_y;
        dist_sq = dx*dx + dy*dy;
    end


    always @(posedge vga_clk) begin
        //On reset return to IDLE
        case (state)

            //IDLE - Waiting for go button - Screen shows "Press start" - 
            STATE_IDLE: begin
                
            end

            //GAME START - Waiting for go button to be pressed - 
            STATE_START: begin
                
            end
            
            //GAME PLAY - Waiting for ball to hit the bottom - Manages ball and paddle and brick interactions 
                //If lives remain - back to GAME START
                //If lives out go to GAME OVER
            STATE_PLAY: begin
                if(active)begin
                    if (dist_sq <= (BALL_RADIUS * BALL_RADIUS))begin
                        r <= BALL_COLOR_R;
                        g <= BALL_COLOR_G;
                        b <= BALL_COLOR_B;
                    end else if (pixel_x >= paddle_pos_x - PADDLE_WIDTH && pixel_x <= paddle_pos_x + PADDLE_WIDTH && pixel_y >= PADDLE_POS_Y && pixel_y <= PADDLE_POS_Y + PADDLE_HEIGHT) begin
                        r <= PADDLE_COLOR_R;
                        g <= PADDLE_COLOR_G;
                        b <= PADDLE_COLOR_B;
                    end else begin
                        r <= BKGRND_COLOR_R;
                        g <= BKGRND_COLOR_G;
                        b <= BKGRND_COLOR_B;
                    end
                end else begin
                    r <= 2'b00;
                    g <= 2'b00;
                    b <= 2'b00;
                end
                
            end
            
            //GAME OVER - Show game over for 5 sec and then back to IDLE
            STATE_OVER: begin
                
            end

            default: ;
        endcase

    end

    //Check whether pixel is within ball and display white
    //Check whether pixel is in paddle and display white
    //Check whether

endmodule