`ifndef SLAVER_AGENT__SV
`define SLAVER_AGENT__SV

class slaver_agent extends uvm_agent;
    slaver_monitor mon;
    function new(string name,uvm_component parent);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon = slaver_monitor::type_id::create("mon",this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction
    
    `uvm_component_utils(slaver_agent)
endclass
`endif