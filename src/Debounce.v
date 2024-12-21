module onepulse_Debounce(
    input clk,
    input pb,
    output reg db_pulse
);
reg [3:0] DFF;
wire db;
always @(posedge clk) begin
    DFF[0] <= pb;
    DFF[3:1] <= DFF[2:0];
end
assign db = (DFF == 4'b1111);

reg db_delay;
always @(posedge clk) begin
    db_delay <= db;
    db_pulse <= db && !db_delay;
end
endmodule