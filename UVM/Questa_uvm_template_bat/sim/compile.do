quit -sim

# 1. 定义 UVM 源码路径变量 (方便后续维护)
set UVM_HOME "C:/Tool/QuestaSim/verilog_src/uvm-1.1d/src"

if {![file exists ../opt]} {
    file mkdir ../opt
}

if {[file exists work]} {
    vdel -all
}

vlib work
vmap work work

# 2. 在 vlog 命令中加入 +incdir+ 路径
# 注意：我们也加入了 +define+UVM_NO_DPI 以防某些版本 Questa 报 DPI 链接错误
vlog -reportprogress 300 -incr -sv -work work \
+incdir+$UVM_HOME \
-f filelist.f \
-l ../opt/compile.log