@echo off
chcp 65001 >nul
echo 正在激活虚拟环境并导出依赖包列表...

call .\.venv\Scripts\activate.bat
pip list --format=freeze > requirements.txt

echo 导出完成！已保存到 requirements.txt
pause