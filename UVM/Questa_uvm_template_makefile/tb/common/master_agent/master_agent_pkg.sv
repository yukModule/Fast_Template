
`ifndef MASTER_AGENT_PKG__SV
`define MASTER_AGENT_PKG__SV


package master_agent_pkg;
   import uvm_pkg::*;
   `include "uvm_macros.svh"

   `include "master_transaction.sv"
   `include "master_sequencer.sv"
   `include "master_driver.sv"
   `include "master_agent.sv"
endpackage
`endif