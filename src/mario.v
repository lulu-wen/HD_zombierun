`timescale 1ns / 1ps
module mario(
    input [9:0] pos_x_shift,
    input wire clk, reset,
    input wire up, down, left, right, 
    input wire game_over,
    input wire mario_on_ground, // 新增判斷是否在地板
    output reg [9:0] pos_x_reg,
    output reg [9:0] pos_y_reg,  // 設定地板高度為100
    output wire [31:0] dina,
    output wire [2:0] addr
);

    reg [2:0] rom_col, rom_row;
    reg [9:0] pos_x_next, pos_y_next;
    
    assign dina = {5'b10000, 1'b0, pos_x_reg, pos_y_reg, rom_row, rom_col};
    assign addr = 0;           
    
    localparam TIME_START_Y      =   100000;  
    localparam TIME_STEP_Y       =    10000; 
    localparam TIME_MAX_Y        =   800000;  
    localparam TIME_TERM_Y       =   250000; 
    
    localparam [2:0]     jump_down    = 3'b000, 
                         jump_up  = 3'b100;
    
    localparam COOL_DOWN_TIME = 500000; // 冷卻時間（以時脈週期數表示）
    reg [19:0] cool_down_reg, cool_down_next; // 冷卻計時器

    reg [2:0] state_reg_y, state_next_y;  
   
    reg [19:0] jump_t_reg, jump_t_next; 
    reg [19:0] start_reg_y, start_next_y; 
    reg [25:0] extra_up_reg, extra_up_next;    

    // signals for up-button positive edge signal
    reg [7:0] up_reg;
    reg is_jumping;
    wire up_edge;
    assign up_edge = ~(&up_reg) & up;
    parameter MIN_Y = 32;

    always @(posedge clk) begin
        if (reset) begin
            is_jumping <= 1'b0;
            pos_y_reg <= 400;  // 初始高度
            pos_x_reg <= 80 - pos_x_shift;
            cool_down_reg <= 0;
        end else begin
            is_jumping <= is_jumping;
            state_reg_y  <= state_next_y;
            jump_t_reg   <= jump_t_next;
            start_reg_y  <= start_next_y;
            extra_up_reg <= extra_up_next;
            pos_y_reg    <= pos_y_next;
            cool_down_reg <= cool_down_next;
            up_reg     <= {up_reg[6:0], up};
        end
    end

    always @(*) begin
        if (game_over) begin
            rom_row <= 1;
            rom_col <= 0;
        end else
        if (state_next_y == jump_up) begin
            rom_row <= start_next_y > 100000 & start_next_y < 600000;
            rom_col <= 3'b001;
        end else begin
            rom_row <= start_next_y > 550000 & start_next_y <= 800000;
            rom_col <= start_next_y > 550000 & start_next_y <= 800000;
        end
    end       

    always @(*) begin
        state_next_y  = state_reg_y;
        jump_t_next   = jump_t_reg;
        start_next_y  = start_reg_y;
        extra_up_next = extra_up_reg;
        pos_y_next    = pos_y_reg;
        cool_down_next = cool_down_reg; 

        if (cool_down_reg > 0) begin
        cool_down_next = cool_down_reg - 1; // 冷卻計時器遞減
        end

        if(up_edge && !game_over && (pos_y_reg == 400) && !cool_down_reg) begin
            state_next_y = jump_up;
            is_jumping <= 1'b1;             
            start_next_y = TIME_START_Y;        
            jump_t_next = TIME_START_Y;         
            extra_up_next = 0;
            cool_down_next = COOL_DOWN_TIME;                  
        end

        case (state_reg_y)
            jump_up: begin
                if(jump_t_reg > 0) begin
                    jump_t_next = jump_t_reg - 1; 
                end
                if(jump_t_reg == 0) begin
                    if( pos_y_next > MIN_Y)           
                        pos_y_next = pos_y_reg - 1;  // 上升過程中改變pos_y_reg
                    if(start_reg_y <= TIME_MAX_Y) begin // 往上跳
                        start_next_y = start_reg_y + TIME_STEP_Y; 
                        jump_t_next = start_reg_y + TIME_STEP_Y;  
                    end else begin // 開始往下掉
                        state_next_y = jump_down;
                        start_next_y = TIME_MAX_Y;                
                        jump_t_next  = TIME_MAX_Y;                
                    end
                end
            end
            jump_down: begin
                if(jump_t_reg > 0) begin
                    jump_t_next = jump_t_reg - 1; 
                end
                /*if(jump_t_reg == 0) begin
                    if (mario_on_ground  && !game_over) begin
                        pos_y_next = 400; // 回到地板高度
                        is_jumping <= 1'b0;
                    end else if (pos_y_next < 480) begin
                        pos_y_next = pos_y_reg + 1; // 繼續掉落
                    end else begin
                        pos_y_next = 480; // 限制最大掉落深度
                        is_jumping <= 1'b0;
                    end
                    if(start_reg_y > TIME_TERM_Y) begin
                        start_next_y = start_reg_y - TIME_STEP_Y; 
                        jump_t_next = start_reg_y - TIME_STEP_Y;  
                    end else begin  
                        jump_t_next = TIME_TERM_Y;
                    end
                end*/
                // mario_on_ground -> 橫向位移不在cliff的範圍
                if(jump_t_reg == 0)                                   
                    begin
                        begin
                        if (mario_on_ground && pos_y_reg == 400) begin
                            pos_y_next = 400; // 鎖定地面高度
                            is_jumping = 1'b0; // 結束跳躍狀態
                        end 
                        // 馬力歐在空中時
                        else if (pos_y_reg < 480) begin
                            pos_y_next = pos_y_reg + 1; // 繼續掉落
                            is_jumping = 1'b1; // 確保處於跳躍狀態
                        end 
                        // 馬力歐接近螢幕下邊界時
                        else begin
                            pos_y_next = 480; // 限制在螢幕下邊界
                            is_jumping = 1'b0; // 結束跳躍狀態
                        end


                        if(start_reg_y > TIME_TERM_Y && is_jumping)                 
                            begin
                                start_next_y = start_reg_y - TIME_STEP_Y; 
                                jump_t_next = start_reg_y - TIME_STEP_Y;  
                            end
                        else
                            begin  
                                jump_t_next = TIME_TERM_Y;
                            end
                        end                 
                    end
            end
        endcase
    end
endmodule
