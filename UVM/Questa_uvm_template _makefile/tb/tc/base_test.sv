`ifndef BASE_TEST__SV
`define BASE_TEST__SV

class tran_sequence extends uvm_sequence#(master_transaction);
    master_transaction m_trans;
    function new(string name = "tran_sequence");
        super.new(name);
    endfunction

    virtual task body();
        if (starting_phase != null) begin
            starting_phase.raise_objection(this);
        end
        repeat(10) begin
            `uvm_do(m_trans)
            `uvm_info("tran_sequence", "send one transaction", UVM_NONE)
        end
        #1000;
        if (starting_phase!=null) begin
            starting_phase.drop_objection(this);
        end
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
    extern virtual task main_phase(uvm_phase phase);
    extern virtual function void report_phase(uvm_phase phase);
    `uvm_component_utils(base_test)

endclass

function void base_test::build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = tran_env::type_id::create("env", this);
    uvm_config_db#(uvm_object_wrapper)::set(this, "env.mst_agt.sqr.main_phase","default_sequence",tran_sequence::type_id::get());
    
endfunction

function void base_test::connect_phase(uvm_phase phase);
endfunction

task base_test::main_phase(uvm_phase phase);
    uvm_status_e status;
    uvm_reg_data_t value;
    #100;
    env.regrm.cfg.read(status,value,UVM_FRONTDOOR);
    `uvm_info("@@@cfg",$sformatf("###000 cfg value is %0h",value),UVM_NONE)
    env.regrm.cfg.write(status,16'h1,UVM_FRONTDOOR);
    env.regrm.cfg.read(status,value,UVM_FRONTDOOR);
    `uvm_info("@@@cfg",$sformatf("##111 cfg value is %0h",value),UVM_NONE)
    //后门读写
    env.regrm.cfg.read (status,value,UVM_BACKDOOR);
    `uvm_info ("@@@cfg",$sformatf ("###222 cfg value is %0h",value),UVM_NONE)
    env.regrm.cfg.write (status,16'h0,UVM_BACKDOOR);
    env.regrm.cfg.read (status,value,UVM_BACKDOOR);
    `uvm_info("@@@cfg",$sformatf ("###333 cfg value is %0h",value),UVM_NONE)
    env.regrm.cfg.poke (status,16'h1);
    env.regrm.cfg.peek(status,value);
    `uvm_info("@@@cfg",$sformatf("###444 cfg value is %0h",value),UVM_NONE)
    env.regrm.cfg.poke (status,16'h2);
    env.regrm.cfg.peek(status,value);
    `uvm_info("@@@stat",$sformatf("###000 cfg value is %0h",value),UVM_NONE)
endtask //base_test::main_phase

function void base_test::report_phase(uvm_phase phase);
    uvm_report_server server; // 声明句柄
    int err_num;
    super.report_phase(phase);
    server = uvm_report_server::get_server(); 
    
    `uvm_info(get_type_name(), "report_phase is executed", UVM_NONE)
    
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