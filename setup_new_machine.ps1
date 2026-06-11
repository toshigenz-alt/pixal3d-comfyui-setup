# ============================================================
#  Pixal3D-ComfyUI : setup for a NEW machine (same spec)
#  วิธีใช้: copy ทั้งโฟลเดอร์ ComfyUI มาวางที่ไหนก็ได้ในเครื่องใหม่
#          แล้วคลิกขวาไฟล์ setup_new_machine.bat > Run
#  สคริปต์นี้: ตรวจ GPU, ติดตั้ง Git, ตั้ง env var, แล้วตรวจ Python env
# ============================================================
$ErrorActionPreference = "Continue"
$root = Split-Path $PSScriptRoot -Parent   # ComfyUI root (parent ของ Er)
$py = Join-Path $root "python_embeded\python.exe"
Write-Host "==== Pixal3D-ComfyUI setup ====" -ForegroundColor Cyan
Write-Host "ComfyUI root: $root"

# 1) ตรวจ python_embeded
if (-not (Test-Path $py)) {
    Write-Host "[X] ไม่พบ $py  -- วางสคริปต์ผิดที่หรือ copy ไม่ครบ" -ForegroundColor Red
    Read-Host "กด Enter เพื่อปิด"; exit 1
}

# 2) ตรวจ NVIDIA GPU
Write-Host "`n[1/4] ตรวจ NVIDIA GPU..." -ForegroundColor Yellow
try { & nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader } catch {
    Write-Host "[!] ไม่พบ nvidia-smi -- ติดตั้ง NVIDIA driver ล่าสุดก่อน (ต้องรองรับ CUDA 13)" -ForegroundColor Red
}

# 3) ตรวจ/ติดตั้ง Git (ComfyUI-Manager ต้องใช้)
Write-Host "`n[2/4] ตรวจ Git..." -ForegroundColor Yellow
$gitExe = $null
$cmd = Get-Command git -ErrorAction SilentlyContinue
if ($cmd) { $gitExe = $cmd.Source }
elseif (Test-Path "C:\Program Files\Git\cmd\git.exe") { $gitExe = "C:\Program Files\Git\cmd\git.exe" }
if (-not $gitExe) {
    Write-Host "    Git ยังไม่มี -- กำลังติดตั้งผ่าน winget..." -ForegroundColor Yellow
    winget install --id Git.Git -e --accept-source-agreements --accept-package-agreements --silent
    if (Test-Path "C:\Program Files\Git\cmd\git.exe") { $gitExe = "C:\Program Files\Git\cmd\git.exe" }
}
if ($gitExe) {
    Write-Host "    Git: $gitExe" -ForegroundColor Green
    # ตั้ง env var ให้ GitPython (ComfyUI-Manager) หา git เจอเสมอ
    [Environment]::SetEnvironmentVariable("GIT_PYTHON_GIT_EXECUTABLE", $gitExe, "User")
    Write-Host "    ตั้ง GIT_PYTHON_GIT_EXECUTABLE แล้ว" -ForegroundColor Green
} else {
    Write-Host "[!] ติดตั้ง Git ไม่สำเร็จ -- ComfyUI-Manager อาจโหลดไม่ได้ (แต่ Pixal3D ยังใช้ได้)" -ForegroundColor Red
}

# 4) ตรวจ Python env (torch / CUDA wheels / triton compile)
Write-Host "`n[3/4] ตรวจ Python environment (torch, CUDA wheels, triton)..." -ForegroundColor Yellow
& $py (Join-Path $PSScriptRoot "verify_env.py")

Write-Host "`n[4/4] เสร็จ!" -ForegroundColor Green
Write-Host "เปิดใช้งาน: ดับเบิลคลิก run_nvidia_gpu.bat แล้วเปิด http://127.0.0.1:8188" -ForegroundColor Cyan
Write-Host "(โมเดลทั้งหมดอยู่ใน models\ แล้ว ไม่ต้องโหลดใหม่)"
Read-Host "`nกด Enter เพื่อปิด"
