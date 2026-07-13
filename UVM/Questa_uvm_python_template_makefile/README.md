这是一个基于windows Questa sim的UVM验证模板。使用DPI-C接口获取python建立的参考模型的参数输出，在UVM的scb中完成参数比对。本项目以8bit加法器为DUT提供参考模板

```
Questa_uvm_python_template _makefile
├── Python
│   ├── export_requirements.bat
│   ├── init_create_venv.bat
│   ├── install_requirements.bat
│   └── reference.py
├── UVM
│   ├── DPI-C
│   │   ├── inc
│   │   │   ├── pipe_py.h
│   │   │   └── read_json.h
│   │   ├── src
│   │   │   ├── pipe_py.c
│   │   │   └── read_json.c
│   │   ├── READNE.md
│   │   ├── config.json
│   │   ├── main.c
│   │   ├── main.exe
│   │   └── makefile
│   ├── rtl
│   │   └── dut.v
│   ├── sim
│   │   ├── file.f
│   │   ├── makefile
│   │   ├── modelsim.ini
│   │   └── vsim.wlf
│   └── tb
│       ├── common
│       │   ├── master_agent
│       │   │   ├── master_agent.sv
│       │   │   ├── master_agent_pkg.sv
│       │   │   ├── master_driver.sv
│       │   │   ├── master_interface.sv
│       │   │   ├── master_sequencer.sv
│       │   │   └── master_transaction.sv
│       │   └── slaver_agent
│       │       ├── slaver_agent.sv
│       │       ├── slaver_agent_pkg.sv
│       │       ├── slaver_interface.sv
│       │       ├── slaver_monitor.sv
│       │       └── slaver_transaction.sv
│       ├── env
│       │   ├── dpi_ref.sv
│       │   ├── env.sv
│       │   ├── env_pkg.sv
│       │   └── scb.sv
│       ├── tc
│       │   ├── base_test.sv
│       │   └── tc_pkg.sv
│       └── tb_top.sv
└── README.md
```

- Python/reference.py 8进制加法器的python参考模型描述
- UVM
  - DPI-C \ main.exe 通过读取config.json指定的python虚拟环境与参考模型python脚本
  - rtl \ dtu.v 8进制加法器的Verilog描述
  - sim
    - file.f uvm仿真环境路径
    - makefile 编译、启动、仿真脚本
  - tb
    - common
      - master_agent dut的输入端
      - slaver_agent 监视dut输出端
    - env 环境、scb比对、dpi-c接口
    - tc base_test 以及提供seq
    - tb_top.sv testbeach 顶层
