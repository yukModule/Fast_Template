`ifndef DPI_REF__SV
`define DPI_REF__SV

// ============================================================================
// DPI-C function imports from dpi_wrapper.dll
// Bridges SystemVerilog testbench to Python reference model via C/DPI.
// ============================================================================

import "DPI-C" function void dpi_init();
import "DPI-C" function void dpi_compute(input int a, input int b, output int sum, output int cout);
import "DPI-C" function void dpi_close();

// ============================================================================
// dpi_ref_class: Simple (non-component) wrapper for DPI-C calls.
// Instantiated and used by the scoreboard.
// ============================================================================
class dpi_ref_class;

    function new();
    endfunction

    // Initialize Python reference model process
    function void init();
        $display("[DPI_REF] Initializing Python reference model...");
        dpi_init();
        $display("[DPI_REF] Initialization complete");
    endfunction

    // Compute reference result for 8-bit adder:
    //   a + b = {cout, sum}
    function void compute(
        input  bit [7:0] a,
        input  bit [7:0] b,
        output bit [7:0] sum,
        output bit       cout
    );
        int ia, ib, isum, icout;
        ia  = int'(a);
        ib  = int'(b);
        isum = 0;
        icout = 0;

        dpi_compute(ia, ib, isum, icout);

        sum  = isum[7:0];
        cout = |icout;
    endfunction

    // Shutdown Python reference model process
    function void close();
        $display("[DPI_REF] Shutting down Python reference model...");
        dpi_close();
        $display("[DPI_REF] Shutdown complete");
    endfunction

endclass

`endif
