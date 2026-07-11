WORK      = work
OUTPUT    = ../opt
UVM_HOME  = C:/Tool/QuestaSim/verilog_src/uvm-1.1d/src
UVM_DPI   = C:/Tool/QuestaSim/uvm-1.1d/win64/uvm_dpi

TESTNAME  = base_test
TB_HOME   = ../tb
INC_VLOG  = +incdir+$(UVM_HOME) \
            +incdir+$(TB_HOME)/env \
            +incdir+$(TB_HOME)/tc \
            +incdir+$(TB_HOME)/common

VLOG_OPT  = -incr -sv -work $(WORK) $(INC_VLOG) -l $(OUTPUT)/compile.log
# 改为 +acc 以免信号被优化导致波形无数据
VOPT_OPT  = +acc -L $(WORK) -work $(WORK)
# 修正后的仿真选项，确保 -sv_lib 被加载
VSIM_OPT  = -lib $(WORK) -l $(OUTPUT)/sim.log \
            +UVM_TESTNAME=$(TESTNAME) \
            -sv_lib $(UVM_DPI)

WAVE_CMD  = -do "add wave -r /tb_top/*; run -all; wave zoom full;"

.PHONY: lib vlog compile test clean

lib:
	if not exist $(WORK) vlib $(WORK)
	vmap work $(WORK)
	if not exist $(OUTPUT) mkdir $(OUTPUT)

vlog: lib
	vlog $(VLOG_OPT) -f file.f

compile: vlog

test: compile
	vopt $(VOPT_OPT) $(WORK).tb_top -o top_opt
	vsim $(VSIM_OPT) $(WAVE_CMD) top_opt

clean:
	if exist $(WORK) rd /s/q $(WORK)
	if exist $(OUTPUT) rd /s/q $(OUTPUT)
	if exist *.wlf del *.wlf