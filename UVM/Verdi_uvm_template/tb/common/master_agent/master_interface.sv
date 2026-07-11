`ifndef MASTER_INTERFACE__SV
`define MASTER_INTERFACE__SV
// master_interface.sv
interface master_interface(
    input logic clk,
    input logic rst_n
);
    
    logic [1:0] data_in0;
    logic [5:0] data_in1;
    logic       data_in_vld;
    logic [7:0] data_out;
    logic       data_out_vld;
    
    clocking cb @(posedge clk);
        default input #1ps output #1ps;
        output data_in0;
        output data_in1;
        output data_in_vld;
        input  data_out;
        input  data_out_vld;
    endclocking
    
    // DRV modport - 用于 driver
    modport DRV (
        clocking cb,
        input rst_n
    );
    
    // MON modport - 用于 monitor
    modport MON (
        clocking cb,
        input rst_n,
        input data_in0,
        input data_in1,
        input data_in_vld,
        input data_out,
        input data_out_vld
    );
    
endinterface
`endif
