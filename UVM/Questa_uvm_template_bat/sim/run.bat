@echo off

set "WORK_HOME=%~dp0.."
set bin_path=C:/Tool/QuestaSim/win64
call %bin_path%/vsim -do "do {run.do}"
if "errerlevel%" == "1" goto END
if "errerlevel%" == "0" goto SUCCESS
:END
exit 1
:SUCCESS
exit 0