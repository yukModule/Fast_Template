`ifndef SCB__SV
`define SCB__SV

// ============================================================================
// adder_scb: Scoreboard for 8-bit adder verification.
// Compares DUT output (from slaver_monitor) against Python reference model
// (via DPI-C) for each input transaction.
//
// Architecture:
//   - Receives input transactions (a,b) from master_driver via TLM analysis
//   - Computes expected {sum,cout} via DPI-C Python reference
//   - Queues expected result (handles 1-cycle DUT pipeline delay)
//   - Receives output transactions (sum,cout) from slaver_monitor
//   - Dequeues and compares
// ============================================================================

class adder_scb extends uvm_scoreboard;

    `uvm_component_utils(adder_scb)

    // TLM analysis exports
    uvm_analysis_export #(master_transaction) mst_export;
    uvm_analysis_export #(slaver_transaction) slv_export;

    // Internal FIFOs
    uvm_tlm_analysis_fifo #(master_transaction) mst_fifo;
    uvm_tlm_analysis_fifo #(slaver_transaction) slv_fifo;

    // DPI-C reference model wrapper
    dpi_ref_class ref_model;

    // Expected result queues (for pipeline delay matching)
    bit [7:0] exp_sum_q[$];
    bit       exp_cout_q[$];

    // Statistics
    int cmp_cnt;
    int err_cnt;
    int match_cnt;

    function new(string name = "adder_scb", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Create analysis ports and FIFOs
        mst_export = new("mst_export", this);
        slv_export = new("slv_export", this);
        mst_fifo   = new("mst_fifo", this);
        slv_fifo   = new("slv_fifo", this);

        // Create and initialize DPI reference model
        ref_model  = new();
        ref_model.init();
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // Connect analysis exports to internal FIFOs
        mst_export.connect(mst_fifo.analysis_export);
        slv_export.connect(slv_fifo.analysis_export);
    endfunction

    virtual task run_phase(uvm_phase phase);
        master_transaction mst_tr;
        slaver_transaction slv_tr;

        `uvm_info(get_type_name(), "Scoreboard run_phase started", UVM_LOW)

        forever begin
            fork
                // Thread 1: Process input transactions (master side)
                begin
                    forever begin
                        mst_fifo.get(mst_tr);
                        process_master_transaction(mst_tr);
                    end
                end

                // Thread 2: Process output transactions (slave side)
                begin
                    forever begin
                        slv_fifo.get(slv_tr);
                        process_slaver_transaction(slv_tr);
                    end
                end
            join
        end
    endtask

    // ========================================================================
    // Compute expected result from input and queue for later comparison
    // ========================================================================
    function void process_master_transaction(master_transaction tr);
        bit [7:0] exp_sum;
        bit       exp_cout;

        // Always compute reference: DUT adds a+b every cycle regardless of vld.
        // The driver ensures back-to-back transactions so the pipeline stays aligned.
        ref_model.compute(tr.data_in0, tr.data_in1, exp_sum, exp_cout);

        // Queue the expected result (DUT has 1-cycle pipeline delay)
        exp_sum_q.push_back(exp_sum);
        exp_cout_q.push_back(exp_cout);

        `uvm_info(get_type_name(),
            $sformatf("REF:  a=%3d, b=%3d -> exp_sum=%3d, exp_cout=%b  [queue=%0d]",
                tr.data_in0, tr.data_in1, exp_sum, exp_cout, exp_sum_q.size()),
            UVM_MEDIUM)
    endfunction

    // ========================================================================
    // Compare DUT output with expected reference
    // ========================================================================
    function void process_slaver_transaction(slaver_transaction tr);
        // Wait until pipeline is primed: DUT + clocking block = 2-cycle delay.
        // Skip the first output (queue size 1) to align REF with DUT output.
        if (exp_sum_q.size() > 1) begin
            bit [7:0] exp_sum;
            bit       exp_cout;

            exp_sum  = exp_sum_q.pop_front();
            exp_cout = exp_cout_q.pop_front();
            cmp_cnt++;

            if (exp_sum != tr.data_out || exp_cout != tr.cout) begin
                err_cnt++;
                `uvm_error(get_type_name(),
                    $sformatf("MISMATCH [%0d]: a+b expected sum=%3d cout=%b, DUT sum=%3d cout=%b",
                        cmp_cnt, exp_sum, exp_cout, tr.data_out, tr.cout))
            end
            else begin
                match_cnt++;
                `uvm_info(get_type_name(),
                    $sformatf("MATCH [%0d]: sum=%3d cout=%b", cmp_cnt, exp_sum, exp_cout),
                    UVM_MEDIUM)
            end
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        $display("----------------------------------------");
        $display("[SCB] Scoreboard Report");
        $display("[SCB]   Comparisons : %0d", cmp_cnt);
        $display("[SCB]   Matches     : %0d", match_cnt);
        $display("[SCB]   Errors      : %0d", err_cnt);
        $display("----------------------------------------");

        // Shutdown Python reference model
        ref_model.close();
    endfunction

endclass

`endif
