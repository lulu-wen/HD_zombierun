`timescale 1ns / 1ns

module wave_generator(
    input wire clk,
    input wire [15:0] freq,
    output reg signed [9:0] wave_out
);
    reg [5:0] i;
    reg signed [7:0] amplitude [0:63];
    reg [15:0] counter = 0;

    initial begin
        amplitude[0] = 0;
        amplitude[1] = 7;
        amplitude[2] = 13;
        amplitude[3] = 19;
        amplitude[4] = 25;
        amplitude[5] = 30;
        amplitude[6] = 35;
        amplitude[7] = 40;
        amplitude[8] = 45;
        amplitude[9] = 49;
        amplitude[10] = 52;
        amplitude[11] = 55;
        amplitude[12] = 58;
        amplitude[13] = 60;
        amplitude[14] = 62;
        amplitude[15] = 63;
        amplitude[16] = 63;
        amplitude[17] = 63;
        amplitude[18] = 62;
        amplitude[19] = 60;
        amplitude[20] = 58;
        amplitude[21] = 55;
        amplitude[22] = 52;
        amplitude[23] = 49;
        amplitude[24] = 45;
        amplitude[25] = 40;
        amplitude[26] = 35;
        amplitude[27] = 30;
        amplitude[28] = 25;
        amplitude[29] = 19;
        amplitude[30] = 13;
        amplitude[31] = 7;
        amplitude[32] = 0;
        amplitude[33] = -7;
        amplitude[34] = -13;
        amplitude[35] = -19;
        amplitude[36] = -25;
        amplitude[37] = -30;
        amplitude[38] = -35;
        amplitude[39] = -40;
        amplitude[40] = -45;
        amplitude[41] = -49;
        amplitude[42] = -52;
        amplitude[43] = -55;
        amplitude[44] = -58;
        amplitude[45] = -60;
        amplitude[46] = -62;
        amplitude[47] = -63;
        amplitude[48] = -63;
        amplitude[49] = -63;
        amplitude[50] = -62;
        amplitude[51] = -60;
        amplitude[52] = -58;
        amplitude[53] = -55;
        amplitude[54] = -52;
        amplitude[55] = -49;
        amplitude[56] = -45;
        amplitude[57] = -40;
        amplitude[58] = -35;
        amplitude[59] = -30;
        amplitude[60] = -25;
        amplitude[61] = -19;
        amplitude[62] = -13;
        amplitude[63] = -7;
    end

    always @ (posedge clk) begin
      if (freq == 0) wave_out <= 0;
      else
      if (counter == freq) begin
        counter <= 0;
        wave_out <= $signed(amplitude[i]);
        i <= i + 1;
        if (i == 63) i <= 0; else i <= i + 1;
      end else counter <= counter + 1;
    end
endmodule

module audio_output(
  input wire clk,
  output reg out, // pmod 1
  output pmod_2,
	output pmod_4,
  input up,
  input game_over,
  input rst,
  input [15:0] score
);
    assign pmod_2 = 1'd1;	//no gain(6dB)
    assign pmod_4 = 1'd1;	//turn-on
    wire signed [9:0] ch [15:0];
    reg [15:0] pre_score;
    reg signed [11:0] wave_sum;
    wire [11:0] positive_wave_sum;
    wire [15:0] freq_count [0:2];
    wire [15:0] jump_count [0:2];
    wire [15:0] gameover_count [0:6];
    wire [15:0] score_count [0:2];
    reg [9:0] PWM;
    reg [31:0] music_data [0:79];
    reg [31:0] music_data2 [0:79];
    reg [31:0] music_data3 [0:180];
    reg [31:0] jump_data1 [0:15];
    reg [31:0] jump_data2 [0:15];
    reg [31:0] jump_data3 [0:15];
    reg [31:0] gameover_data [0:48];
    reg [31:0] gameover_data2 [0:48];
    reg [31:0] gameover_data3 [0:48];
    reg [31:0] gameover_data4 [0:48];
    reg [31:0] gameover_data5 [0:48];
    reg [31:0] gameover_data6 [0:48];
    reg [31:0] gameover_data7 [0:48];
    reg [31:0] score_data0 [0:7];
    reg [31:0] score_data1 [0:7];
    reg [31:0] score_data2 [0:7];
    reg jump_playing, gameover_play, score_playing;
    reg [31:0] play_counter;
    reg [15:0] note_counter = 0;
    reg [15:0] note_counter1 = 0;
    reg [15:0] jump_counter = 0;
    reg [15:0] gameover_counter = 0;
    reg [15:0] score_counter = 0;
    reg [31:0] note_data[0:1];
    reg [31:0] note_data2;
    reg [31:0] jump_note_data [0:2];
    reg [31:0] gameover_note_data[0:6];
    reg [31:0] score_note_data[0:2];
    wave_generator ch0(clk, freq_count[0], ch[0]);
    wave_generator ch1(clk, freq_count[1], ch[1]);
    wave_generator ch2(clk, freq_count[2], ch[2]);
    wave_generator ch3(clk, jump_count[0], ch[3]);
    wave_generator ch4(clk, jump_count[1], ch[4]);
    wave_generator ch5(clk, jump_count[2], ch[5]);
    wave_generator ch6(clk, gameover_count[0], ch[6]);
    wave_generator ch7(clk, gameover_count[1], ch[7]);
    wave_generator ch8(clk, gameover_count[2], ch[8]);
    wave_generator ch9(clk, gameover_count[3], ch[9]);
    wave_generator ch10(clk, gameover_count[4], ch[10]);
    wave_generator ch11(clk, gameover_count[5], ch[11]);
    wave_generator ch12(clk, gameover_count[6], ch[12]);
    wave_generator ch13(clk, score_count[0], ch[13]);
    wave_generator ch14(clk, score_count[1], ch[14]);
    wave_generator ch15(clk, score_count[2], ch[15]);
    assign freq_count[0] = note_data[0][31:16];
    assign freq_count[1] = note_data[1][31:16];
    assign freq_count[2] = note_data2[31:16];
    assign jump_count[0] = jump_note_data[0][31:16];
    assign jump_count[1] = jump_note_data[1][31:16];
    assign jump_count[2] = jump_note_data[2][31:16];
    assign gameover_count[0] = gameover_note_data[0][31:16];
    assign gameover_count[1] = gameover_note_data[1][31:16];
    assign gameover_count[2] = gameover_note_data[2][31:16];
    assign gameover_count[3] = gameover_note_data[3][31:16];
    assign gameover_count[4] = gameover_note_data[4][31:16];
    assign gameover_count[5] = gameover_note_data[5][31:16];
    assign gameover_count[6] = gameover_note_data[6][31:16];
    assign score_count[0] = score_note_data[0][31:16];
    assign score_count[1] = score_note_data[1][31:16];
    assign score_count[2] = score_note_data[2][31:16];
    assign positive_wave_sum = wave_sum * 2 + 512;


    always @(*)begin
      if(jump_playing) begin
        wave_sum = ch[5] + ch[4] + ch[3];
      end else if(game_over) begin
        wave_sum = ch[6] + ch[7] + ch[8] + ch[9] + ch[10] + ch[11] + ch[12];
      end else if(score_playing) begin
        wave_sum = ch[13] + ch[14] + ch[15];
      end else begin
        wave_sum = ch[2] + ch[1] + ch[0];
      end
    end

    parameter NOTES = 80;
    parameter BASS = 9'd165;
    parameter PLAY_DELAY = 100_000 - 1;
    always @ (posedge clk) begin
      if(rst) begin
        jump_counter <= 16'd0;
        gameover_counter <= 16'd0;
        score_counter <= 16'd0;
        note_counter <= 16'd0;
        note_counter1 <= 16'd0;
        gameover_play <= 1'b0;
        jump_playing <= 1'b0;
        score_playing <= 1'b0;
        pre_score <= 16'd0;
      end else begin
        pre_score <= score;
        if(pre_score < score) begin
          score_playing <= 1'b1;
        end else begin
          score_playing <= score_playing;
        end

        if(up)begin
            jump_playing <= 1'b1;
        end else begin
            jump_playing <= jump_playing;
        end

        if (play_counter == PLAY_DELAY) begin
          play_counter <= 0;

          if (jump_playing) begin
              if(jump_note_data[0][15:0] == 0) begin
                if(jump_counter == 0) begin
                  jump_playing <= 1;
                  jump_counter <= 1;
                  jump_note_data[0] <= jump_data1[0];
                  jump_note_data[1] <= jump_data2[0];
                  jump_note_data[2] <= jump_data3[0];
                end else if(jump_counter < 16) begin
                  jump_counter <= jump_counter + 1;
                  jump_note_data[0] <= jump_data1[jump_counter];
                  jump_note_data[1] <= jump_data2[jump_counter];
                  jump_note_data[2] <= jump_data3[jump_counter];
                  jump_playing <= jump_playing;
                end else begin
                  jump_counter <= 0;
                  jump_playing <= 0;
                end
              end else jump_note_data[0][15:0] <= jump_note_data[0][15:0] - 1;
          end else if(game_over && !gameover_play) begin
              if(gameover_note_data[0][15:0] == 0) begin
                if(gameover_counter == 0) begin
                  gameover_counter <= 1;
                  gameover_note_data[0] <= gameover_data[0];
                  gameover_note_data[1] <= gameover_data2[0];
                  gameover_note_data[2] <= gameover_data3[0];
                  gameover_note_data[3] <= gameover_data4[0];
                  gameover_note_data[4] <= gameover_data5[0];
                  gameover_note_data[5] <= gameover_data6[0];
                  gameover_note_data[6] <= gameover_data7[0];
                  gameover_play <= gameover_play;
                end else if(gameover_counter < 49) begin
                  gameover_counter <= gameover_counter + 1;
                  gameover_note_data[0] <= gameover_data[gameover_counter];
                  gameover_note_data[1] <= gameover_data2[gameover_counter];
                  gameover_note_data[2] <= gameover_data3[gameover_counter];
                  gameover_note_data[3] <= gameover_data4[gameover_counter];
                  gameover_note_data[4] <= gameover_data5[gameover_counter];
                  gameover_note_data[5] <= gameover_data6[gameover_counter];
                  gameover_note_data[6] <= gameover_data7[gameover_counter];
                  gameover_play <= gameover_play;
                end else begin
                  gameover_counter <= 0;
                  gameover_play <= 1;
                end
              end else gameover_note_data[0][15:0] <= gameover_note_data[0][15:0] - 1;
          end else if(score_playing) begin
            if(score_note_data[0][15:0] == 0) begin
              if(score_counter == 0) begin
                score_playing <= score_playing;
                score_counter <= 1;
                score_note_data[0] <= score_data0[0];
                score_note_data[1] <= score_data1[0];
                score_note_data[2] <= score_data2[0];
              end else if(score_counter < 8) begin
                score_playing <= score_playing;
                score_counter <= score_counter + 1;
                score_note_data[0] <= score_data0[score_counter];
                score_note_data[1] <= score_data1[score_counter];
                score_note_data[2] <= score_data2[score_counter];           
              end else begin
                score_playing <= 1'b0;
                score_counter <= 0;
                score_note_data[0] <= score_note_data[0];
                score_note_data[1] <= score_note_data[1];
                score_note_data[2] <= score_note_data[2];
              end
            end else score_note_data[0][15:0] <= score_note_data[0][15:0] - 1;
          end else begin
              if (note_data2[15:0] == 0) begin
                  if (note_counter1 == BASS | note_counter1 == 0) begin
                      note_counter1 <= 1; 
                      note_data2 <= music_data3[0]; 
                      note_counter <= 1; 
                      note_data[0] <= music_data[0];  
                      note_data[1] <= music_data2[0];
                  end
                  else begin
                      note_counter1 <= note_counter1 + 1;
                      note_data2 <= music_data3[note_counter1]; 
                  end
              end else note_data2[15:0] <= note_data2[15:0] - 1; 

              if (note_data[0][15:0] == 0) begin
                  if (note_counter == 0) begin
                      note_counter <= 1;  
                      note_data[0] <= music_data[0];  
                      note_data[1] <= music_data2[0];
                  end
                  else if (note_counter < NOTES) begin
                      note_counter <= note_counter + 1; 
                      note_data[0] <= music_data[note_counter];  
                      note_data[1] <= music_data2[note_counter]; 
                  end
              end else note_data[0][15:0] <= note_data[0][15:0] - 1;
          end
      end else begin
          play_counter <= play_counter + 1; 
      end
      
      // PWM 信号生成
      if (PWM < $unsigned(positive_wave_sum)) out <= 1;
      else out <= 0;
      
      PWM <= PWM + 1;
    end
end
    initial begin
    jump_playing = 0;
    gameover_play = 0;
    //
    score_data0[0] = 32'h04a10070;
    score_data0[1] = 32'h04a100bb;
    score_data0[2] = 32'h04a10025;
    score_data0[3] = 32'h03e4004b;
    score_data0[4] = 32'h02ea0070;
    score_data0[5] = 32'h02ea0070;
    score_data0[6] = 32'h02990070;
    score_data0[7] = 32'h01f2004b;
    //
    score_data1[0] = 32'h00000070;
    score_data1[1] = 32'h03e400bb;
    score_data1[2] = 32'h03e40025;
    score_data1[3] = 32'h02ea004b;
    score_data1[4] = 32'h02990070;
    score_data1[5] = 32'h02990070;
    score_data1[6] = 32'h01f20070;
    score_data1[7] = 32'h0000004b;
    //
    score_data2[0] = 32'h00000070;
    score_data2[1] = 32'h000000bb;
    score_data2[2] = 32'h02ea0025;
    score_data2[3] = 32'h0000004b;
    score_data2[4] = 32'h00000070;
    score_data2[5] = 32'h01f20070;
    score_data2[6] = 32'h00000070;
    score_data2[7] = 32'h0000004b;
    // game_over 音軌1
    gameover_data[1] = 32'h1f230011;
    gameover_data[2] = 32'h1f230035;
    gameover_data[3] = 32'h1f230011;
    gameover_data[4] = 32'h0c5b0011;
    gameover_data[5] = 32'h0c5b0011;
    gameover_data[6] = 32'h0c5b0011;
    gameover_data[7] = 32'h0c5b0011;
    gameover_data[8] = 32'h08bd0047;
    gameover_data[9] = 32'h08bd0011;
    gameover_data[10] = 32'h00000047;
    gameover_data[11] = 32'h1f230011;
    gameover_data[12] = 32'h1f230011;
    gameover_data[13] = 32'h1f230059;
    gameover_data[14] = 32'h1f230011;
    gameover_data[15] = 32'h1f230011;
    gameover_data[16] = 32'h1f230011;
    gameover_data[17] = 32'h1f230011;
    gameover_data[18] = 32'h1f230023;
    gameover_data[19] = 32'h1f230011;
    gameover_data[20] = 32'h08bd0011;
    gameover_data[21] = 32'h1bbe0011;
    gameover_data[22] = 32'h1bbe0011;
    gameover_data[23] = 32'h1bbe0059;
    gameover_data[24] = 32'h09420011;
    gameover_data[25] = 32'h09420011;
    gameover_data[26] = 32'h18b70011;
    gameover_data[27] = 32'h18b70059;
    gameover_data[28] = 32'h18b70011;
    gameover_data[29] = 32'h0a640011;
    gameover_data[30] = 32'h0a640011;
    gameover_data[31] = 32'h17540011;
    gameover_data[32] = 32'h17540047;
    gameover_data[33] = 32'h17540011;
    gameover_data[34] = 32'h03e40011;
    gameover_data[35] = 32'h139e0011;
    gameover_data[36] = 32'h00000035;
    gameover_data[37] = 32'h1bbe0011;
    gameover_data[38] = 32'h1bbe0011;
    gameover_data[39] = 32'h1f230011;
    gameover_data[40] = 32'h1f230047;
    gameover_data[41] = 32'h1f230023;
    gameover_data[42] = 32'h14c80011;
    gameover_data[43] = 32'h00000047;
    gameover_data[44] = 32'h2ea80011;
    gameover_data[45] = 32'h2ea80011;
    gameover_data[46] = 32'h2ea80011;
    gameover_data[47] = 32'h2ea80035;
    gameover_data[48] = 32'h2ea80011;
    // gameover 音軌2
    gameover_data2[0] = 32'h0c5b0011;
    gameover_data2[1] = 32'h0c5b0011;
    gameover_data2[2] = 32'h0c5b0035;
    gameover_data2[3] = 32'h0c5b0011;
    gameover_data2[4] = 32'h041f0011;
    gameover_data2[5] = 32'h1d640011;
    gameover_data2[6] = 32'h0b020011;
    gameover_data2[7] = 32'h08bd0011;
    gameover_data2[8] = 32'h02ea0047;
    gameover_data2[9] = 32'h00000011;
    gameover_data2[10] = 32'h00000047;
    gameover_data2[11] = 32'h0b020011;
    gameover_data2[12] = 32'h0b020011;
    gameover_data2[13] = 32'h08bd0059;
    gameover_data2[14] = 32'h08bd0011;
    gameover_data2[15] = 32'h08bd0011;
    gameover_data2[16] = 32'h08bd0011;
    gameover_data2[17] = 32'h08bd0011;
    gameover_data2[18] = 32'h08bd0023;
    gameover_data2[19] = 32'h08bd0011;
    gameover_data2[20] = 32'h00000011;
    gameover_data2[21] = 32'h0c5b0011;
    gameover_data2[22] = 32'h0c5b0011;
    gameover_data2[23] = 32'h09420059;
    gameover_data2[24] = 32'h03160011;
    gameover_data2[25] = 32'h18b70011;
    gameover_data2[26] = 32'h0a640011;
    gameover_data2[27] = 32'h0a640059;
    gameover_data2[28] = 32'h0a640011;
    gameover_data2[29] = 32'h00000011;
    gameover_data2[30] = 32'h17540011;
    gameover_data2[31] = 32'h107f0011;
    gameover_data2[32] = 32'h03e40047;
    gameover_data2[33] = 32'h03e40011;
    gameover_data2[34] = 32'h139e0011;
    gameover_data2[35] = 32'h00000011;
    gameover_data2[36] = 32'h00000035;
    gameover_data2[37] = 32'h00000011;
    gameover_data2[38] = 32'h1f230011;
    gameover_data2[39] = 32'h00000011;
    gameover_data2[40] = 32'h0a640047;
    gameover_data2[41] = 32'h14c80023;
    gameover_data2[42] = 32'h00000011;
    gameover_data2[43] = 32'h00000047;
    gameover_data2[44] = 32'h00000011;
    gameover_data2[45] = 32'h1a2f0011;
    gameover_data2[46] = 32'h1a2f0011;
    gameover_data2[47] = 32'h0f910035;
    gameover_data2[48] = 32'h00000011;
    // game_over 音軌3
    gameover_data3[0] = 32'h041f0011;
    gameover_data3[1] = 32'h041f0011;
    gameover_data3[2] = 32'h041f0035;
    gameover_data3[3] = 32'h041f0011;
    gameover_data3[4] = 32'h0a640011;
    gameover_data3[5] = 32'h0b020011;
    gameover_data3[6] = 32'h08bd0011;
    gameover_data3[7] = 32'h02ea0011;
    gameover_data3[8] = 32'h00000047;
    gameover_data3[9] = 32'h00000011;
    gameover_data3[10] = 32'h00000047;
    gameover_data3[11] = 32'h08bd0011;
    gameover_data3[12] = 32'h08bd0011;
    gameover_data3[13] = 32'h02ea0059;
    gameover_data3[14] = 32'h02ea0011;
    gameover_data3[15] = 32'h02ea0011;
    gameover_data3[16] = 32'h02ea0011;
    gameover_data3[17] = 32'h02ea0011;
    gameover_data3[18] = 32'h02ea0023;
    gameover_data3[19] = 32'h02ea0011;
    gameover_data3[20] = 32'h00000011;
    gameover_data3[21] = 32'h09420011;
    gameover_data3[22] = 32'h09420011;
    gameover_data3[23] = 32'h03160059;
    gameover_data3[24] = 32'h00000011;
    gameover_data3[25] = 32'h00000011;
    gameover_data3[26] = 32'h03770011;
    gameover_data3[27] = 32'h03770059;
    gameover_data3[28] = 32'h03770011;
    gameover_data3[29] = 32'h00000011;
    gameover_data3[30] = 32'h107f0011;
    gameover_data3[31] = 32'h03e40011;
    gameover_data3[32] = 32'h02500047;
    gameover_data3[33] = 32'h02500011;
    gameover_data3[34] = 32'h00000011;
    gameover_data3[35] = 32'h00000011;
    gameover_data3[36] = 32'h00000035;
    gameover_data3[37] = 32'h00000011;
    gameover_data3[38] = 32'h00000011;
    gameover_data3[39] = 32'h00000011;
    gameover_data3[40] = 32'h00000047;
    gameover_data3[41] = 32'h00000023;
    gameover_data3[42] = 32'h00000011;
    gameover_data3[43] = 32'h00000047;
    gameover_data3[44] = 32'h00000011;
    gameover_data3[45] = 32'h00000011;
    gameover_data3[46] = 32'h0f910011;
    gameover_data3[47] = 32'h00000035;
    gameover_data3[48] = 32'h00000011;
    // game_over 音軌4
    gameover_data4[0] = 32'h00000011;
    gameover_data4[1] = 32'h02730011;
    gameover_data4[2] = 32'h02730035;
    gameover_data4[3] = 32'h0a640011;
    gameover_data4[4] = 32'h17540011;
    gameover_data4[5] = 32'h08bd0011;
    gameover_data4[6] = 32'h02ea0011;
    gameover_data4[7] = 32'h00000011;
    gameover_data4[8] = 32'h00000047;
    gameover_data4[9] = 32'h00000011;
    gameover_data4[10] = 32'h00000047;
    gameover_data4[11] = 32'h00000011;
    gameover_data4[12] = 32'h02ea0011;
    gameover_data4[13] = 32'h0a640059;
    gameover_data4[14] = 32'h0a640011;
    gameover_data4[15] = 32'h0c5b0011;
    gameover_data4[16] = 32'h0c5b0011;
    gameover_data4[17] = 32'h0a640011;
    gameover_data4[18] = 32'h0a640023;
    gameover_data4[19] = 32'h00000011;
    gameover_data4[20] = 32'h00000011;
    gameover_data4[21] = 32'h00000011;
    gameover_data4[22] = 32'h03160011;
    gameover_data4[23] = 32'h00000059;
    gameover_data4[24] = 32'h00000011;
    gameover_data4[25] = 32'h00000011;
    gameover_data4[26] = 32'h00000011;
    gameover_data4[27] = 32'h083f0059;
    gameover_data4[28] = 32'h00000011;
    gameover_data4[29] = 32'h00000011;
    gameover_data4[30] = 32'h00000011;
    gameover_data4[31] = 32'h02500011;
    gameover_data4[32] = 32'h07c80047;
    gameover_data4[33] = 32'h07c80011;
    gameover_data4[34] = 32'h00000011;
    gameover_data4[35] = 32'h00000011;
    gameover_data4[36] = 32'h00000035;
    gameover_data4[37] = 32'h00000011;
    gameover_data4[38] = 32'h00000011;
    gameover_data4[39] = 32'h00000011;
    gameover_data4[40] = 32'h00000047;
    gameover_data4[41] = 32'h00000023;
    gameover_data4[42] = 32'h00000011;
    gameover_data4[43] = 32'h00000047;
    gameover_data4[44] = 32'h00000011;
    gameover_data4[45] = 32'h00000011;
    gameover_data4[46] = 32'h00000011;
    gameover_data4[47] = 32'h00000035;
    gameover_data4[48] = 32'h00000011;
    // game_over 音軌5
    gameover_data5[0] = 32'h00000011;
    gameover_data5[1] = 32'h00000011;
    gameover_data5[2] = 32'h0a640035;
    gameover_data5[3] = 32'h17540011;
    gameover_data5[4] = 32'h1d640011;
    gameover_data5[5] = 32'h02ea0011;
    gameover_data5[6] = 32'h00000011;
    gameover_data5[7] = 32'h00000011;
    gameover_data5[8] = 32'h00000047;
    gameover_data5[9] = 32'h00000011;
    gameover_data5[10] = 32'h00000047;
    gameover_data5[11] = 32'h00000011;
    gameover_data5[12] = 32'h00000011;
    gameover_data5[13] = 32'h00000059;
    gameover_data5[14] = 32'h0c5b0011;
    gameover_data5[15] = 32'h0b020011;
    gameover_data5[16] = 32'h0a640011;
    gameover_data5[17] = 32'h00000011;
    gameover_data5[18] = 32'h0eb20023;
    gameover_data5[19] = 32'h00000011;
    gameover_data5[20] = 32'h00000011;
    gameover_data5[21] = 32'h00000011;
    gameover_data5[22] = 32'h00000011;
    gameover_data5[23] = 32'h00000059;
    gameover_data5[24] = 32'h00000011;
    gameover_data5[25] = 32'h00000011;
    gameover_data5[26] = 32'h00000011;
    gameover_data5[27] = 32'h020f0059;
    gameover_data5[28] = 32'h00000011;
    gameover_data5[29] = 32'h00000011;
    gameover_data5[30] = 32'h00000011;
    gameover_data5[31] = 32'h00000011;
    gameover_data5[32] = 32'h00000047;
    gameover_data5[33] = 32'h139e0011;
    gameover_data5[34] = 32'h00000011;
    gameover_data5[35] = 32'h00000011;
    gameover_data5[36] = 32'h00000035;
    gameover_data5[37] = 32'h00000011;
    gameover_data5[38] = 32'h00000011;
    gameover_data5[39] = 32'h00000011;
    gameover_data5[40] = 32'h00000047;
    gameover_data5[41] = 32'h00000023;
    gameover_data5[42] = 32'h00000011;
    gameover_data5[43] = 32'h00000047;
    gameover_data5[44] = 32'h00000011;
    gameover_data5[45] = 32'h00000011;
    gameover_data5[46] = 32'h00000011;
    gameover_data5[47] = 32'h00000035;
    gameover_data5[48] = 32'h00000011;
    // game_over 音軌6
    gameover_data6[0] = 32'h00000011;
    gameover_data6[1] = 32'h00000011;
    gameover_data6[2] = 32'h00000035;
    gameover_data6[3] = 32'h00000011;
    gameover_data6[4] = 32'h0b020011;
    gameover_data6[5] = 32'h00000011;
    gameover_data6[6] = 32'h00000011;
    gameover_data6[7] = 32'h00000011;
    gameover_data6[8] = 32'h00000047;
    gameover_data6[9] = 32'h00000011;
    gameover_data6[10] = 32'h00000047;
    gameover_data6[11] = 32'h00000011;
    gameover_data6[12] = 32'h00000011;
    gameover_data6[13] = 32'h00000059;
    gameover_data6[14] = 32'h0b020011;
    gameover_data6[15] = 32'h00000011;
    gameover_data6[16] = 32'h00000011;
    gameover_data6[17] = 32'h00000011;
    gameover_data6[18] = 32'h00000023;
    gameover_data6[19] = 32'h00000011;
    gameover_data6[20] = 32'h00000011;
    gameover_data6[21] = 32'h00000011;
    gameover_data6[22] = 32'h00000011;
    gameover_data6[23] = 32'h00000059;
    gameover_data6[24] = 32'h00000011;
    gameover_data6[25] = 32'h00000011;
    gameover_data6[26] = 32'h00000011;
    gameover_data6[27] = 32'h00000059;
    gameover_data6[28] = 32'h00000011;
    gameover_data6[29] = 32'h00000011;
    gameover_data6[30] = 32'h00000011;
    gameover_data6[31] = 32'h00000011;
    gameover_data6[32] = 32'h00000047;
    gameover_data6[33] = 32'h00000011;
    gameover_data6[34] = 32'h00000011;
    gameover_data6[35] = 32'h00000011;
    gameover_data6[36] = 32'h00000035;
    gameover_data6[37] = 32'h00000011;
    gameover_data6[38] = 32'h00000011;
    gameover_data6[39] = 32'h00000011;
    gameover_data6[40] = 32'h00000047;
    gameover_data6[41] = 32'h00000023;
    gameover_data6[42] = 32'h00000011;
    gameover_data6[43] = 32'h00000047;
    gameover_data6[44] = 32'h00000011;
    gameover_data6[45] = 32'h00000011;
    gameover_data6[46] = 32'h00000011;
    gameover_data6[47] = 32'h00000035;
    gameover_data6[48] = 32'h00000011;
    // gameover 音軌 7
    gameover_data7[0] = 32'h00000011;
    gameover_data7[1] = 32'h00000011;
    gameover_data7[2] = 32'h00000035;
    gameover_data7[3] = 32'h00000011;
    gameover_data7[4] = 32'h08bd0011;
    gameover_data7[5] = 32'h00000011;
    gameover_data7[6] = 32'h00000011;
    gameover_data7[7] = 32'h00000011;
    gameover_data7[8] = 32'h00000047;
    gameover_data7[9] = 32'h00000011;
    gameover_data7[10] = 32'h00000047;
    gameover_data7[11] = 32'h00000011;
    gameover_data7[12] = 32'h00000011;
    gameover_data7[13] = 32'h00000059;
    gameover_data7[14] = 32'h00000011;
    gameover_data7[15] = 32'h00000011;
    gameover_data7[16] = 32'h00000011;
    gameover_data7[17] = 32'h00000011;
    gameover_data7[18] = 32'h00000023;
    gameover_data7[19] = 32'h00000011;
    gameover_data7[20] = 32'h00000011;
    gameover_data7[21] = 32'h00000011;
    gameover_data7[22] = 32'h00000011;
    gameover_data7[23] = 32'h00000059;
    gameover_data7[24] = 32'h00000011;
    gameover_data7[25] = 32'h00000011;
    gameover_data7[26] = 32'h00000011;
    gameover_data7[27] = 32'h00000059;
    gameover_data7[28] = 32'h00000011;
    gameover_data7[29] = 32'h00000011;
    gameover_data7[30] = 32'h00000011;
    gameover_data7[31] = 32'h00000011;
    gameover_data7[32] = 32'h00000047;
    gameover_data7[33] = 32'h00000011;
    gameover_data7[34] = 32'h00000011;
    gameover_data7[35] = 32'h00000011;
    gameover_data7[36] = 32'h00000035;
    gameover_data7[37] = 32'h00000011;
    gameover_data7[38] = 32'h00000011;
    gameover_data7[39] = 32'h00000011;
    gameover_data7[40] = 32'h00000047;
    gameover_data7[41] = 32'h00000023;
    gameover_data7[42] = 32'h00000011;
    gameover_data7[43] = 32'h00000047;
    gameover_data7[44] = 32'h00000011;
    gameover_data7[45] = 32'h00000011;
    gameover_data7[46] = 32'h00000011;
    gameover_data7[47] = 32'h00000035;
    gameover_data7[48] = 32'h00000011;

    // background 音軌 1
    music_data[0] = 32'h0000010a;
    music_data[1] = 32'h1284010a;
    music_data[2] = 32'h1754010a;
    music_data[3] = 32'h18b7010a;
    music_data[4] = 32'h0ddf010a;
    music_data[5] = 32'h0d17010a;
    music_data[6] = 32'h14c80085;
    music_data[7] = 32'h0c5b0085;
    music_data[8] = 32'h14c80085;
    music_data[9] = 32'h00000085;
    music_data[10] = 32'h0c5b0085;
    music_data[11] = 32'h00000085;
    music_data[12] = 32'h0c5b0215;
    music_data[13] = 32'h0000010a;
    music_data[14] = 32'h0f91026e;
    music_data[15] = 32'h000000b1;
    music_data[16] = 32'h107f026e;
    music_data[17] = 32'h000000b1;
    music_data[18] = 32'h0f91026e;
    music_data[19] = 32'h00000137;
    music_data[20] = 32'h00000085;
    music_data[21] = 32'h00000085;
    music_data[22] = 32'h00000085;
    music_data[23] = 32'h00000085;
    music_data[24] = 32'h00000085;
    music_data[25] = 32'h0f91026e;
    music_data[26] = 32'h000000b1;
    music_data[27] = 32'h107f0215;
    music_data[28] = 32'h08bd010a;
    music_data[29] = 32'h0f91026e;
    music_data[30] = 32'h0000034c;
    music_data[31] = 32'h00000085;
    music_data[32] = 32'h117a026e;
    music_data[33] = 32'h000000b1;
    music_data[34] = 32'h0b02026e;
    music_data[35] = 32'h000000b1;
    music_data[36] = 32'h117a026e;
    music_data[37] = 32'h00000137;
    music_data[38] = 32'h00000085;
    music_data[39] = 32'h00000085;
    music_data[40] = 32'h00000085;
    music_data[41] = 32'h00000085;
    music_data[42] = 32'h00000085;
    music_data[43] = 32'h0a64026e;
    music_data[44] = 32'h000000b1;
    music_data[45] = 32'h0f910215;
    music_data[46] = 32'h0ddf010a;
    music_data[47] = 32'h0f91026e;
    music_data[48] = 32'h0000034c;
    music_data[49] = 32'h00000085;
    music_data[50] = 32'h0942026e;
    music_data[51] = 32'h000000b1;
    music_data[52] = 32'h07c8026e;
    music_data[53] = 32'h000000b1;
    music_data[54] = 32'h07c8026e;
    music_data[55] = 32'h000000b1;
    music_data[56] = 32'h0000010a;
    music_data[57] = 32'h00000085;
    music_data[58] = 32'h0000010a;
    music_data[59] = 32'h00000085;
    music_data[60] = 32'h08bd026e;
    music_data[61] = 32'h000000b1;
    music_data[62] = 32'h08bd026e;
    music_data[63] = 32'h000000b1;
    music_data[64] = 32'h0baa026e;
    music_data[65] = 32'h000000b1;
    music_data[66] = 32'h0000010a;
    music_data[67] = 32'h00000085;
    music_data[68] = 32'h0000010a;
    music_data[69] = 32'h00000085;
    music_data[70] = 32'h0942026e;
    music_data[71] = 32'h000000b1;
    music_data[72] = 32'h117a010a;
    music_data[73] = 32'h0c5b010a;
    music_data[74] = 32'h0c5b010a;
    music_data[75] = 32'h09420085;
    music_data[76] = 32'h0c5b0085;
    music_data[77] = 32'h0942018f;
    music_data[78] = 32'h117a0085;
    music_data[79] = 32'h1284031f;
    // background 音軌 2
    music_data2[0] = 32'h14c8010a;
    music_data2[1] = 32'h1605010a;
    music_data2[2] = 32'h107f010a;
    music_data2[3] = 32'h0f91010a;
    music_data2[4] = 32'h1754010a;
    music_data2[5] = 32'h1605010a;
    music_data2[6] = 32'h0c5b0085;
    music_data2[7] = 32'h14c80085;
    music_data2[8] = 32'h0c5b0085;
    music_data2[9] = 32'h00000085;
    music_data2[10] = 32'h12840085;
    music_data2[11] = 32'h00000085;
    music_data2[12] = 32'h117a0215;
    music_data2[13] = 32'h0f91010a;
    music_data2[14] = 32'h0942026e;
    music_data2[15] = 32'h000000b1;
    music_data2[16] = 32'h09cf026e;
    music_data2[17] = 32'h000000b1;
    music_data2[18] = 32'h0942026e;
    music_data2[19] = 32'h00000137;
    music_data2[20] = 32'h0f910085;
    music_data2[21] = 32'h0ddf0085;
    music_data2[22] = 32'h0c5b0085;
    music_data2[23] = 32'h0baa0085;
    music_data2[24] = 32'h0a640085;
    music_data2[25] = 32'h0942026e;
    music_data2[26] = 32'h000000b1;
    music_data2[27] = 32'h09cf0215;
    music_data2[28] = 32'h0ddf010a;
    music_data2[29] = 32'h0942026e;
    music_data2[30] = 32'h0000034c;
    music_data2[31] = 32'h0f910085;
    music_data2[32] = 32'h0a64026e;
    music_data2[33] = 32'h000000b1;
    music_data2[34] = 32'h1284026e;
    music_data2[35] = 32'h000000b1;
    music_data2[36] = 32'h0a64026e;
    music_data2[37] = 32'h00000137;
    music_data2[38] = 32'h0f910085;
    music_data2[39] = 32'h0ddf0085;
    music_data2[40] = 32'h0c5b0085;
    music_data2[41] = 32'h0baa0085;
    music_data2[42] = 32'h0b020085;
    music_data2[43] = 32'h117a026e;
    music_data2[44] = 32'h000000b1;
    music_data2[45] = 32'h18b70215;
    music_data2[46] = 32'h08bd010a;
    music_data2[47] = 32'h0942026e;
    music_data2[48] = 32'h0000034c;
    music_data2[49] = 32'h0f910085;
    music_data2[50] = 32'h07c8026e;
    music_data2[51] = 32'h000000b1;
    music_data2[52] = 32'h0a64026e;
    music_data2[53] = 32'h000000b1;
    music_data2[54] = 32'h0b02026e;
    music_data2[55] = 32'h000000b1;
    music_data2[56] = 32'h07c8010a;
    music_data2[57] = 32'h06ef0085;
    music_data2[58] = 32'h0000010a;
    music_data2[59] = 32'h07c80085;
    music_data2[60] = 32'h0a64026e;
    music_data2[61] = 32'h000000b1;
    music_data2[62] = 32'h0b02026e;
    music_data2[63] = 32'h000000b1;
    music_data2[64] = 32'h08bd026e;
    music_data2[65] = 32'h000000b1;
    music_data2[66] = 32'h08bd010a;
    music_data2[67] = 32'h07c80085;
    music_data2[68] = 32'h0000010a;
    music_data2[69] = 32'h08bd0085;
    music_data2[70] = 32'h1754026e;
    music_data2[71] = 32'h000000b1;
    music_data2[72] = 32'h0ddf010a;
    music_data2[73] = 32'h0f91010a;
    music_data2[74] = 32'h08bd010a;
    music_data2[75] = 32'h0c5b0085;
    music_data2[76] = 32'h09420085;
    music_data2[77] = 32'h0c5b018f;
    music_data2[78] = 32'h0c5b0085;
    music_data2[79] = 32'h0baa031f;
    // background 音軌 3
    music_data3[0] = 32'h00000855;
    music_data3[1] = 32'h1f230085;
    music_data3[2] = 32'h00000085;
    music_data3[3] = 32'h1f23031f;
    music_data3[4] = 32'h2ea80085;
    music_data3[5] = 32'h00000085;
    music_data3[6] = 32'h1f230085;
    music_data3[7] = 32'h00000085;
    music_data3[8] = 32'h17540085;
    music_data3[9] = 32'h00000085;
    music_data3[10] = 32'h316e0085;
    music_data3[11] = 32'h00000085;
    music_data3[12] = 32'h1f230085;
    music_data3[13] = 32'h00000085;
    music_data3[14] = 32'h18b70085;
    music_data3[15] = 32'h00000085;
    music_data3[16] = 32'h2ea80085;
    music_data3[17] = 32'h00000085;
    music_data3[18] = 32'h1f230085;
    music_data3[19] = 32'h00000085;
    music_data3[20] = 32'h17540085;
    music_data3[21] = 32'h00000085;
    music_data3[22] = 32'h25080085;
    music_data3[23] = 32'h00000085;
    music_data3[24] = 32'h1f230085;
    music_data3[25] = 32'h00000085;
    music_data3[26] = 32'h17540085;
    music_data3[27] = 32'h00000085;
    music_data3[28] = 32'h2ea80085;
    music_data3[29] = 32'h00000085;
    music_data3[30] = 32'h1f230085;
    music_data3[31] = 32'h00000085;
    music_data3[32] = 32'h17540085;
    music_data3[33] = 32'h00000085;
    music_data3[34] = 32'h316e0085;
    music_data3[35] = 32'h00000085;
    music_data3[36] = 32'h1f230085;
    music_data3[37] = 32'h00000085;
    music_data3[38] = 32'h18b70085;
    music_data3[39] = 32'h00000085;
    music_data3[40] = 32'h2ea80085;
    music_data3[41] = 32'h00000085;
    music_data3[42] = 32'h1f230085;
    music_data3[43] = 32'h00000085;
    music_data3[44] = 32'h17540085;
    music_data3[45] = 32'h00000085;
    music_data3[46] = 32'h25080085;
    music_data3[47] = 32'h00000085;
    music_data3[48] = 32'h1f230085;
    music_data3[49] = 32'h00000085;
    music_data3[50] = 32'h17540085;
    music_data3[51] = 32'h00000085;
    music_data3[52] = 32'h29910085;
    music_data3[53] = 32'h00000085;
    music_data3[54] = 32'h1f230085;
    music_data3[55] = 32'h00000085;
    music_data3[56] = 32'h18b70085;
    music_data3[57] = 32'h00000085;
    music_data3[58] = 32'h2c0a0085;
    music_data3[59] = 32'h00000085;
    music_data3[60] = 32'h20fe0085;
    music_data3[61] = 32'h00000085;
    music_data3[62] = 32'h1a2f0085;
    music_data3[63] = 32'h00000085;
    music_data3[64] = 32'h29910085;
    music_data3[65] = 32'h00000085;
    music_data3[66] = 32'h1f230085;
    music_data3[67] = 32'h00000085;
    music_data3[68] = 32'h18b70085;
    music_data3[69] = 32'h00000085;
    music_data3[70] = 32'h316e0085;
    music_data3[71] = 32'h00000085;
    music_data3[72] = 32'h1f230085;
    music_data3[73] = 32'h00000085;
    music_data3[74] = 32'h18b70085;
    music_data3[75] = 32'h00000085;
    music_data3[76] = 32'h29910085;
    music_data3[77] = 32'h00000085;
    music_data3[78] = 32'h1f230085;
    music_data3[79] = 32'h00000085;
    music_data3[80] = 32'h18b70085;
    music_data3[81] = 32'h00000085;
    music_data3[82] = 32'h316e0085;
    music_data3[83] = 32'h00000085;
    music_data3[84] = 32'h1f230085;
    music_data3[85] = 32'h00000085;
    music_data3[86] = 32'h18b70085;
    music_data3[87] = 32'h00000085;
    music_data3[88] = 32'h2ea80085;
    music_data3[89] = 32'h00000085;
    music_data3[90] = 32'h1f230085;
    music_data3[91] = 32'h00000085;
    music_data3[92] = 32'h17540085;
    music_data3[93] = 32'h00000085;
    music_data3[94] = 32'h3e470085;
    music_data3[95] = 32'h00000085;
    music_data3[96] = 32'h1f230085;
    music_data3[97] = 32'h00000085;
    music_data3[98] = 32'h17540085;
    music_data3[99] = 32'h00000085;
    music_data3[100] = 32'h2ea80085;
    music_data3[101] = 32'h00000085;
    music_data3[102] = 32'h1f230085;
    music_data3[103] = 32'h00000085;
    music_data3[104] = 32'h12840085;
    music_data3[105] = 32'h00000085;
    music_data3[106] = 32'h316e0085;
    music_data3[107] = 32'h00000085;
    music_data3[108] = 32'h1f230085;
    music_data3[109] = 32'h00000085;
    music_data3[110] = 32'h14c80085;
    music_data3[111] = 32'h00000085;
    music_data3[112] = 32'h345f0085;
    music_data3[113] = 32'h00000085;
    music_data3[114] = 32'h1f230085;
    music_data3[115] = 32'h00000085;
    music_data3[116] = 32'h16050085;
    music_data3[117] = 32'h00000085;
    music_data3[118] = 32'h2c0a0085;
    music_data3[119] = 32'h00000085;
    music_data3[120] = 32'h1f230085;
    music_data3[121] = 32'h00000085;
    music_data3[122] = 32'h12840085;
    music_data3[123] = 32'h00000085;
    music_data3[124] = 32'h29910085;
    music_data3[125] = 32'h00000085;
    music_data3[126] = 32'h1bbe0085;
    music_data3[127] = 32'h00000085;
    music_data3[128] = 32'h117a0085;
    music_data3[129] = 32'h00000085;
    music_data3[130] = 32'h2c0a0085;
    music_data3[131] = 32'h00000085;
    music_data3[132] = 32'h1bbe0085;
    music_data3[133] = 32'h00000085;
    music_data3[134] = 32'h117a0085;
    music_data3[135] = 32'h00000085;
    music_data3[136] = 32'h2ea80085;
    music_data3[137] = 32'h00000085;
    music_data3[138] = 32'h1bbe0085;
    music_data3[139] = 32'h00000085;
    music_data3[140] = 32'h117a0085;
    music_data3[141] = 32'h00000085;
    music_data3[142] = 32'h316e0085;
    music_data3[143] = 32'h00000085;
    music_data3[144] = 32'h1f230085;
    music_data3[145] = 32'h00000085;
    music_data3[146] = 32'h117a0085;
    music_data3[147] = 32'h00000085;
    music_data3[148] = 32'h2ea80085;
    music_data3[149] = 32'h00000085;
    music_data3[150] = 32'h1f230085;
    music_data3[151] = 32'h00000085;
    music_data3[152] = 32'h12840085;
    music_data3[153] = 32'h00000085;
    music_data3[154] = 32'h3e470085;
    music_data3[155] = 32'h00000085;
    music_data3[156] = 32'h1f230085;
    music_data3[157] = 32'h00000085;
    music_data3[158] = 32'h1f230085;
    music_data3[159] = 32'h00000085;
    music_data3[160] = 32'h22f40085;
    music_data3[161] = 32'h22f40085;
    music_data3[162] = 32'h22f4018f;
    music_data3[163] = 32'h316e0085;
    music_data3[164] = 32'h2ea8031f;
    // jump 音軌 1
    jump_data1[0] = 32'h0d170011; 
    jump_data1[1] = 32'h0baa0008; 
    jump_data1[2] = 32'h022f0008;
    jump_data1[3] = 32'h022f0008;
    jump_data1[4] = 32'h09cf0008;
    jump_data1[5] = 32'h02ea0008;
    jump_data1[6] = 32'h02ea0008; 
    jump_data1[7] = 32'h083f0008;
    jump_data1[8] = 32'h07c80008;
    jump_data1[9] = 32'h07590008;
    jump_data1[10] = 32'h06ef0008; 
    jump_data1[11] = 32'h068b0008;
    jump_data1[12] = 32'h062d0011;
    jump_data1[13] = 32'h05d50011;
    jump_data1[14] = 32'h05810008;
    jump_data1[15] = 32'h05320011;
    // jump 音軌 2
    jump_data2[0] = 32'h045e0011;
    jump_data2[1] = 32'h022f0008;
    jump_data2[2] = 32'h0b020008;
    jump_data2[3] = 32'h0a640008;
    jump_data2[4] = 32'h02ea0008;
    jump_data2[5] = 32'h01f20008;
    jump_data2[6] = 32'h08bd0008;
    jump_data2[7] = 32'h00000008;
    jump_data2[8] = 32'h00000008;
    jump_data2[9] = 32'h00000008;
    jump_data2[10] = 32'h00000008;
    jump_data2[11] = 32'h00000008;
    jump_data2[12] = 32'h020f0011;
    jump_data2[13] = 32'h01f20011;
    jump_data2[14] = 32'h00000008;
    jump_data2[15] = 32'h00000011;
    // jump 音軌 3
    jump_data3[0] = 32'h02990011;
    jump_data3[1] = 32'h00000008;
    jump_data3[2] = 32'h00000008;
    jump_data3[3] = 32'h00000008;
    jump_data3[4] = 32'h01f20008;
    jump_data3[5] = 32'h09420008;
    jump_data3[6] = 32'h00000008;
    jump_data3[7] = 32'h00000008;
    jump_data3[8] = 32'h00000008;
    jump_data3[9] = 32'h00000008;
    jump_data3[10] = 32'h00000008;
    jump_data3[11] = 32'h00000008;
    jump_data3[12] = 32'h00000011;
    jump_data3[13] = 32'h00000011;
    jump_data3[14] = 32'h00000008;
    jump_data3[15] = 32'h00000011;
    end
endmodule
/*
    set_property PACKAGE_PIN N1 [get_ports {output}]                
    set_property IOSTANDARD LVCMOS33 [get_ports {output}]
*/