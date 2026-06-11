@echo off
REM ===== Build ComfyUI+Pixal3D env new for RTX 4090/4080 (cp313) =====
REM Double-click. Clones repo recipe -> builds a fresh working ComfyUI.
REM No need to copy the 35GB folder. Models (~30GB) auto-download on first run.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build_env_4090.ps1" -Target "C:\ComfyUI"
pause
