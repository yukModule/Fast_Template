`ifndef TRAN_ENV__SV
`define TRAN_ENV__SV

class tran_env extends uvm_env;

    master_agent mst_agt;
    slaver_agent slv_agt;
    bus_agent bus_agt;
    tran_rm rm;
    tran_scb scb;
    reg_model regrm;
    bus_adapter adapter;
    uvm_tlm_analysis_fifo #(master_transaction) mst2rm_fifo;
    uvm_tlm_analysis_fifo #(slaver_transaction) rm2scb_fifo;
    uvm_tlm_analysis_fifo #(slaver_transaction) slv2scb_fifo;

    `uvm_component_utils(tran_env)

    function new(string name="tran_env", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mst_agt = master_agent::type_id::create("mst_agt", this);
        mst_agt.is_active = UVM_ACTIVE;
        slv_agt = slaver_agent::type_id::create("slv_agt", this);
        bus_agt = bus_agent::type_id::create("bus_agt", this);
        bus_agt.is_active = UVM_ACTIVE;
        rm = tran_rm::type_id::create("rm", this);
        scb = tran_scb::type_id::create("scb", this);
        mst2rm_fifo = new("mst2rm_fifo", this);
        rm2scb_fifo = new("rm2scb_fifo", this);
        slv2scb_fifo = new("slv2scb_fifo", this);
        regrm = reg_model::type_id::create("regrm", this);
        regrm.configure (null,"");
        regrm.build();
        regrm.lock_model();
        regrm.reset();
        regrm.set_hdl_path_root("harness.u_dut");
        adapter = new("adapter");
    endfunction

    virtual function void connect_phase (uvm_phase phase);
        super.connect_phase(phase);
        mst_agt.drv.ap.connect(mst2rm_fifo.analysis_export);
        rm.port.connect(mst2rm_fifo.blocking_get_export);
        rm.ap.connect(rm2scb_fifo.analysis_export);
        scb.exp_port.connect(rm2scb_fifo.blocking_get_export);
        slv_agt.mon.ap.connect(slv2scb_fifo.analysis_export);
        scb.act_port.connect(slv2scb_fifo.blocking_get_export);
        regrm.default_map.set_sequencer(bus_agt.sqr, adapter);//
        regrm.default_map.set_auto_predict(1);
    endfunction
endclass

`endif

