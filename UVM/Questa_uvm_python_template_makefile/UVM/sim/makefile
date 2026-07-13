WORK      = work
OUTPUT    = ../opt
UVM_HOME  = C:/Tool/QuestaSim/verilog_src/uvm-1.1d/src
UVM_DPI   = C:/Tool/QuestaSim/uvm-1.1d/win64/uvm_dpi
DPI_LIB   = ../DPI-C/dpi_wrapper

TESTNAME  = base_test
TB_HOME   = ../tb
INC_VLOG  = +incdir+$(UVM_HOME) \
            +incdir+$(TB_HOME)/env \
            +incdir+$(TB_HOME)/tc \
            +incdir+$(TB_HOME)/common

VLOG_OPT  = -incr -sv -work $(WORK) $(INC_VLOG) -l $(OUTPUT)/compile.log
# +acc prevents signals from being optimized away (needed for waveform visibility)
VOPT_OPT  = +acc -L $(WORK) -work $(WORK)
# Load both UVM DPI library and our custom DPI wrapper for Python reference model
VSIM_OPT  = -lib $(WORK) -l $(OUTPUT)/sim.log \
            +UVM_TESTNAME=$(TESTNAME) \
            -sv_lib $(UVM_DPI) \
            -sv_lib $(DPI_LIB)

WAVE_CMD  = -do "add wave -r /tb_top/*; run -all; wave zoom full;"

.PHONY: lib vlog compile test clean dpi

# Build the DPI-C wrapper DLL first
dpi:
	@echo "=== Building DPI-C wrapper DLL ==="
	$(MAKE) -C ../DPI-C all
	@echo "=== DPI-C DLL build complete ==="

lib:
	if not exist $(WORK) vlib $(WORK)
	vmap work $(WORK)
	if not exist $(OUTPUT) mkdir $(OUTPUT)
	
vlog: lib
	vlog $(VLOG_OPT) -f file.f

compile: vlog

test: dpi compile
	vopt $(VOPT_OPT) $(WORK).tb_top -o top_opt
	vsim $(VSIM_OPT) $(WAVE_CMD) top_opt

# Run simulation without rebuilding DPI DLL
rerun: compile
	vopt $(VOPT_OPT) $(WORK).tb_top -o top_opt
	vsim $(VSIM_OPT) $(WAVE_CMD) top_opt

clean:
	@del /q /s "$(WORK)" "$(OUTPUT)" "wlft*" "*.wlf"
	@echo "Clean complete."
