// file.f - VCS compile file list

// Include directories
+incdir+../tb/common/master_agent/
+incdir+../tb/common/slaver_agent/
+incdir+../tb/common/bus_agent/
+incdir+../tb/env/
+incdir+../tb/tc/

// Design files
../rtl/dut.v

// Interfaces
../tb/common/master_agent/master_interface.sv
../tb/common/slaver_agent/slaver_interface.sv
../tb/common/bus_agent/bus_if.sv

// Agent packages
../tb/common/master_agent/master_agent_pkg.sv
../tb/common/slaver_agent/slaver_agent_pkg.sv
../tb/common/bus_agent/bus_agent_pkg.sv

// Environment package
../tb/env/env_pkg.sv

// Test package
../tb/tc/tc_pkg.sv

// Testbench top
../tb/tb_top.sv
