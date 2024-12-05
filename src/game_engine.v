`timescale 1ns / 1ps
module game_engine(
    input wire clk, reset,
    input wire video_on, game_on,
    input wire up, down, left, right,
    input wire f_tick,
    input wire [9:0]  x, y,
    output reg [3:0] bg_x_offset,
    output wire [7:0] obj_ram_addr,
    output wire [15:0] bg_ram_addr,
    output reg bg_wea = 0,
    output wire [31:0] obj_ram_data,
    output wire [31:0] bg_ram_data
); 
    // Multiplexers
        reg [15:0] bam_addr [5:0];
        reg [15:0] bam_data [5:0];
        wire  [15:0] score_addr, score_data, text_addr, text_data;
        reg [15:0] score = 0;
        reg  [2:0] bam_select;
        reg  [15:0] bam_counter;
        reg [3:0] real_bg_x_offset;

    // pipes
        reg  [2:0] gap_end_osc;
        reg  [2:0] up_end_osc;
        reg  [15:0] pipe_pos_x[2:0];
        reg  [15:0] pipe_up_end[2:0];
        reg  [15:0] pipe_gap_end[2:0];
        reg  [15:0] pipe_y[2:0];
        reg  [15:0] pipe_x[2:0];
        reg [2:0] pipe_data_col, pipe_data_row, pipe_data_props;
        reg [1:0] pipe_count;

    // coins
        reg [15:0] coin_x = 38, coin_y = 16;
        reg [15:0] coin_counter;
        reg [2:0] coin_data_col;
        reg [7:0] coin_y_osc;
        reg [31:0] scroll_counter, scroll_delay = 1_000_000;
        reg [31:0] coin_animate_counter;
        reg [1:0] coin_frame;
        reg coin_eaten;

    // 地板
        reg [15:0] floor_rows = 3;
        reg [15:0] floor_y_start = 27; // 地板起始行
        reg [6:0] ground_count = 0;
        reg [15:0] ground_x, ground_y;
        reg [15:0] ground_pos_x;
        reg [15:0] cliff_x, right_cliff_x;

    // Mario
        reg mario_on_ground;
        wire wlk;
        wire [9:0] mario_x, mario_y;
        reg game_over = 0;
        mario mario(.clk(game_on ? clk : 0), .reset(reset), .up(up), .left(left), .right(right), .down(down), .pos_x_reg(mario_x), .pos_y_reg(mario_y),
                    .game_over(game_over), .dina(obj_ram_data), .addr(obj_ram_addr), .mario_on_ground(mario_on_ground));

    // Ghost
    reg [15:0] ghost_x = 37;  // 初始化鬼魂位置為螢幕右側
    reg [15:0] ghost_y = 15;  // 鬼魂垂直位置（可以根據需求調整）
    wire [7:0] ghost_data_col = 4;

    // game status
    vga_num vga_num(clk, 1, score, score_addr, score_data);
    game_over_text text(clk, game_over, text_addr, text_data);

    integer i;
    reg clear_bg = 0;
    parameter TILE_WIDTH = 16;
    parameter TILE_HEIGHT = 16;
    parameter TILE_COLS = 640 / TILE_WIDTH;
    parameter TILE_ROWS = 480 / TILE_HEIGHT;
    parameter MAX_SCROLL_DELAY = 1_000_000;
    parameter MIN_SCROLL_DELAY = 200_000;
    parameter COIN_ANIMATE_DELAY = 15_000_000;
    parameter COIN_SCORE = 10;
    parameter SPEED_UP_STEP = 100_000;

    // 400 clocks for pipes and 10 clocks for score
    // clear background

    initial begin
        score <= 0;
        game_over <= 0;
        scroll_delay <= 1_000_000; 
        ground_count <= 0; // 初始化地板繪製的索引
        ground_x <= 0;
        ground_pos_x <= 0;
        ground_y <= TILE_ROWS - 3;
        cliff_x <= 10;

        // Mario
        mario_on_ground <= 1'b1;
    end
    reg [7:0] lfsr_cliff;
    reg cliff_refresh;
    reg [7:0] cliff_refresh_idx;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            lfsr_cliff <= 8'b10110101; 
        end else begin
            lfsr_cliff <= {lfsr_cliff[6:0], lfsr_cliff[7] ^ lfsr_cliff[5]};
        end
    end

    always @ (posedge clk) begin

     if (reset) begin
        score <= 0;
        bg_wea <= 0;
        game_over <= 0;
        scroll_delay <= 1_000_000;
        ground_count <= 0; // 初始化地板繪製的索引
        ground_x <= 0;
        cliff_x <= 20;
        ground_pos_x <= 0;
        ground_y <= TILE_ROWS - 3;

        // Mario
        mario_on_ground <= 1'b1;
     end
    /*
        `define TILE_COL ram_data[2:0]
    `define TILE_ROW ram_data[5:3]
    `define X_FILP ram_data[6:6]
    `define Y_FLIP ram_data[7:7]
    `define ENABLE ram_data[8:8]*/
     if (game_on) begin
        if (clear_bg) begin
            bg_wea <= 1;
            if (bam_addr[2] == TILE_COLS * TILE_ROWS) clear_bg <= 0;
            bam_select <= 2;
            bam_addr[2] <= bam_addr[2] + 1;
            bam_data[2] <= 0;
        end
      else begin
              if (bam_counter < 2050) begin bam_select <= 1; bam_counter <= bam_counter + 1; bg_wea <= 1 ;end
              else if (bam_counter >= 2050 & bam_counter < 2064) begin bam_select <= 0; bam_counter <= bam_counter + 1; bg_wea <= 1; end
              else if (bam_counter >= 2064 & bam_counter < 2100) begin bam_select <= 3; bam_counter <= bam_counter + 1; bg_wea <= 1; end
              else if (bam_counter >= 2100 & bam_counter < 2300) begin bam_select <= 4; bam_counter <= bam_counter + 1; bg_wea <= 1; end
              else if (bam_counter >= 2300 && bam_counter < 2500) begin bam_select <= 5; bam_counter <= bam_counter + 1; bg_wea <= 1; end
              else begin bam_counter <= 0; ground_count <= 0; end
            
              bam_addr[0] <= score_addr;
              bam_data[0] <= score_data;
              bam_addr[4] <= text_addr;
              bam_data[4] <= text_data;
              
        if (ground_count < TILE_COLS * 3) begin
            ground_x <= ground_count % TILE_COLS;
            ground_y <= floor_y_start + (ground_count / TILE_COLS); // y 座標根據行數計算
            bam_addr[1] <= ground_x + ground_y * TILE_COLS; // 計算 BAM 地址
    
            if (ground_x == cliff_x - 4) begin
                    // 左邊緣
                    if (ground_y == floor_y_start) begin
                        bam_data[1] <= {1'b1, 2'b00, 3'd6, 3'd1}; // 左斷崖
                    end else begin
                        bam_data[1] <= {1'b1, 2'b00, 3'd7, 3'd0};
                    end
                    bg_wea <= 1;
            // cliff & cliff - 1 -> cliff = 0 / cliff_refresh_idx <= (lfsr_cliff % 101) + 20;
            end else if (ground_x == (cliff_x - 1)) begin
                    // 右邊緣
                    if (ground_y == floor_y_start) begin
                            bam_data[1] <= {1'b1, 2'b01, 3'd6, 3'd1}; // 右斷崖
                        end else begin
                            bam_data[1] <= {1'b1, 2'b01, 3'd7, 3'd0};
                        end
                    bg_wea <= 1;
            end else if ((ground_x == cliff_x - 3 || ground_x == cliff_x - 2)) begin
                    // 空白區域
                    bg_wea <= 0;
            end else begin
                    if (ground_y == floor_y_start) begin
                    // 第一行地板
                        bam_data[1] <= {1'b1, 2'b00, 3'd6, 3'd0}; // 中間地板屬性
                    end else if (ground_y == (TILE_ROWS) - 2) begin
                        // 第二行地板
                        bam_data[1] <= {1'b1, 2'b00, 3'd6, 3'd3};
                    end else if (ground_y == (TILE_ROWS) - 1) begin
                        // 第三行地板
                        bam_data[1] <= {1'b1, 2'b00, 3'd6, 3'd3};
                    end
                    bg_wea <= 1; 
            end
            ground_count <= ground_count + 1;
        end else begin
                bg_wea <= 0; // 停止寫入
                ground_count <= 0;
        end
            // coin 
            coin_data_col <= coin_frame + 4;
            bam_addr[3] <= coin_x + coin_y * TILE_COLS;
            bam_data[3] <= {~coin_eaten , 2'b00, 3'd7, coin_data_col};

            bam_addr[5] <= ghost_x + ghost_y * TILE_COLS;
            bam_data[5] <= {1'b1, 2'b00, 3'd6, 3'd7}; // 設定鬼魂屬性和圖像
            end
      bg_x_offset <= (y < 32) ? 0 : real_bg_x_offset;
      if (scroll_counter == scroll_delay) begin
        if (real_bg_x_offset == 15) begin
        if (coin_x > 0) begin
            coin_x <= coin_x - 1;
        end else begin
            coin_eaten <= 0;
            coin_x <= 39 - coin_y_osc % 6;
            coin_y <= (coin_y_osc % 4 + 23);
        end
         if (ghost_x > 0) begin
            ghost_x <= ghost_x - 1;
        end else begin
            ghost_x <= TILE_COLS - 1;
        end
        /*if (ground_x > 0) begin
            ground_x <= ground_x - 1;
        end else begin
            ground_x <= 39; // 循環滾動
        end*/
        if(cliff_x > 0) begin
            cliff_x <= cliff_x - 1;
            cliff_refresh_idx <= cliff_refresh_idx;
            if(cliff_x == (cliff_refresh - 1 || cliff_refresh_idx - 2)) cliff_refresh <= 1'b1;
            else cliff_refresh <= 1'b0;
        end else if(cliff_x == 0) begin
            cliff_x <= (lfsr_cliff % 101) + 50;
            cliff_refresh <= 1'b1;
            cliff_refresh_idx <= (lfsr_cliff % 101) + 20;
        end
        clear_bg <= 1; bam_addr[2] <= 0;
        end
        real_bg_x_offset <= (real_bg_x_offset + 1) % TILE_COLS;
        scroll_counter <= 0;
      end else
        scroll_counter <= scroll_counter + 1;
        
      if (coin_animate_counter == COIN_ANIMATE_DELAY) begin coin_frame <= coin_frame + 1; coin_animate_counter <= 0; end
      else coin_animate_counter <= coin_animate_counter + 1;
      
      if (((mario_x + 28 + real_bg_x_offset) >= (pipe_pos_x[pipe_count] * TILE_WIDTH) & mario_x + real_bg_x_offset < (pipe_pos_x[pipe_count] + 2) * TILE_WIDTH 
          & ((mario_y < (pipe_up_end[pipe_count] + 1) * TILE_HEIGHT) | (mario_y + 28 > pipe_gap_end[pipe_count] * TILE_HEIGHT))) | mario_y > 480)
        game_over <= 0;

        if ((mario_x + 28 + real_bg_x_offset) >= (coin_x * TILE_WIDTH) & mario_x + real_bg_x_offset < (coin_x + 1) * TILE_WIDTH 
          & (mario_y >= (coin_y - 1) * TILE_HEIGHT) & (mario_y <= (coin_y + 1) * TILE_HEIGHT)
          & ~coin_eaten & ~game_over)
        begin coin_eaten <= 1; score <= score + COIN_SCORE; end

        // Mario on ground (ground_x >= cliff_x - 2 && ground_x <= cliff_x - 1)
        if (mario_x + real_bg_x_offset >= ((cliff_x - 4) * TILE_WIDTH) && 
            mario_x + real_bg_x_offset <= ((cliff_x - 2) * TILE_WIDTH)) begin
            mario_on_ground <= 1'b0;
        end else begin
            mario_on_ground <= 1'b1;
        end
        if (!mario_on_ground && mario_y >= 480) begin
            game_over <= 1; // 如果馬力歐不在地板上且掉出畫面，遊戲結束
        end else begin
            game_over <= game_over;
        end 
      up_end_osc <= up_end_osc + x / 2 + y + score;
      gap_end_osc <= gap_end_osc + y + score;
      coin_y_osc <= coin_y_osc + y + x;
    end
    end
    
    assign bg_ram_addr = bam_addr[bam_select];
    assign bg_ram_data = bam_data[bam_select];
endmodule
