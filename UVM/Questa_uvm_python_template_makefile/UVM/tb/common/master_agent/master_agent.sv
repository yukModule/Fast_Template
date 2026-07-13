`ifndef MASTER_AGENT__SV
`define MASTER_AGENT__SV

class master_agent extends uvm_agent;
    master_driver drv;
    master_sequencer sqr;

    function new (string name,uvm_component parent);
        super.new (name,parent);
    endfunction

    virtual function void build_phase (uvm_phase phase);
        super.build_phase (phase);
        if(is_active == UVM_ACTIVE) begin
            drv = master_driver::type_id::create("drv",this);
            sqr = master_sequencer::type_id::create("sqr",this);
        end
    endfunction

    virtual function void connect_phase (uvm_phase phase);
        super.connect_phase (phase);
        if(is_active == UVM_ACTIVE) begin
            drv.seq_item_port.connect(sqr.seq_item_export);
        end
    endfunction
    
    `uvm_component_utils(master_agent)
endclass
`endif