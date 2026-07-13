`ifndef MASTER_INTERFACE__SV
`define MASTER_INTERFACE__SV
// master_interface.sv - DUT input interface for 8-bit adder
`timescale 1ns/1ns
interface master_interface(
    input logic clk,
    input logic rst_n
);

    logic [7:0] data_in0;     // a[7:0] - first 8-bit operand
    logic [7:0] data_in1;     // b[7:0] - second 8-bit operand
    logic       data_in_vld;  // input valid flag

    clocking cb @(posedge clk);
        default input #1ps output #1ps;
        output data_in0;
        output data_in1;
        output data_in_vld;
    endclocking

    // DRV modport - used by master_driver
    modport DRV (
        clocking cb,
        input rst_n
    );

    // MON modport - used for monitoring (optional)
    modport MON (
        clocking cb,
        input rst_n,
        input data_in0,
        input data_in1,
        input data_in_vld
    );

endinterface
`endif
