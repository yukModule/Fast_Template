vopt +acc=npr work.harness -o top -L work
vsim -do "add wave -position insertpoint sim:/harness/u_dut/*" -sv_lib C:/Tool/QuestaSim/uvm-1.1d/win64/uvm_dpi -lib work top -l ../opt/simulate.log

set NumberiscStdNoWarnings 1
set StdArithNoWarnings 1

run -all