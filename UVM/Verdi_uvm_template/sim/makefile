#============================================
# Makefile for 8-bit Adder (VCS + Verdi + UVM)
# Ubuntu 20.04 自动适配版
#============================================

#============================================
# 环境配置
#============================================
VCS_HOME      = /home/mkm/vcs/vcs2018/vcs/O-2018.09-SP2
VERDI_HOME    = /home/mkm/vcs/verdi/verdi/Verdi_O-2018.09-SP2
UVM_HOME      = $(VCS_HOME)/etc/uvm
UVM_VERDI_HOME = $(VCS_HOME)/etc/uvm-1.2

#============================================
# 项目配置
#============================================
DESIGN_TOP    = tb_top
FSDB_FILE     = novas.fsdb
VCS_ARCH      = -full64
VCS_DEBUG     = -debug_access+all -kdb
SIMV_DAIDIR   = simv.daidir
UVM_VERDI_TRACE = UVM_AWARE+RAL+HIER+COMPWAVE
UVM_SIM_OPTS    = +UVM_VERDI_TRACE=$(UVM_VERDI_TRACE) \
                  +UVM_TR_RECORD \
                  +UVM_LOG_RECORD

# 文件列表
FILELIST      = file.f

# 仿真选项
SIMV_OPTS     = -l run.log \
				-gui=verdi
SIMV_UVM_OPTS = $(SIMV_OPTS) $(UVM_SIM_OPTS)

# 包含目录
INCDIRS       = +incdir+../tb/common/master_agent/ \
                +incdir+../tb/common/slaver_agent/ \
                +incdir+../tb/common/bus_agent/ \
                +incdir+../tb/env/ \
                +incdir+../tb/tc/ \
                +incdir+$(UVM_HOME)/src/

#============================================
# VCS编译选项
#============================================
# UVM相关选项
UVM_OPTS      = -ntb_opts uvm-1.2

# 编译选项
VCS_OPTS      = $(UVM_OPTS) \
                -f $(FILELIST) \
                $(INCDIRS) \
                -sverilog \
                $(VCS_ARCH) \
                $(VCS_DEBUG) \
                -l compile.log \
                -timescale=1ns/1ps \
                -override_timescale=1ns/1ps \
                -debug_all \
				+define+UVM_VERDI_COMPWAVE

#============================================
# Verdi选项（修正：添加UVM支持）
#============================================
VERDI_CMD     = $(VERDI_HOME)/bin/verdi
VERDI_WAVE_OPTS = -f $(FILELIST) \
                $(INCDIRS) \
                -ssf $(FSDB_FILE) \
                -top $(DESIGN_TOP) \
                -nologo \
                -sv \
                -uvm \
                -uvmhome $(UVM_VERDI_HOME)

VERDI_UVM_OPTS = $(VERDI_WAVE_OPTS) \
                -dbdir $(SIMV_DAIDIR)

#============================================
# 目标定义
#============================================

# 默认目标
all: clean compile simulate_uvm verdi

# 检查环境
check_env:
	@echo "========================================="
	@echo "  Environment Check"
	@echo "========================================="
	@echo "VCS_HOME:   $(VCS_HOME)"
	@echo "VERDI_HOME: $(VERDI_HOME)"
	@echo "UVM_HOME:   $(UVM_HOME)"
	@echo "GCC:        $$(gcc --version | head -1)"
	@echo "========================================="

# 编译
compile: check_env
	@echo "========================================="
	@echo "  Compiling with UVM Support..."
	@echo "========================================="
	vcs $(VCS_OPTS)
	@if [ $$? -eq 0 ]; then \
		echo "✅ Compilation SUCCESS!"; \
	else \
		echo "❌ Compilation FAILED!"; \
		echo "Check compile.log for details"; \
		exit 1; \
	fi

# 仿真（UVM模式）
simulate: compile
	@echo "========================================="
	@echo "  Running UVM Simulation..."
	@echo "========================================="
	./simv $(SIMV_OPTS) +UVM_TESTNAME=base_test
	@if [ $$? -eq 0 ]; then \
		echo "✅ Simulation SUCCESS!"; \
		echo "📊 Waveform saved to $(FSDB_FILE)"; \
	else \
		echo "❌ Simulation FAILED!"; \
		echo "Check run.log for details"; \
		exit 1; \
	fi

simulate_uvm: compile
	@echo "========================================="
	@echo "  Running UVM Simulation with Verdi Debug..."
	@echo "========================================="
	./simv $(SIMV_UVM_OPTS) +UVM_TESTNAME=base_test
	@if [ $$? -eq 0 ]; then \
		echo "鉁?UVM debug simulation SUCCESS!"; \
		echo "馃搳 Waveform saved to $(FSDB_FILE)"; \
	else \
		echo "鉂?UVM debug simulation FAILED!"; \
		echo "Check run.log for details"; \
		exit 1; \
	fi

# 运行指定测试用例
test_%: compile
	@echo "========================================="
	@echo "  Running UVM Test: $*"
	@echo "========================================="
	./simv $(SIMV_OPTS) +UVM_TESTNAME=$*
	@if [ $$? -eq 0 ]; then \
		echo "✅ Test $* PASSED!"; \
	else \
		echo "❌ Test $* FAILED!"; \
		exit 1; \
	fi

# 打开Verdi查看波形
verdi:
	@echo "========================================="
	@echo "  Opening Verdi..."
	@echo "========================================="
	@if [ -f $(FSDB_FILE) ]; then \
		$(VERDI_CMD) $(VERDI_WAVE_OPTS) & \
		echo "✅ Verdi opened!"; \
	else \
		echo "❌ Waveform file $(FSDB_FILE) not found!"; \
		echo "Please run 'make simulate' first"; \
		exit 1; \
	fi

# 仅查看波形（不加载设计）
verdi_uvm:
	@echo "========================================="
	@echo "  Opening Verdi with UVM Debug..."
	@echo "========================================="
	@if [ ! -f $(FSDB_FILE) ]; then \
		echo "鉂?Waveform file $(FSDB_FILE) not found!"; \
		echo "Please run 'make simulate' first"; \
		exit 1; \
	fi
	@if [ ! -d $(SIMV_DAIDIR) ]; then \
		echo "鉂?$(SIMV_DAIDIR) not found!"; \
		echo "Please run 'make clean && make simulate' first"; \
		exit 1; \
	fi
	$(VERDI_CMD) $(VERDI_UVM_OPTS) &
	@echo "鉁?Verdi UVM debug opened!"

view:
	@if [ -f $(FSDB_FILE) ]; then \
		$(VERDI_CMD) $(VERDI_WAVE_OPTS) & \
	else \
		echo "❌ Waveform file $(FSDB_FILE) not found!"; \
		exit 1; \
	fi

# 清理
clean:
	@echo "========================================="
	@echo "  Cleaning up..."
	@echo "========================================="
	rm -rf csrc simv* *.log *.fsdb *.key verdi_log *.vpd *.conf DVEfiles ucli.key
	rm -rf verdiLog
	@echo "✅ Cleanup complete!"

# 深度清理
distclean: clean
	rm -rf *.vdb *.bak *.syn *.sdf *~
	@echo "✅ Deep clean complete!"

# 快速编译（不清理）
quick: compile simulate

# 帮助信息
help:
	@echo "========================================="
	@echo "  Makefile Targets (VCS + UVM + Verdi)"
	@echo "========================================="
	@echo "  all           : Clean + Compile + Simulate + Verdi"
	@echo "  compile       : Compile with UVM support"
	@echo "  simulate      : Run simulation (base_test)"
	@echo "  test_<name>   : Run specific UVM test"
	@echo "  verdi         : Open Verdi with waveform"
	@echo "  simulate_uvm  : Run simulation with Verdi UVM debug trace"
	@echo "  verdi_uvm     : Open Verdi with UVM debug database"
	@echo "  view          : Open Verdi (waveform only)"
	@echo "  clean         : Remove generated files"
	@echo "  distclean     : Remove all generated files"
	@echo "  quick         : Compile and simulate (no clean)"
	@echo "  help          : Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make all              # Full flow"
	@echo "  make test_base_test   # Run base_test"
	@echo "  make test_add_test    # Run add_test"
	@echo "========================================="

.PHONY: all compile simulate simulate_uvm verdi verdi_uvm clean distclean quick view help check_env test_%
