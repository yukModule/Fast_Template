
`ifndef BUS_ADAPTER__SV
`define BUS_ADAPTER__SV

class bus_adapter extends uvm_reg_adapter;

    `uvm_object_utils(bus_adapter)

    function new(string name="bus_adapter");
        super.new(name);
    endfunction : new

    function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
        bus_transaction tr;
        tr = new("tr");
        tr.addr = rw.addr;
        tr.op = (rw.kind == UVM_WRITE) ? 1 : 0;
        if (rw.kind == UVM_WRITE)
            tr.wr_data = rw.data;
        return tr;
    endfunction : reg2bus

    function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
        bus_transaction tr;
        if(!$cast(tr, bus_item)) begin
            `uvm_fatal(get_type_name(),"Provided bus item is not of the correct type")
            return;
        end
        rw.kind = (tr.op == 1) ? UVM_WRITE : UVM_READ;
        rw.addr = tr.addr;
        rw.data = (tr.op == 0) ? tr.rd_data : tr.wr_data;
        rw.status = UVM_IS_OK;
    endfunction : bus2reg

endclass : bus_adapter

`endif

