`ifndef ENV_PKG_SV
`define ENV_PKG_SV

package env_pkg;
    // 1. 先导入 package（必须在 `include 宏之前！）
    import uvm_pkg::*;
    import master_agent_pkg::*;
    import slaver_agent_pkg::*;
    import bus_agent_pkg::*;
    
    // 2. 再包含 UVM 宏（必须在 class 定义之前！）
    `include "uvm_macros.svh"
    
    // 3. 包含环境组件（这些文件里不要再有 import 和宏！）
    `include "tran_rm.sv"
    `include "tran_scb.sv"
    `include "reg_model.sv"
    `include "bus_adapter.sv"
    `include "tran_env.sv"
    
endpackage
`endif