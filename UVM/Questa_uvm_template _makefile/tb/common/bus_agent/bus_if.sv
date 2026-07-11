`ifndef BUS_IF__SV
`define BUS_IF__SV
interface bus_if (input clk,input rst_n);
    logic bus_cs;
    logic bus_op;
    logic [15:0] bus_addr;
    logic [15:0] bus_wr_data;
    logic [15:0] bus_rd_data;

    clocking cb @(posedge clk);
        output bus_cs;
        output bus_op;
        output bus_addr;
        output bus_wr_data;
        input bus_rd_data;
    endclocking

    modport DRV(clocking cb,input rst_n);
    
endinterface
`endif