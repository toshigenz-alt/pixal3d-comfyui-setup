@echo off
REM ===== สร้าง ComfyUI+Pixal3D env Python 3.12 สำหรับ RTX 50xx (Blackwell) + NAF =====
REM ดับเบิลคลิกบนเครื่อง 5080  (จะ build ใหม่ทั้งหมด ใช้เน็ต+เวลาพอควร)
REM เปลี่ยนโฟลเดอร์ปลายทางได้ที่ -Target ด้านล่าง
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build_env_cp312_blackwell.ps1" -Target "C:\ComfyUI_cp312"
pause
