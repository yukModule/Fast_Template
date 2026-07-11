// 1. UVM 基础
+incdir+C:/Tool/QuestaSim/verilog_src/uvm-1.1d/src
C:/Tool/QuestaSim/verilog_src/uvm-1.1d/src/uvm_pkg.sv

// 2. DUT
../rtl/dut.v

// 3. 接口 (Interfaces)
../tb/common/master_agent/master_interface.sv
../tb/common/slaver_agent/slaver_interface.sv
../tb/common/bus_agent/bus_if.sv

// 4. 各类组件包 (Packages)
../tb/common/master_agent/master_agent_pkg.sv
../tb/common/slaver_agent/slaver_agent_pkg.sv
../tb/common/bus_agent/bus_agent_pkg.sv
../tb/env/env_pkg.sv

// 5. 测试用例包 (包含 base_test.sv)
../tb/tc/tc_pkg.sv

// 6. 顶层文件
../tb/tb_top.sv