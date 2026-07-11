`ifndef SLAVER_MONITOR__SV
`define SLAVER_MONITOR__SV

class slaver_monitor extends uvm_monitor;
    virtual slaver_interface.MON vif;
    uvm_analysis_port #(slaver_transaction) ap;

    function new(string name,uvm_component parent);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual slaver_interface)::get(this,"","vif",vif))
            `uvm_fatal("slaver monitor","virtual interface must be set for vif!!!")
        ap = new("ap",this);
    endfunction

    virtual task main_phase(uvm_phase phase);
        slaver_transaction tr;
        wait(vif.rst_n == 1);
        @vif.cb;
        while(1) begin
            tr = new("tr");
            tr.data_out = vif.cb.data_out;
            tr.data_out_vld = vif.cb.data_out_vld;
            if(vif.cb.data_out_vld == 1) ap.write(tr);
            @vif.cb;
        end
    endtask

    `uvm_component_utils(slaver_monitor)
endclass
`endif