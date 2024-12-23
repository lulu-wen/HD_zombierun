module Top
	(
		input wire clk, clr,
		input wire [15:0] sw,
		input up_button, down, left, right, 
		output wire hsync, vsync,
		output wire [11:0] rgb,
		output wire [6:0] seg,
        output wire [3:0] ano,
        output wire dp,
        output wire out, pmod_2, pmod_4,
        inout wire PS2_DATA,
        inout wire PS2_CLK
	);
	integer z_index;
	parameter LAYERS = 5;
	reg [11:0] rgb_reg;
	reg [11:0] ctrl;
	wire bg_wea;
	wire wlk;
    wire up, up_db;
    onepulse_Debounce up_debounce(clk, up_button, up);
	wire [11:0] rgb_pic[0:LAYERS - 1];
	wire layer_on[0:LAYERS - 1];
	wire video_on, f_tick, clock_clk, walk_clk;
	wire [9:0] x, y;
	wire [15:0] nums;
	wire [38:0] dina[0:3];
	wire [38:0] data;
    wire [15:0] addr[0:3];
    wire [15:0] bg_data;
    wire [15:0] bg_ram_addr;
    wire [15:0] splash_data;
    wire [15:0] splash_addr;
    //wire [31:0] oam_data;
    wire [31:0] mario1_data, mario2_data,mario3_data;
    //wire [2:0] oam_addr;
    wire [2:0] mario1_addr, mario2_addr, mario3_addr;
    wire [15:0] game_over_data;
    wire [15:0] game_over_addr;
    wire [15:0] bam_data;
    wire [3:0] bg_x_offset;
    reg [9:0] cloud_x_offset;
    wire game_over;
    wire [15:0] score;
    parameter GAME_OVER_DELAY = 5_000;
    reg [31:0] game_over_timer = 0;
    reg game_over_display = 0; 
    
    parameter GAME_BEGIN_DELAY = 500_000_000;
    reg [31:0] splash_timer;
    reg game_begin = 0;
	    clock_normal clock_normal(.clk(clk), .clr(0), .out_clk(clock_clk), .clock(nums));
        vga_sync vga_sync_unit (.clk(clk), .clr(0), .hsync(hsync), .vsync(vsync),
                                .video_on(video_on), .p_tick(), .f_tick(f_tick), .x(x), .y(y));

        display display(.basys3_clk(clk), .seg(seg), .ano(ano), .nums(nums)); // FPGA 顯示
        audio_output audio(clk, out, pmod_2, pmod_4, up, game_over, clr, score);
            ram #(
                    .RAM_WIDTH(9), 
                    .RAM_DEPTH(1208), 
                    .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
                    .INIT_FILE("splash.bin") // 封面圖片
                  ) splash_ram (
                    .addra(0),
                    .addrb(bg_ram_addr),
                    .dina(0), 
                    .clka(clk),     
                    .wea(0),    
                    .enb(1), .rstb(0),    
                    .regceb(1), .doutb(splash_data)
                  );
            ram #(
                .RAM_WIDTH(9), 
                .RAM_DEPTH(1208), 
                .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
                .INIT_FILE("game_over.bin") // GAME OVER
            ) game_over_ram (
                .addra(0),
                .addrb(bg_ram_addr), // 與背景 RAM 共用地址
                .dina(0), 
                .clka(clk),     
                .wea(0),    
                .enb(1), 
                .rstb(0),    
                .regceb(1), 
                .doutb(game_over_data)
            );      
        ram #(
            .RAM_WIDTH(9), 
            .RAM_DEPTH(1208), 
            .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
            .INIT_FILE("")
          ) bg_ram (
            .addra(addr[0]),
            .addrb(bg_ram_addr),
            .dina(dina[0]), 
            .clka(clk),     
            .wea(bg_wea),    
            .enb(1), .rstb(0),    
            .regceb(1), .doutb(bg_data)
          );
        //Mario1  
        ram #(.RAM_WIDTH(32), .RAM_DEPTH(8), .RAM_PERFORMANCE("HIGH_PERFORMANCE"),.INIT_FILE()) Mario1_ram (
            .addra(addr[1]),
            .addrb(mario1_addr),
            .dina(dina[1]), 
            .clka(clk),     
            .wea(bg_wea),    
            .enb(1), .rstb(0),    
            .regceb(1), .doutb(mario1_data)
        );
        // Mario2
        ram #(.RAM_WIDTH(32), .RAM_DEPTH(8), .RAM_PERFORMANCE("HIGH_PERFORMANCE"),.INIT_FILE()) Mario2_ram (
            .addra(addr[2]),
            .addrb(mario2_addr),
            .dina(dina[2]), 
            .clka(clk),     
            .wea(bg_wea),    
            .enb(1), .rstb(0),    
            .regceb(1), .doutb(mario2_data)
        );
        // Mario3
        ram #(.RAM_WIDTH(32), .RAM_DEPTH(8), .RAM_PERFORMANCE("HIGH_PERFORMANCE"),.INIT_FILE()) Mario3_ram (
            .addra(addr[3]),
            .addrb(mario3_addr),
            .dina(dina[3]), 
            .clka(clk),     
            .wea(bg_wea),    
            .enb(1), .rstb(0),    
            .regceb(1), .doutb(mario3_data)
        );
        cloud_bg cloud_bg(clk, video_on, ((x + cloud_x_offset) / 3) % 213, y / 3, rgb_pic[0]);
        background_engine bg_engine(clk, video_on, game_over, bg_x_offset, x, y, bam_data, bg_ram_addr, layer_on[1], rgb_pic[1]);
        object_engine Mario1 (clk, video_on, x, y, mario1_data, mario1_addr, layer_on[2], rgb_pic[2]);
        object_engine Mario2 (clk, video_on, x, y, mario2_data, mario2_addr, layer_on[3], rgb_pic[3]);
        object_engine Mario3 (clk, video_on, x, y, mario3_data, mario3_addr, layer_on[4], rgb_pic[4]);
        game_engine game_eng (clk, clr, video_on, game_begin, up, down, left, right, f_tick, x, y, bg_x_offset, addr[1], addr[2], addr[3], addr[0], bg_wea, dina[1], dina[2], dina[3], dina[0], game_over, PS2_DATA, PS2_CLK, score);

        assign bam_data = game_begin ? (game_over_display ? game_over_data : bg_data) : splash_data;
        assign layer_on[0] = y > 70 && game_begin && !game_over_display;
        always @ (posedge clk)
        if (clr) begin
            game_begin <= 0;
            splash_timer <= 0;
            game_over_display <= 0;
            game_over_timer <= 0;
        end else if(game_over) begin
            if (game_over_timer < GAME_OVER_DELAY) begin
                game_over_timer <= game_over_timer + 1;
                game_over_display <= 0; // 顯示 GAME OVER
            end else begin
                game_over_display <= 1; // 清除 GAME OVER 畫面或切換狀態
                game_over_timer <= game_over_timer;
            end
        end else begin
            if (~game_begin & splash_timer < GAME_BEGIN_DELAY)
                splash_timer <= splash_timer + 1;
            else if (splash_timer == GAME_BEGIN_DELAY) game_begin <= 1;
            for (z_index = 0; z_index < LAYERS; z_index = z_index + 1) begin
                if (layer_on[z_index])
                    rgb_reg <= rgb_pic[z_index];
            end
        end
        always @ (posedge bg_x_offset[0]) begin  // 製造比角色物件慢的位移
            if (cloud_x_offset == 639) cloud_x_offset <= 0;
            else cloud_x_offset <= cloud_x_offset + 1;
        end
        assign dp = 1;
        assign rgb = (video_on & (layer_on[0] | layer_on[1] | layer_on[2] | layer_on[3] | layer_on[4])) ? rgb_reg : 12'b0;
   
endmodule