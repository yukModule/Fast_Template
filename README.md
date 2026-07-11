# Fast Template

> 快速模板：规范地快速搭建初始项目

- 规范的项目结构既是好习惯也便于后期维护、交付、他人学习。结合本人项目开发经验总结和收集一些便于快速开发的项目模板
- 有关makefile\bat\sh等编译或运行的项目,请确认该文件中的某些环境路径
- 部分复杂或关联其他开发程序的才会在README中详细描述(如PetaLinux)
- ⚠️部分项目使用过AI辅助

---

## 模板包括: 

### Python

- Python_Template 创建虚拟环境导入导出requirement
- [Pyinstaller_Template](https://github.com/yukModule/Pyinstaller_Template) 将python成像打包成可执行文件


### C / C++

- c_makefile_template windows环境下的C编译
- cpp_makefile_template windows环境下的C++编译


### MCU

- esp-idf_ESP32S3_N16R8_template 使用ESP-IDF开发ESP32S3


### FPGA

- PetaLinux_template 适用ZYNQ系列的PetaLinux项目搭建
- Xilinx_FPGA_template 适用在vscode上Vitis裸机开发,相关库的引用

### UVM

- Questa_uvm_template _makefile 在windows环境下使用makefile进行Questa的UVM编译与仿真
- Questa_uvm_template_bat 在windows环境下使用bat进行Questa的UVM编译与仿真
- Verdi_uvm_template 在Linux环境下使用makefile进行VCS+Verdi的UVM编译与仿真