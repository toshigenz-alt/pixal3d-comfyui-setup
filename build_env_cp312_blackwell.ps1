# =================================================================
#  สร้าง ComfyUI + Pixal3D env แบบ Python 3.12 (cp312) สำหรับ RTX 50xx (Blackwell sm_120)
#  + ลง NATTEN (libnatten) เพื่อใช้ strict NAF ได้
#
#  ใช้ venv Python 3.12 จริง (ไม่ใช่ embedded) -> triton compile ได้เลย ไม่ต้องเติม dev files
#  Stack: Python 3.12 + torch 2.10.0+cu130 + wheels cp312/cu130/torch2.10
#
#  วิธีใช้: ดับเบิลคลิก build_env_cp312_blackwell.bat (รันบนเครื่อง 5080)
#  พารามิเตอร์: -Target <โฟลเดอร์ปลายทาง>  (ดีฟอลต์ C:\ComfyUI_cp312)
# =================================================================
param(
    [string]$Target = "C:\ComfyUI_cp312"
)
$ErrorActionPreference = "Continue"

function Check([string]$name) {
    if ($LASTEXITCODE -ne 0) { Write-Host "[X] ขั้นตอน '$name' ล้มเหลว (exit $LASTEXITCODE)" -ForegroundColor Red; Read-Host "กด Enter เพื่อปิด"; exit 1 }
}

Write-Host "==== Build ComfyUI+Pixal3D cp312 (Blackwell/NAF) ====" -ForegroundColor Cyan
Write-Host "ปลายทาง: $Target`n"

# ---------- 0) เครื่องมือพื้นฐาน: git + Python 3.12 ----------
Write-Host "[0/8] ตรวจ git + Python 3.12..." -ForegroundColor Yellow
$git = (Get-Command git -ErrorAction SilentlyContinue).Source
if (-not $git -and (Test-Path "C:\Program Files\Git\cmd\git.exe")) { $git = "C:\Program Files\Git\cmd\git.exe" }
if (-not $git) {
    Write-Host "    ติดตั้ง Git..." -ForegroundColor Yellow
    winget install --id Git.Git -e --accept-source-agreements --accept-package-agreements --silent
    if (Test-Path "C:\Program Files\Git\cmd\git.exe") { $git = "C:\Program Files\Git\cmd\git.exe" }
}
$env:PATH = "$(Split-Path $git);" + $env:PATH

# หา python 3.12
function Find-Py312 {
    $cands = @(
        "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
        "C:\Python312\python.exe",
        "C:\Program Files\Python312\python.exe"
    )
    foreach ($c in $cands) { if (Test-Path $c) { return $c } }
    # ลอง py launcher
    try { $v = & py -3.12 -c "import sys;print(sys.executable)" 2>$null; if ($LASTEXITCODE -eq 0 -and $v) { return $v.Trim() } } catch {}
    return $null
}
$py312 = Find-Py312
if (-not $py312) {
    Write-Host "    ติดตั้ง Python 3.12 ผ่าน winget..." -ForegroundColor Yellow
    winget install --id Python.Python.3.12 -e --accept-source-agreements --accept-package-agreements --silent
    Start-Sleep -Seconds 3
    $py312 = Find-Py312
}
if (-not $py312) {
    Write-Host "[X] หา Python 3.12 ไม่เจอ -- เปิดสคริปต์นี้ใหม่อีกครั้ง (PATH เพิ่งอัปเดต) หรือ" -ForegroundColor Red
    Write-Host "    ติดตั้งเองจาก https://www.python.org/downloads/release (เลือก 3.12.x) แล้วรันใหม่" -ForegroundColor Red
    Read-Host "กด Enter เพื่อปิด"; exit 1
}
Write-Host "    Python 3.12: $py312" -ForegroundColor Green
Write-Host "    Git: $git" -ForegroundColor Green

# ---------- 1) clone ComfyUI ----------
Write-Host "`n[1/8] clone ComfyUI..." -ForegroundColor Yellow
if (-not (Test-Path "$Target\main.py")) {
    & $git clone https://github.com/comfyanonymous/ComfyUI "$Target"; Check "clone ComfyUI"
} else { Write-Host "    มี ComfyUI อยู่แล้ว ข้าม" }

# ---------- 2) สร้าง venv ----------
Write-Host "`n[2/8] สร้าง venv Python 3.12..." -ForegroundColor Yellow
$vpy = "$Target\venv\Scripts\python.exe"
if (-not (Test-Path $vpy)) { & $py312 -m venv "$Target\venv"; Check "create venv" }
& $vpy -m pip install --upgrade pip wheel setuptools | Out-Null

# ---------- 3) torch 2.10.0 + cu130 ----------
Write-Host "`n[3/8] ติดตั้ง torch 2.10.0+cu130 (ดาวน์โหลดใหญ่ ~2GB)..." -ForegroundColor Yellow
& $vpy -m pip install torch==2.10.0 torchvision==0.25.0 torchaudio==2.10.0 --index-url https://download.pytorch.org/whl/cu130; Check "install torch"

# ---------- 4) ComfyUI requirements ----------
Write-Host "`n[4/8] ติดตั้ง ComfyUI requirements..." -ForegroundColor Yellow
& $vpy -m pip install -r "$Target\requirements.txt"; Check "comfyui requirements"

# ---------- 5) clone custom nodes ----------
Write-Host "`n[5/8] clone ComfyUI-Manager + Pixal3D-ComfyUI..." -ForegroundColor Yellow
$cn = "$Target\custom_nodes"
if (-not (Test-Path "$cn\comfyui-manager")) { & $git clone https://github.com/Comfy-Org/ComfyUI-Manager "$cn\comfyui-manager" }
if (-not (Test-Path "$cn\Pixal3D-ComfyUI")) { & $git clone https://github.com/Saganaki22/Pixal3D-ComfyUI.git "$cn\Pixal3D-ComfyUI" }

# ---------- 6) NATTEN Blackwell ก่อน (เพื่อให้ requirements ไม่ build natten ใหม่) ----------
Write-Host "`n[6/8] ติดตั้ง NATTEN (libnatten) สำหรับ Blackwell -> เปิด strict NAF ได้..." -ForegroundColor Yellow
$natten = "https://huggingface.co/drbaph/NATTEN-0.21.6-torch2100cu130-cp312-cp312-win_amd64/resolve/main/NATTEN-0.21.6%2Btorch2100cu130-cp312-cp312-win_amd64.whl"
& $vpy -m pip install --no-deps $natten; Check "install NATTEN"

# ---------- 7) Pixal3D requirements + CUDA wheels (cp312) ----------
Write-Host "`n[7/8] ติดตั้ง Pixal3D requirements + CUDA wheels (cp312/cu130/torch2.10)..." -ForegroundColor Yellow
& $vpy -m pip install -r "$cn\Pixal3D-ComfyUI\requirements.txt"; Check "pixal3d requirements"
$base = "https://github.com/PozzettiAndrea/cuda-wheels/releases/download"
$wheels = @(
    "$base/flex_gemm_ap-latest/flex_gemm_ap-1.0.0%2Bcu130torch2.10-cp312-cp312-win_amd64.whl",
    "$base/cumesh_vb-latest/cumesh_vb-1.0%2Bcu130torch2.10-cp312-cp312-win_amd64.whl",
    "$base/o_voxel_vb_ap-latest/o_voxel_vb_ap-0.0.1%2Bcu130torch2.10-cp312-cp312-win_amd64.whl",
    "$base/drtk-latest/drtk-0.1.0%2Bcu130torch2.10-cp312-cp312-win_amd64.whl",
    "$base/flash_attn-latest/flash_attn-2.8.3%2Bcu130torch2.10-cp312-cp312-win_amd64.whl"
)
& $vpy -m pip install --no-deps @wheels; Check "cuda wheels"
& $vpy -m pip install zstandard "triton-windows<3.7"; Check "triton+zstandard"

# ---------- 8) ตั้ง env var git + เขียน run script + verify ----------
Write-Host "`n[8/8] ตั้งค่า + ตรวจ env..." -ForegroundColor Yellow
[Environment]::SetEnvironmentVariable("GIT_PYTHON_GIT_EXECUTABLE", $git, "User")

# run_comfyui_cp312.bat
$runbat = "$Target\run_comfyui_cp312.bat"
@"
@echo off
cd /d "%~dp0"
set GIT_PYTHON_GIT_EXECUTABLE=$git
"venv\Scripts\python.exe" main.py --disable-auto-launch
pause
"@ | Out-File -FilePath $runbat -Encoding ascii

# verify (ใช้ verify_env.py ที่อยู่ข้างๆ สคริปต์นี้ ถ้ามี)
$verify = Join-Path $PSScriptRoot "verify_env.py"
if (Test-Path $verify) { & $vpy $verify }
# เช็ก NATTEN libnatten แยก (จุดสำคัญของ NAF)
& $vpy -c "import natten; print('  natten:', natten.__version__, '| HAS_LIBNATTEN:', natten.HAS_LIBNATTEN)"

Write-Host "`n==== เสร็จ! ====" -ForegroundColor Green
Write-Host "เปิดใช้งาน: ดับเบิลคลิก $runbat -> http://127.0.0.1:8188" -ForegroundColor Cyan
Write-Host "โมเดล: ครั้งแรกจะ auto-download (~30GB) หรือ copy โฟลเดอร์ models\ จากเครื่อง 4090 มาวางที่ $Target\models\ ก็ได้ (โมเดลใช้ร่วมกันได้)" -ForegroundColor Cyan
Write-Host "NAF: ถ้า HAS_LIBNATTEN=True -> ตั้ง Model Loader naf_mode=strict ได้เลย" -ForegroundColor Cyan
Read-Host "`nกด Enter เพื่อปิด"
