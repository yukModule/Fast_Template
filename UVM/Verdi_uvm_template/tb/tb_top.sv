`ifndef TB_TOP_SV
`define TB_TOP_SV

`timescale 1ns/1ns

`include "uvm_macros.svh"

import uvm_pkg::*;
import master_agent_pkg::*;
import slaver_agent_pkg::*;
import bus_agent_pkg::*;
import env_pkg::*;
import tc_pkg::*;

module tb_top;
    logic clk;
    logic rst_n;

    master_interface input_if(clk, rst_n);
    slaver_interface output_if(clk, rst_n);
    bus_if b_if(clk, rst_n);

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst_n = 1'b0;
        #100 rst_n = 1'b1;
    end

    initial begin
        uvm_config_db#(virtual master_interface.DRV)::set(null, "uvm_test_top.env.mst_agt.drv", "vif", input_if);
        uvm_config_db#(virtual slaver_interface.MON)::set(null, "uvm_test_top.env.slv_agt.mon", "vif", output_if);
        uvm_config_db#(virtual bus_if.DRV)::set(null, "uvm_test_top.env.bus_agt.drv", "vif", b_if);
    end

    initial begin
        run_test();
    end

    initial begin
        $fsdbDumpfile("tb_top.fsdb");
        $fsdbDumpvars;
    end

    DUT u_dut(
        .clk            (clk                    ),
        .rst_n          (rst_n                  ),
        .data_in0       (input_if.data_in0      ),
        .data_in1       (input_if.data_in1      ),
        .data_in_vld    (input_if.data_in_vld   ),
        .data_out       (output_if.data_out     ),
        .data_out_vld   (output_if.data_out_vld ),
        .bus_cs         (b_if.bus_cs            ),
        .bus_op         (b_if.bus_op            ),
        .bus_addr       (b_if.bus_addr          ),
        .bus_wr_data    (b_if.bus_wr_data       ),
        .bus_rd_data    (b_if.bus_rd_data       )
    );
endmodule

`endif
