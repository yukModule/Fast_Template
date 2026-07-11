`ifndef MASTER_DRIVER__SV
`define MASTER_DRIVER__SV

class master_driver extends uvm_driver#(master_transaction);
    virtual master_interface.DRV vif;
    uvm_analysis_port #(master_transaction) ap;

    function new(string name,uvm_component parent);
        super.new(name,parent);
    endfunction

    virtual function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual master_interface.DRV)::get(this,"","vif",vif))
            `uvm_fatal("master driver","virtual interface must be set for vif!!!")
        ap = new("ap",this);
    endfunction

    virtual task run_phase (uvm_phase phase);
        vif.cb.data_in0 <=0;
        vif.cb.data_in1 <=0;
        vif.cb.data_in_vld <=0;
    wait(vif.rst_n ==1);
    @vif.cb;
    while (1) begin
        seq_item_port.get_next_item(req);
        ap.write(req);
        vif.cb.data_in0 <= req.data_in0;
        vif.cb.data_in1 <= req.data_in1;
        vif.cb.data_in_vld <= req.data_in_vld;
        @vif.cb;
        vif.cb.data_in0 <=0;
        vif.cb.data_in1 <=0;
        vif.cb.data_in_vld <=0;
        seq_item_port.item_done();
    end
    endtask

    `uvm_component_utils(master_driver)
endclass
`endif
