`ifndef REG_MODEL__SV
`define REG_MODEL__SV

class reg_cfg extends uvm_reg;
    rand uvm_reg_field reserved;
    rand uvm_reg_field cfg;

    virtual function void build();
        reserved = uvm_reg_field::type_id::create("reserved");
        cfg = uvm_reg_field::type_id::create("cfg");
        reserved.configure(this, 15, 1, "RO", 0, 15'h0, 1, 1, 0);
        cfg.configure(this, 1, 0, "RW", 0, 1'h0, 1, 1, 0);
    endfunction

    `uvm_object_utils(reg_cfg)

    function new(input string name="reg_cfg");
        super.new(name, 16, UVM_NO_COVERAGE);
    endfunction
endclass

class reg_stat extends uvm_reg;
    rand uvm_reg_field reserved;
    rand uvm_reg_field stat2;
    rand uvm_reg_field stat1;
    rand uvm_reg_field stat0;

    virtual function void build();
        reserved = uvm_reg_field::type_id::create("reserved");
        stat2 = uvm_reg_field::type_id::create("stat2");
        stat1 = uvm_reg_field::type_id::create("stat1");
        stat0 = uvm_reg_field::type_id::create("stat0");
        reserved.configure(this, 13, 3, "RO", 0, 13'h0, 1, 1, 0);
        stat2.configure(this, 1,2,"RO", 0, 1'h0, 1, 1, 0);
        stat1.configure(this, 1,1,"RO", 0, 1'h0, 1, 1, 0);
        stat0.configure(this, 1,0,"RO", 0, 1'h0, 1, 1, 0);
    endfunction

    `uvm_object_utils(reg_stat)
    function new(input string name = "reg_stat");
        super.new(name, 16, UVM_NO_COVERAGE);
    endfunction
endclass

class reg_model extends uvm_reg_block;
    rand reg_cfg cfg;
    rand reg_stat stat;
    virtual function void build();
        default_map = create_map("default_map",0,2,UVM_BIG_ENDIAN, 0);
        cfg = reg_cfg::type_id::create("cfg");
        cfg.configure(this,null,"cfg");
        cfg.build();
        default_map.add_reg(cfg,'h9,"RW");
        stat = reg_stat::type_id::create("stat");
        stat.configure(this,null,"stat");
        stat.build();
        default_map.add_reg(stat,'h8,"RO");
    endfunction
    `uvm_object_utils(reg_model)

    function new(input string name = "reg_model");
        super.new(name, UVM_NO_COVERAGE);
    endfunction
endclass
`endif

