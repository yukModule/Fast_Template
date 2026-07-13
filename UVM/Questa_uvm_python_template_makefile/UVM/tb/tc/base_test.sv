`ifndef BASE_TEST__SV
`define BASE_TEST__SV

class tran_sequence extends uvm_sequence#(master_transaction);
    master_transaction m_trans;

    function new(string name = "tran_sequence");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info("SEQ", "Sequence body started!", UVM_LOW)

        if (starting_phase != null) begin
            starting_phase.raise_objection(this);
        end

        repeat(10) begin
            m_trans = master_transaction::type_id::create("m_trans");
            if (!m_trans.randomize()) begin
                `uvm_error("SEQ", "Failed to randomize transaction")
            end
            `uvm_do(m_trans)
            `uvm_info("SEQ", $sformatf("Sent transaction: data_in0=%0d, data_in1=%0d, vld=%0d",
                m_trans.data_in0, m_trans.data_in1, m_trans.data_in_vld), UVM_LOW)
        end

        #100;
        if (starting_phase != null) begin
            starting_phase.drop_objection(this);
        end
        `uvm_info("SEQ", "Sequence body finished!", UVM_LOW)
    endtask

    `uvm_object_utils(tran_sequence)
endclass

class base_test extends uvm_test;
    tran_env env;

    function new(string name = "base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void connect_phase(uvm_phase phase);
    extern virtual task run_phase(uvm_phase phase);
    extern virtual function void report_phase(uvm_phase phase);

    `uvm_component_utils(base_test)
endclass

function void base_test::build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = tran_env::type_id::create("env", this);
    `uvm_info(get_type_name(), "Build phase completed!", UVM_LOW)
endfunction

function void base_test::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info(get_type_name(), "Connect phase completed!", UVM_LOW)
endfunction

task base_test::run_phase(uvm_phase phase);
    tran_sequence seq;

    `uvm_info(get_type_name(), "Run phase started!", UVM_LOW)

    if (env == null) begin
        `uvm_fatal(get_type_name(), "env is null!")
    end
    if (env.mst_agt == null) begin
        `uvm_fatal(get_type_name(), "mst_agt is null!")
    end
    if (env.mst_agt.sqr == null) begin
        `uvm_fatal(get_type_name(), "sqr is null!")
    end

    `uvm_info(get_type_name(), "All components are valid!", UVM_LOW)

    seq = tran_sequence::type_id::create("seq");
    phase.raise_objection(this);

    `uvm_info(get_type_name(), "Starting sequence...", UVM_LOW)
    seq.start(env.mst_agt.sqr);
    `uvm_info(get_type_name(), "Sequence finished!", UVM_LOW)

    #100;
    phase.drop_objection(this);
    `uvm_info(get_type_name(), "Run phase completed!", UVM_LOW)
endtask

function void base_test::report_phase(uvm_phase phase);
    uvm_report_server server;
    int err_num;

    super.report_phase(phase);
    server = uvm_report_server::get_server();

    `uvm_info(get_type_name(), "Report phase executed", UVM_LOW)

    err_num = server.get_severity_count(UVM_ERROR);

    if (err_num != 0) begin
        $display("---------------------------------------");
        $display("TEST CASE FAILED with %0d errors", err_num);
        $display("---------------------------------------");
    end
    else begin
        $display("---------------------------------------");
        $display("TEST CASE PASSED");
        $display("---------------------------------------");
    end
endfunction

`endif
