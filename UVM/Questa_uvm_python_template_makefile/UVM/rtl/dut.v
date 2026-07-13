`timescale 1ns/1ns
module DUT (
    input               clk             ,
    input               rst_n           ,
    input    [7:0]      a               ,
    input    [7:0]      b               ,
    output   [7:0]      s               ,
    output              cout

);

reg [8:0] reg_s;

assign s = reg_s[7:0];
assign cout = reg_s[8:8];

always @(posedge clk) begin
    if (!rst_n) begin
        reg_s <= 0;
    end
    else begin
        reg_s <= a + b;
    end
end


endmodule
