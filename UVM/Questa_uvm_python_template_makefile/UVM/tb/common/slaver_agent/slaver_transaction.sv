`ifndef SLAVER_TRANSACTION__SV
`define SLAVER_TRANSACTION__SV

class slaver_transaction extends uvm_sequence_item;
    rand bit [7:0] data_out;      // sum[7:0] - DUT sum output
    rand bit       data_out_vld;  // output valid flag
    rand bit       cout;          // carry-out from DUT

    function new(string name="slaver_transaction");
        super.new(name);
    endfunction

    `uvm_object_utils_begin(slaver_transaction)
        `uvm_field_int(data_out, UVM_ALL_ON)
        `uvm_field_int(data_out_vld, UVM_ALL_ON)
        `uvm_field_int(cout, UVM_ALL_ON)
    `uvm_object_utils_end
endclass
`endif
