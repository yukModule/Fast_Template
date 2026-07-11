`ifndef BUS_AGENT_PKG__SV
`define BUS_AGENT_PKG__SV

package bus_agent_pkg;
   import uvm_pkg::*;
   `include "uvm_macros.svh"

   `include "bus_transaction.sv"
   `include "bus_sequencer.sv"
   `include "bus_driver.sv"
   `include "bus_agent.sv"
endpackage
`endif