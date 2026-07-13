`ifndef TRAN_RM__SV
`define TRAN_RM__SV

class tran_rm extends uvm_component;
    uvm_blocking_get_port #(master_transaction) port;
    uvm_analysis_port #(slaver_transaction) ap;

    extern function new(string name,uvm_component parent);
    extern function void build_phase(uvm_phase phase);
    extern virtual task main_phase(uvm_phase phase);

    `uvm_component_utils(tran_rm)
endclass

function tran_rm::new(string name,uvm_component parent);
    super.new(name,parent);
endfunction

function void tran_rm::build_phase(uvm_phase phase);
    super.build_phase(phase);
    port = new("port",this);
    ap = new("ap",this);
endfunction

task tran_rm::main_phase(uvm_phase phase);
    master_transaction tr_in;
    slaver_transaction tr_out;
    while(1) begin
        tr_out = new();
        port.get(tr_in);
        tr_out.data_out = {tr_in.data_in1, tr_in.data_in0};
        tr_out.data_out_vld = tr_in.data_in_vld;
        if(tr_in.data_in_vld == 1) ap.write(tr_out);
    end
endtask
`endif