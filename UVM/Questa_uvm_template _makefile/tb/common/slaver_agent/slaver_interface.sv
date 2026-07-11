`ifndef SLAVER_INTERFACE__SV
`define SLAVER_INTERFACE__SV
interface slaver_interface(input clk,input rst_n);
    logic [7:0]data_out;
    logic data_out_vld;

    clocking cb @(posedge clk);
        input data_out;
        input data_out_vld;
    endclocking

    modport MON(clocking cb, input rst_n);
endinterface
`endif