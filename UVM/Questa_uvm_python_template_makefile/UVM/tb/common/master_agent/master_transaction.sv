`ifndef MASTER_TRANSACTION__SV
`define MASTER_TRANSACTION__SV
class master_transaction extends uvm_sequence_item;

    rand bit [7:0] data_in0;     // a[7:0] - first 8-bit operand
    rand bit [7:0] data_in1;     // b[7:0] - second 8-bit operand
    rand bit       data_in_vld;  // input valid flag

    // Constrain to reasonable values for 8-bit adder testing
    constraint c_default {
        data_in0 inside {[0:255]};
        data_in1 inside {[0:255]};
    }

    function new(string name="master_transaction");
        super.new(name);
    endfunction

    `uvm_object_utils_begin(master_transaction)
        `uvm_field_int(data_in0, UVM_ALL_ON)
        `uvm_field_int(data_in1, UVM_ALL_ON)
        `uvm_field_int(data_in_vld, UVM_ALL_ON)
    `uvm_object_utils_end

endclass
`endif
