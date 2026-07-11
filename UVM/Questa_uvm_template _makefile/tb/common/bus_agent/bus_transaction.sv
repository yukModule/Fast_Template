`ifndef BUS_TRANSACTION__SV
`define BUS_TRANSACTION__SV

class bus_transaction extends uvm_sequence_item;
    rand bit [15:0] rd_data;
    rand bit [15:0] wr_data;
    rand bit [15:0] addr;
    rand bit op;

    `uvm_object_utils_begin(bus_transaction)
        `uvm_field_int(rd_data,UVM_ALL_ON)
        `uvm_field_int(wr_data,UVM_ALL_ON)
        `uvm_field_int(addr,UVM_ALL_ON)
        `uvm_field_int(op,UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name="bus_transaction");
        super.new();
    endfunction

endclass
`endif