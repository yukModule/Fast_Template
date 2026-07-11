`ifndef MASTER_INTERFACE__SV
`define MASTER_INTERFACE__SV
interface master_interface(input clk,input rst_n);
    logic [1:0]data_in0;
    logic [5:0]data_in1;
    logic data_in_vld;

    clocking cb @(posedge clk);
        output data_in0;
        output data_in1;
        output data_in_vld;
    endclocking

    modport DRV(clocking cb, input rst_n);
endinterface
`endif