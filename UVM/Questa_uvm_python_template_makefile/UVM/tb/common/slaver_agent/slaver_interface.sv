`ifndef SLAVER_INTERFACE__SV
`define SLAVER_INTERFACE__SV
// slaver_interface.sv - DUT output interface for 8-bit adder
`timescale 1ns/1ns
interface slaver_interface(
    input logic clk,
    input logic rst_n
);

    logic [7:0] data_out;     // s[7:0] - sum output from DUT
    logic       data_out_vld; // output valid (tied high or pulsed)
    logic       cout;         // carry-out from DUT

    clocking cb @(posedge clk);
        default input #1ps output #1ps;
        input  data_out;
        input  data_out_vld;
        input  cout;
    endclocking

    // MON modport - used by slaver_monitor
    modport MON (
        clocking cb,
        input rst_n,
        input data_out,
        input data_out_vld,
        input cout
    );

endinterface
`endif
