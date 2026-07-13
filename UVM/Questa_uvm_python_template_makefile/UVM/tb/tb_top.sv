`ifndef TB_TOP_SV
`define TB_TOP_SV

`timescale 1ns/1ns

`include "uvm_macros.svh"

import uvm_pkg::*;
import tc_pkg::*;

module tb_top;

    // =========================================================================
    // Clock and Reset
    // =========================================================================
    logic clk;
    logic rst_n;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns period = 100MHz
    end

    initial begin
        rst_n = 1'b0;
        #100 rst_n = 1'b1;
    end

    // =========================================================================
    // Interfaces
    // =========================================================================
    master_interface input_if (.clk(clk), .rst_n(rst_n));
    slaver_interface output_if(.clk(clk), .rst_n(rst_n));

    // =========================================================================
    // DUT signals
    // =========================================================================
    logic [7:0] dut_a;
    logic [7:0] dut_b;
    logic [7:0] dut_s;
    logic       dut_cout;

    // Connect interface signals to DUT
    assign dut_a   = input_if.data_in0;
    assign dut_b   = input_if.data_in1;
    assign output_if.data_out     = dut_s;
    assign output_if.data_out_vld = 1'b1;   // DUT outputs every cycle
    assign output_if.cout         = dut_cout;

    // =========================================================================
    // DUT Instantiation
    // =========================================================================
    DUT u_dut (
        .clk   (clk),
        .rst_n (rst_n),
        .a     (dut_a),
        .b     (dut_b),
        .s     (dut_s),
        .cout  (dut_cout)
    );

    // =========================================================================
    // UVM Configuration: set virtual interfaces in config_db
    // =========================================================================
    initial begin
        uvm_config_db#(virtual master_interface.DRV)::set(
            null, "uvm_test_top.env.mst_agt.drv", "vif", input_if.DRV);

        uvm_config_db#(virtual slaver_interface.MON)::set(
            null, "uvm_test_top.env.slv_agt.mon", "vif", output_if.MON);
    end

    // =========================================================================
    // Start UVM test
    // =========================================================================
    initial begin
        run_test();
    end

endmodule

`endif
