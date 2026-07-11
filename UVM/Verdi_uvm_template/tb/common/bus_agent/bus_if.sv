`ifndef BUS_IF__SV
`define BUS_IF__SV
// bus_if.sv
interface bus_if(
    input logic clk,
    input logic rst_n
);
    
    logic       bus_cs;
    logic       bus_op;
    logic [15:0] bus_addr;
    logic [15:0] bus_wr_data;
    logic [15:0] bus_rd_data;
    
    clocking cb @(posedge clk);
        default input #1ps output #1ps;
        output bus_cs;
        output bus_op;
        output bus_addr;
        output bus_wr_data;
        input  bus_rd_data;
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
        input bus_cs,
        input bus_op,
        input bus_addr,
        input bus_wr_data,
        input bus_rd_data
    );
    
endinterface
`endif