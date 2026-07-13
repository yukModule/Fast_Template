`ifndef SLAVER_AGENT_PKG__SV
`define SLAVER_AGENT_PKG__SV
package slaver_agent_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "slaver_transaction.sv"
    `include "slaver_monitor.sv"
    `include "slaver_agent.sv"
endpackage
`endif