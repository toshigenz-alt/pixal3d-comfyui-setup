@echo off
REM ดับเบิลคลิกไฟล์นี้บนเครื่องใหม่ (หลัง copy โฟลเดอร์ ComfyUI มาแล้ว)
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_new_machine.ps1"
pause
