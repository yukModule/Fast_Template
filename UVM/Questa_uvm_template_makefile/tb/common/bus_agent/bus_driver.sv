`ifndef BUS_DRIVER__SV
`define BUS_DRIVER__SV

class bus_driver extends uvm_driver#(bus_transaction);
    virtual bus_if.DRV vif;
    `uvm_component_utils(bus_driver)
    function new(string name = "bus_driver",uvm_component parent = null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual bus_if)::get(this,"","vif",vif))
            `uvm_fatal("bus driver","virtual interface must be set for vif!!!")
    endfunction

    extern task main_phase(uvm_phase phase);
    extern task cpu_write(bus_transaction tr);
    extern task cpu_read(bus_transaction tr);

endclass

task bus_driver::main_phase(uvm_phase phase);
    vif.cb.bus_cs <= 1'b0;
    vif.cb.bus_op <= 1'b0;
    vif.cb.bus_addr <= 16'b0;
    vif.cb.bus_wr_data <= 16'b0;
    wait(vif.rst_n);
    @vif.cb;
    while(1) begin
        seq_item_port.get_next_item(req);
        if(req.op == 1) cpu_write(req);
        else cpu_read(req);
        seq_item_port.item_done();
    end
endtask

task bus_driver::cpu_write(bus_transaction tr);
    @vif.cb;
    vif.cb.bus_cs <=1'b1;
    vif.cb.bus_op <=tr.op;
    vif.cb.bus_addr <=tr.addr;
    vif.cb.bus_wr_data <=tr.wr_data;
    @vif.cb;
    vif.cb.bus_cs <=1'b0;
    vif.cb.bus_op <=1'b0;
    vif.cb.bus_addr <=16'b0;
    vif.cb.bus_wr_data <=16'b0;
endtask

task bus_driver::cpu_read(bus_transaction tr);
    @vif.cb;
    vif.cb.bus_cs <=1'b1;
    vif.cb.bus_op <=tr.op;
    vif.cb.bus_addr <=tr.addr;
    @vif.cb;
    vif.cb.bus_cs <=1'b0;
    vif.cb.bus_op <=1'b0;
    vif.cb.bus_addr <=16'b0;
    @vif.cb;
    tr.rd_data <=vif.cb.bus_rd_data;
endtask
`endif  