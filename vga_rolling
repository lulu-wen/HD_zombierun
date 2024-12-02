module mem_addr_gen(
   input clk,
   input rst,
   input [9:0] h_cnt,
   input [9:0] v_cnt,
   output [16:0] pixel_addr
);
   reg [8:0] position;  // 使用 9 位來支援橫向滾動的最大範圍

   // 將水平位置偏移應用於 h_cnt，模擬橫向滾動
   assign pixel_addr = (((h_cnt >> 1) + position) % 320 + 320 * (v_cnt >> 1)) % 76800; // 320*240
   
   always @(posedge clk or posedge rst) begin
      if (rst)
          position <= 0; // 復位時，重置位置
      else if (position < 319) // 限制 position 的範圍在一行內
          position <= position + 1; // 每時鐘周期右移一像素
      else
          position <= 0; // 滾動到最右邊時重置
   end
endmodule