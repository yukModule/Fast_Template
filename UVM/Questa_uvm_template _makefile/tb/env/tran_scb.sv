`ifndef TRAN_SCB__SV
`define TRAN_SCB__SV
class tran_scb extends uvm_scoreboard;
    uvm_blocking_get_port #(slaver_transaction) act_port;
    uvm_blocking_get_port #(slaver_transaction) exp_port;
    slaver_transaction exp_tr[$];

    extern function new(string name,uvm_component parent);
    extern function void build_phase(uvm_phase phase);
    extern virtual task main_phase(uvm_phase phase);
    `uvm_component_utils(tran_scb)
endclass

function tran_scb::new(string name,uvm_component parent);
    super.new(name,parent);
endfunction

function void tran_scb::build_phase(uvm_phase phase);
    super.build_phase(phase);
    act_port = new("act_port",this);
    exp_port = new("exp_port",this);
endfunction

task tran_scb::main_phase(uvm_phase phase);
    slaver_transaction get_act_tr;
    slaver_transaction get_exp_tr;
    slaver_transaction tmp_exp_tr;
    fork
        while(1) begin
            exp_port.get(get_exp_tr);
            exp_tr.push_back(get_exp_tr);
        end
        while(1) begin
            act_port.get(get_act_tr);
            if(exp_tr.size() > 0) begin
                tmp_exp_tr = new();
                tmp_exp_tr = exp_tr.pop_front();
                if(tmp_exp_tr.compare(get_act_tr)) begin
                    `uvm_info("my_scb","pass!! exp is eq act",UVM_NONE);
                end
                else begin
                    `uvm_error("my_scb","compare failed");
                    $display("the espect pkt is\n");
                    tmp_exp_tr.print();
                    $display("the actual pkt is\n");
                    get_act_tr.print();
                end
            end
            else begin
                `uvm_error("my_scb","Received from DUT, while expect queue is empty");
                $display("the unexpected pkt is \n");
                get_act_tr.print();
            end
        end
    join
endtask

`endif