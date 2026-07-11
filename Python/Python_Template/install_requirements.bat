@echo off
chcp 65001 >nul
echo 正在激活虚拟环境...

call .\.venv\Scripts\activate.bat
pip install -r requirement.txt

pause