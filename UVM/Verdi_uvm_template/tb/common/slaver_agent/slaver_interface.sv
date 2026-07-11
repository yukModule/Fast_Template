`ifndef SLAVER_INTERFACE__SV
`define SLAVER_INTERFACE__SV
// slaver_interface.sv
interface slaver_interface(
    input logic clk,
    input logic rst_n
);
    
    logic [7:0] data_out;
    logic       data_out_vld;
    
    clocking cb @(posedge clk);
        default input #1ps output #1ps;
        input  data_out;
        input  data_out_vld;
    endclocking
    
    // MON modport - 用于 monitor
    modport MON (
        clocking cb,
        input rst_n
    );
    
endinterface
`endif