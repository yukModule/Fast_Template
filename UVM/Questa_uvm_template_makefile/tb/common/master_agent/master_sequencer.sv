`ifndef MASTER_SEQUENCER__SV
`define MASTER_SEQUENCER__SV

class master_sequencer extends uvm_sequencer#(master_transaction);
    function new(string name,uvm_component parent);
        super.new(name,parent);
    endfunction

    `uvm_component_utils(master_sequencer)
endclass
`endif