`ifndef TC_PKG__SV
`define TC_PKG__SV

package tc_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    // 导入环境和所有的 transaction 定义
    import master_agent_pkg::*;
    import slaver_agent_pkg::*;
    import bus_agent_pkg::*;
    import env_pkg::*;

    // 包含测试用例源代码
    `include "base_test.sv"
endpackage
`endif