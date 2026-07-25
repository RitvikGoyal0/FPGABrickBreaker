module game_logic#(
    //States
    parameter          STATE_IDLE,
    parameter          STATE_START,
    parameter          STATE_PLAY,
    parameter          STATE_OVER,

    //DEFAULT VALUES
    parameter          BALL_START_X,
    parameter          BALL_START_Y,
    parameter          BALL_START_DX,
    parameter          BALL_START_DY,
    parameter          PADDLE_START_X,
    parameter          PADDLE_POS_Y,
    parameter          START_LIVES,
    parameter          BALL_RADIUS,
    parameter          PADDLE_WIDTH,
    parameter          PADDLE_HEIGHT,
    parameter          PADDLE_DX
)(
    input           frame_tick,
    input           btn_left,
    input           btn_right,
    input           btn_rst,
    input           btn_go,
    
    output reg signed [10:0]   ball_pos_x,
    output reg signed [9:0]    ball_pos_y,
    output reg signed [10:0]   paddle_pos_x,
    output reg        [1:0]    state
);
   

    //Internal storage elements


    //Game Elements
    //ball
    reg signed  [3:0]   ball_dx         = BALL_START_DX;
    reg signed  [3:0]   ball_dy         = BALL_START_DY;

    //lives
    reg [1:0]           lives           = START_LIVES;

    //STATE MACHINE
    always @ (posedge frame_tick) begin
        if(btn_rst == 1'b1) begin
            state <= STATE_IDLE;
            //default values
            ball_pos_x      <= BALL_START_X;
            ball_pos_y      <= BALL_START_Y;
            paddle_pos_x    <= PADDLE_START_X;
            lives           <= START_LIVES;
        end

        //On reset return to IDLE
        case (state)

            //IDLE - Waiting for go button - Screen shows "Press start" - 
            STATE_IDLE: begin
                if(btn_rst == 1'b1) begin
                    //default values
                    ball_pos_x      <= BALL_START_X;
                    ball_pos_y      <= BALL_START_Y;
                    paddle_pos_x    <= PADDLE_START_X;
                    lives           <= START_LIVES;
                end else if(btn_go == 1'b1) begin
                    ball_pos_x      <= BALL_START_X;
                    ball_pos_y      <= BALL_START_Y;
                    paddle_pos_x    <= PADDLE_START_X;
                    lives           <= START_LIVES;
                    ball_dx         <= BALL_START_DX;
                    ball_dy         <= BALL_START_DY;
                    state           <= STATE_START;
                end
            end

            //GAME START - Waiting for go button to be pressed - 
            STATE_START: begin
                if(btn_go == 1'b1) begin
                    state           <= STATE_PLAY;
                end
            end
            
            //GAME PLAY - Waiting for ball to hit the bottom - Manages ball and paddle and brick interactions 
                //If lives remain - back to GAME START
                //If lives out go to GAME OVER
            STATE_PLAY: begin

                //Move Paddle
                if(btn_left ^ btn_right)begin
                    if(btn_left == 1'b1)begin
                        if (paddle_pos_x - PADDLE_DX - PADDLE_WIDTH < 0) paddle_pos_x <= PADDLE_WIDTH;
                        else paddle_pos_x <= paddle_pos_x - PADDLE_DX;
                    end else begin
                        if (paddle_pos_x + PADDLE_DX + PADDLE_WIDTH > 639) paddle_pos_x <= 639-PADDLE_WIDTH;
                        else paddle_pos_x <= paddle_pos_x + PADDLE_DX;
                    end
                end


                //Check collisions with walls
                if (ball_pos_x + ball_dx - BALL_RADIUS < 0 && ball_dx < 0) begin //LEFT WALL
                    ball_pos_x <= -(ball_pos_x + ball_dx);
                    ball_dx <= -ball_dx;
                end else if (ball_pos_x + ball_dx + BALL_RADIUS >= 640 && ball_dx > 0) begin //RIGHT WALL
                    ball_pos_x <= -((ball_pos_x + ball_dx + BALL_RADIUS) - 639) + 639 - BALL_RADIUS;
                    ball_dx <= -ball_dx;
                end else ball_pos_x <= ball_pos_x + ball_dx;

                if (ball_pos_y + ball_dy - BALL_RADIUS < 0 && ball_dy < 0) begin   //TOP WALL
                    ball_pos_y <= -(ball_pos_y + ball_dy); 
                    ball_dy <= -ball_dy;
                end else if (ball_pos_y + ball_dy + BALL_RADIUS >= 480  && ball_dy > 0) begin //BOTTOM WALL
                    //Ball dead
                    lives <= lives - 1;
                    state <= STATE_START;
                end else if (ball_pos_y + ball_dy + BALL_RADIUS >= PADDLE_POS_Y && ball_pos_y + ball_dy + BALL_RADIUS <= PADDLE_POS_Y + PADDLE_HEIGHT && ball_pos_x + ball_dx >= paddle_pos_x - PADDLE_WIDTH && ball_pos_x + ball_dx <= paddle_pos_x + PADDLE_WIDTH && ball_dy > 0) begin
                    ball_pos_y <= -((ball_pos_y + ball_dy + BALL_RADIUS) - PADDLE_POS_Y) - BALL_RADIUS + PADDLE_POS_Y;
                    ball_dy <= -ball_dy;    
                end else ball_pos_y <= ball_pos_y + ball_dy;
            end
            
            //GAME OVER - Show game over for 5 sec and then back to IDLE
            STATE_OVER: begin
            end

            default: state <= STATE_IDLE;
        endcase
    end

endmodule