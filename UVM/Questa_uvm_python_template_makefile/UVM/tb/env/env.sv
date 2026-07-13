`ifndef ENV__SV
`define ENV__SV

// ============================================================================
// tran_env: UVM Environment for 8-bit adder verification.
// Contains:
//   - master_agent (active) : drives DUT inputs (a, b)
//   - slaver_agent (passive): monitors DUT outputs (sum, cout)
//   - adder_scb             : scoreboard with DPI-C Python reference comparison
// ============================================================================

class tran_env extends uvm_env;

    `uvm_component_utils(tran_env)

    master_agent mst_agt;
    slaver_agent slv_agt;
    adder_scb    scb;

    function new(string name = "tran_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        `uvm_info(get_type_name(), "Building environment...", UVM_LOW)

        // Create master agent (active - drives DUT inputs)
        mst_agt = master_agent::type_id::create("mst_agt", this);
        mst_agt.is_active = UVM_ACTIVE;

        // Create slave agent (passive - monitors DUT outputs)
        slv_agt = slaver_agent::type_id::create("slv_agt", this);
        slv_agt.is_active = UVM_PASSIVE;

        // Create scoreboard (with DPI-C Python reference)
        scb = adder_scb::type_id::create("scb", this);

        `uvm_info(get_type_name(), "Environment build complete", UVM_LOW)
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        `uvm_info(get_type_name(), "Connecting environment...", UVM_LOW)

        // Connect master_driver analysis port → scoreboard (input transactions)
        mst_agt.drv.ap.connect(scb.mst_export);

        // Connect slaver_monitor analysis port → scoreboard (output transactions)
        slv_agt.mon.ap.connect(scb.slv_export);

        `uvm_info(get_type_name(), "Environment connections complete", UVM_LOW)
    endfunction

endclass

`endif
