`ifndef TC_PKG__SV
`define TC_PKG__SV

package tc_pkg;
    // 1. Import UVM and agent packages
    import uvm_pkg::*;
    import master_agent_pkg::*;
    import slaver_agent_pkg::*;
    import env_pkg::*;

    // 2. Include UVM macros
    `include "uvm_macros.svh"

    // 3. Include test cases
    `include "base_test.sv"

endpackage
`endif
