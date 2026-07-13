`ifndef ENV_PKG_SV
`define ENV_PKG_SV

package env_pkg;
    // 1. Import packages (must be before `include macros)
    import uvm_pkg::*;
    import master_agent_pkg::*;
    import slaver_agent_pkg::*;

    // 2. Include UVM macros (must be before class definitions)
    `include "uvm_macros.svh"

    // 3. Include environment components
    `include "dpi_ref.sv"    // DPI-C wrapper: dpi_ref_class
    `include "scb.sv"        // Scoreboard: adder_scb
    `include "env.sv"        // Environment: tran_env

endpackage
`endif
