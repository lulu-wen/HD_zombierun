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
        reg [15:0] bam_addr [4:0];
        reg [15:0] bam_data [4:0];
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
        reg [15:0] floor_x = 0;
        reg [15:0] floor_y = 25; // 固定地板位置 -> 400
        reg [15:0] floor_rows = 3;
        reg [15:0] floor_y_start = 27; // 地板起始行

    // Mario
        wire wlk;
        wire [9:0] mario_x[4:0], mario_y[4:0];
        wire [9:0] mario_x_shift[4:0];
        assign mario_x_shift[0] = 0;
        assign mario_x_shift[1] = 10;
        assign mario_x_shift[2] = 20;
        assign mario_x_shift[3] = 30;
        assign mario_x_shift[4] = 40;
        reg game_over = 0;
        mario mario1(.pos_x_shift(mario_x_shift[0]), .clk(game_on ? clk : 0), .reset(reset), .up(up), .left(left), .right(right), .down(down), .pos_x_reg(mario_x[0]), .pos_y_reg(mario_y[0]),
                    .game_over(game_over), .dina(obj_ram_data), .addr(obj_ram_addr));
        mario mario2(.pos_x_shift(mario_x_shift[1]), .clk(game_on ? clk : 0), .reset(reset), .up(up), .left(left), .right(right), .down(down), .pos_x_reg(mario_x[1]), .pos_y_reg(mario_y[1]),
                    .game_over(game_over), .dina(obj_ram_data), .addr(obj_ram_addr));
        mario mario3(.pos_x_shift(mario_x_shift[2]), .clk(game_on ? clk : 0), .reset(reset), .up(up), .left(left), .right(right), .down(down), .pos_x_reg(mario_x[2]), .pos_y_reg(mario_y[2]),
                    .game_over(game_over), .dina(obj_ram_data), .addr(obj_ram_addr));
        mario mario4(.pos_x_shift(mario_x_shift[3]), .clk(game_on ? clk : 0), .reset(reset), .up(up), .left(left), .right(right), .down(down), .pos_x_reg(mario_x[3]), .pos_y_reg(mario_y[3]),
                    .game_over(game_over), .dina(obj_ram_data), .addr(obj_ram_addr));
        mario mario5(.pos_x_shift(mario_x_shift[4]), .clk(game_on ? clk : 0), .reset(reset), .up(up), .left(left), .right(right), .down(down), .pos_x_reg(mario_x[4]), .pos_y_reg(mario_y[4]),
                    .game_over(game_over), .dina(obj_ram_data), .addr(obj_ram_addr));

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
       /* pipe_pos_x[0] <= 39;
        pipe_up_end[0] <= 10;
        pipe_gap_end[0] <= 22;
        pipe_y[0] <= 2;
        pipe_x[0] <= 39;
        pipe_pos_x[1] <= 26;
        pipe_up_end[1] <= 11;
        pipe_gap_end[1] <= 24;
        pipe_y[1] <= 2;
        pipe_x[1] <= 39;
        pipe_pos_x[2] <= 13;
        pipe_up_end[2] <= 14;
        pipe_gap_end[2] <= 24;
        pipe_y[2] <= 2;
        pipe_x[2] <= 39;*/
    end
    
    always @ (posedge clk) begin

     if (reset) begin
        score <= 0;
        bg_wea <= 0;
        game_over <= 0;
        scroll_delay <= 1_000_000;
        floor_x = 0; 
       /* pipe_pos_x[0] <= 39;
        pipe_up_end[0] <= 10;
        pipe_gap_end[0] <= 22;
        pipe_y[0] <= 1;
        pipe_x[0] <= 39;
        pipe_pos_x[1] <= 26;
        pipe_up_end[1] <= 11;
        pipe_gap_end[1] <= 24;
        pipe_y[1] <= 1;
        pipe_x[1] <= 39;
        pipe_pos_x[2] <= 13;
        pipe_up_end[2] <= 3;
        pipe_gap_end[2] <= 28;
        pipe_y[2] <= 1;
        pipe_x[2] <= 39;*/
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
              else begin bam_counter <= 0; pipe_count <= 0; end
            
              bam_addr[0] <= score_addr;
              bam_data[0] <= score_data;
              bam_addr[4] <= text_addr;
              bam_data[4] <= text_data;
              
              /*if (pipe_y[pipe_count] < pipe_up_end[pipe_count] | pipe_y[pipe_count] > pipe_gap_end[pipe_count]) 
              begin
                  pipe_data_col <= 3'd2 + pipe_x[pipe_count] - pipe_pos_x[pipe_count];
                  pipe_data_props <= 3'b100;
              end
              else if (pipe_y[pipe_count] == pipe_up_end[pipe_count])
              begin
                  pipe_data_col <= 3'd0 + pipe_x[pipe_count] - pipe_pos_x[pipe_count];
                  pipe_data_props <= 3'b110;
                  
              end
              else if (pipe_y[pipe_count] == pipe_gap_end[pipe_count]) 
              begin
                  pipe_data_col <= 3'd0 + pipe_x[pipe_count] - pipe_pos_x[pipe_count];
                  pipe_data_props <= 3'b100;
              end
              else if (pipe_y[pipe_count] > pipe_up_end[pipe_count] + 1 & pipe_y[pipe_count] < pipe_gap_end[pipe_count] - 1)
              begin
                  bg_wea <= 0;
                  pipe_data_props <= 3'b000;
              end
              */
                // 處理第一行
                for (i = 0; i < TILE_COLS; i = i + 1) begin
                    bam_addr[1] <= i + (floor_y_start) * TILE_COLS;

                    // 第一行的處理
                    if (i == 0) begin
                        bam_data[1] <= {1'b1, 2'b01, 3'd6, 3'd1}; // 最左邊的地板屬性
                    end else if (i == TILE_COLS - 1) begin
                        bam_data[1] <= {1'b1, 2'b00, 3'd6, 3'd1}; // 最右邊的地板屬性
                    end else begin
                        bam_data[1] <= {1'b1, 2'b00, 3'd6, 3'd0}; // 其他位置的地板屬性
                    end

                    bg_wea <= 1;
                end

                // 處理第二行
                for (i = 0; i < TILE_COLS; i = i + 1) begin
                    bam_addr[1] <= i + (floor_y_start + 1) * TILE_COLS;

                    // 第二行及以下的地板屬性
                    bam_data[1] <= {1'b1, 2'b00, 3'd6, 3'd3};

                    bg_wea <= 1;
                end

                // 處理最後一行
                for (i = 0; i < TILE_COLS; i = i + 1) begin
                    bam_addr[1] <= i + (floor_y_start + 1) * TILE_COLS;

                    // 第三行及以下的地板屬性
                    bam_data[1] <= {1'b1, 2'b00, 3'd6, 3'd3};

                    bg_wea <= 1;
                end
              /*if (floor_y == y / TILE_HEIGHT) begin
                    bam_addr[1] <= floor_x + floor_y * TILE_COLS;
                    bam_data[1] <= {1'b1, 2'b00, 3'd7, 3'd1}; // 設定地板圖塊的屬性
                    bam_select <= 5;
                    bg_wea <= 1;
              end*/ // 這個是只有兩個地板會動的
              /*
              if (pipe_y[pipe_count] == 39) begin
                  pipe_y[pipe_count] <= 1;
                  if (pipe_x[pipe_count] != pipe_pos_x[pipe_count] + 1)
                     pipe_x[pipe_count] <= pipe_pos_x[pipe_count] + 1;
                  else
                  begin
                     pipe_count <= pipe_count + 1;
                     pipe_y[pipe_count + 1] <= 1; end

              end else
                  pipe_y[pipe_count] <= pipe_y[pipe_count] + 1;
              */
            /*bam_addr[1] <= pipe_x[pipe_count] + pipe_y[pipe_count] * TILE_COLS;
            bam_data[1] <= {pipe_data_props, 3'd5, pipe_data_col};*/
            // coin 
            coin_data_col <= coin_frame + 4;
            bam_addr[3] <= coin_x + coin_y * TILE_COLS;
            bam_data[3] <= {~coin_eaten , 2'b00, 3'd7, coin_data_col};
            end
      bg_x_offset <= (y < 32) ? 0 : real_bg_x_offset;
      if (scroll_counter == scroll_delay) begin
        if (real_bg_x_offset == 15) begin
        if (coin_x > 0) begin
            coin_x <= coin_x - 1;
        end else begin
            coin_eaten <= 0;
            coin_x <= 39 - coin_y_osc % 6;
            coin_y <= coin_y_osc % (TILE_ROWS - 2) + 2;
        end
        if (floor_x > 0)
            floor_x <= floor_x - 1;
        else
            floor_x <= TILE_COLS - 1; // 循環滾動
        for (i = 0; i < 3; i = i + 1)
        /*if (pipe_pos_x[i] > 0)  begin
            pipe_pos_x[i] <= pipe_pos_x[i] - 1;
            pipe_x[i] <= pipe_pos_x[i] - 1;
            pipe_y[i] <= 1;
            if (pipe_pos_x[i] == 2 && ~game_over) begin
                if (scroll_delay > MIN_SCROLL_DELAY & (score + 1) % 10 == 0) scroll_delay <= scroll_delay - SPEED_UP_STEP; 
                score <= score + 1;
            end 
        end
        else begin
        
            pipe_pos_x[i] <= 39;
            pipe_x[i] <= 39;
            pipe_up_end[i] <= up_end_osc + 6;
            pipe_gap_end[i] <= up_end_osc + 14 + gap_end_osc;
            pipe_y[i] <= 1; 
        end*/
        clear_bg <= 1; bam_addr[2] <= 0;
        end
        real_bg_x_offset <= real_bg_x_offset + 1;
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

      up_end_osc <= up_end_osc + x / 2 + y + score;
      gap_end_osc <= gap_end_osc + y + score;
      coin_y_osc <= coin_y_osc + y + x;
    end
    end
    
    assign bg_ram_addr = bam_addr[bam_select];
    assign bg_ram_data = bam_data[bam_select];
endmodule
