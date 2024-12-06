`timescale 1ns / 1ps
module mario(
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
    reg [16:0] frame_counter; // 用來控制幀切換
    reg [2:0] current_frame; // 當前的顯示幀
    
    assign dina = {5'b10000, 1'b0, pos_x_reg, pos_y_reg, rom_row, rom_col};
    assign addr = 0;           
    
    localparam TIME_START_Y      =   100000;  
    localparam TIME_STEP_Y       =    10000; 
    localparam TIME_MAX_Y        =   800000;  
    localparam TIME_TERM_Y       =   250000; 
    localparam RUNNING_FRAME_COUNT = 100000; // 每100000時脈週期切換一幀
    
    localparam [2:0]    running_frame_1 = 3'b000,
                        running_frame_2 = 3'b001,
                        running_frame_3 = 3'b010,
                        running_frame_4 = 3'b011,
                        running_frame_5 = 3'b100;
    
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
            frame_counter <= 0;
            current_frame <= running_frame_1; // 初始化顯示幀
            is_jumping <= 1'b0;
            pos_y_reg <= 400;  // 初始高度
            pos_x_reg <= 80;
            cool_down_reg <= 0;
        end else begin
            frame_counter <= frame_counter + 1; // 計數器增加
            if (frame_counter == RUNNING_FRAME_COUNT) begin
                frame_counter <= 0; // 重置計數器
                // 切換顯示的幀
                case (current_frame)
                    running_frame_1: current_frame <= running_frame_2;
                    running_frame_2: current_frame <= running_frame_3;
                    running_frame_3: current_frame <= running_frame_4;
                    running_frame_4: current_frame <= running_frame_5;
                    running_frame_5: current_frame <= running_frame_1;
                endcase
            end
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

    /*always @(*) begin
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
    end   */

    //跑步+跳躍
    always @(*) begin
        if (game_over) begin
            rom_row <= 0;  // 遊戲結束時使用靜止幀
            rom_col <= 0;  // 靜止狀態的第一個幀
        end else if (start_next_y == running_frame_1) begin
            // 當 Mario 正在跳躍時，根據跳躍的過程切換幀
            if (start_next_y > 100000 && start_next_y < 600000) begin
                rom_row <= 0;  // 假設跳躍過程中還是用同一行
                rom_col <= running_frame_2;  // 跳躍的幀
            end else if (start_next_y >= 600000 && start_next_y < 800000) begin
                rom_row <= 0;  // 跳躍結束時還是用同一行
                rom_col <= running_frame_3;  // 跳躍的另一個幀
            end else begin
                rom_row <= 0;  // 當 Mario 跳到頂點後
                rom_col <= running_frame_4;  // 顯示跳躍的最後一個幀
            end
        end else begin
            rom_col <= current_frame;
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
            state_next_y = running_frame_1;
            is_jumping <= 1'b1;             
            start_next_y = TIME_START_Y;        
            jump_t_next = TIME_START_Y;         
            extra_up_next = 0;
            cool_down_next = COOL_DOWN_TIME;                  
        end

        case (state_reg_y)
            running_frame_1: begin
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
                        state_next_y = running_frame_2;
                        start_next_y = TIME_MAX_Y;                
                        jump_t_next  = TIME_MAX_Y;                
                    end
                end
            end
            running_frame_2: begin
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
