# =================================================================
#  Build ComfyUI + Pixal3D env ใหม่จากศูนย์ สำหรับ RTX 4090/4080 (Ada sm_89)
#  Stack: ComfyUI portable, Python 3.13, torch 2.10.0+cu130, wheels cp313
#  ทำซ้ำสิ่งที่ทดสอบแล้วใช้ได้จริง: downgrade torch + 5 CUDA wheels + แก้ triton + ข้าม natten
#
#  วิธีใช้: ดับเบิลคลิก build_env_4090.bat (clone repo มาแล้วรันได้เลย ไม่ต้อง copy โฟลเดอร์ 35GB)
#  โมเดล ~30GB จะ auto-download ตอนรัน workflow ครั้งแรก
#  พารามิเตอร์: -Target (ดีฟอลต์ C:\ComfyUI)  -ComfyUIVersion (ดีฟอลต์ v0.24.0)
# =================================================================
param(
    [string]$Target = "C:\ComfyUI",
    [string]$ComfyUIVersion = "v0.24.0"
)
$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

function Check([string]$name) {
    if ($LASTEXITCODE -ne 0) { Write-Host "[X] '$name' ล้มเหลว (exit $LASTEXITCODE)" -ForegroundColor Red; Read-Host "กด Enter เพื่อปิด"; exit 1 }
}

Write-Host "==== Build ComfyUI+Pixal3D cp313 (RTX 4090/4080) ====" -ForegroundColor Cyan
Write-Host "ปลายทาง: $Target | ComfyUI $ComfyUIVersion`n"
if (Test-Path "$Target\python_embeded\python.exe") {
    Write-Host "[!] มี env อยู่แล้วที่ $Target -- ถ้าจะ build ใหม่ให้ลบหรือเปลี่ยน -Target" -ForegroundColor Yellow
    Read-Host "กด Enter เพื่อปิด"; exit 0
}

# ---------- 0) เครื่องมือ: git + 7-Zip ----------
Write-Host "[0/9] ตรวจ git + 7-Zip..." -ForegroundColor Yellow
$git = (Get-Command git -ErrorAction SilentlyContinue).Source
if (-not $git -and (Test-Path "C:\Program Files\Git\cmd\git.exe")) { $git = "C:\Program Files\Git\cmd\git.exe" }
if (-not $git) { winget install --id Git.Git -e --accept-source-agreements --accept-package-agreements --silent; if (Test-Path "C:\Program Files\Git\cmd\git.exe") { $git = "C:\Program Files\Git\cmd\git.exe" } }
$env:PATH = "$(Split-Path $git);" + $env:PATH
$sevenzip = "C:\Program Files\7-Zip\7z.exe"
if (-not (Test-Path $sevenzip)) { winget install --id 7zip.7zip -e --accept-source-agreements --accept-package-agreements --silent }
if (-not (Test-Path $sevenzip)) { Write-Host "[X] ไม่พบ 7-Zip" -ForegroundColor Red; Read-Host; exit 1 }
Write-Host "    git: $git`n    7zip: $sevenzip" -ForegroundColor Green

# ---------- 1) โหลด + แตก ComfyUI portable (nvidia) ----------
Write-Host "`n[1/9] ดาวน์โหลด ComfyUI portable (~2GB)..." -ForegroundColor Yellow
$url = "https://github.com/Comfy-Org/ComfyUI/releases/download/$ComfyUIVersion/ComfyUI_windows_portable_nvidia.7z"
$dl = "$env:TEMP\ComfyUI_portable.7z"
& curl.exe -L --fail -o $dl $url; Check "download ComfyUI"
Write-Host "    แตกไฟล์..." -ForegroundColor Yellow
$parent = Split-Path $Target -Parent
& $sevenzip x $dl "-o$parent" -y | Out-Null; Check "extract"
if (Test-Path "$parent\ComfyUI_windows_portable") { Move-Item "$parent\ComfyUI_windows_portable" $Target }
Remove-Item $dl -Force -ErrorAction SilentlyContinue
$py = "$Target\python_embeded\python.exe"
if (-not (Test-Path $py)) { Write-Host "[X] แตกไฟล์ผิดโครงสร้าง" -ForegroundColor Red; Read-Host; exit 1 }

# ---------- 2) downgrade torch -> 2.10.0+cu130 ----------
Write-Host "`n[2/9] ติดตั้ง torch 2.10.0+cu130 (ดาวน์โหลด ~2GB)..." -ForegroundColor Yellow
& $py -m pip install torch==2.10.0 torchvision==0.25.0 torchaudio==2.10.0 --index-url https://download.pytorch.org/whl/cu130; Check "torch 2.10"

# ---------- 3) clone custom nodes ----------
Write-Host "`n[3/9] clone ComfyUI-Manager + Pixal3D-ComfyUI..." -ForegroundColor Yellow
$cn = "$Target\ComfyUI\custom_nodes"
if (-not (Test-Path "$cn\comfyui-manager")) { & $git clone https://github.com/Comfy-Org/ComfyUI-Manager "$cn\comfyui-manager" }
if (-not (Test-Path "$cn\Pixal3D-ComfyUI")) { & $git clone https://github.com/Saganaki22/Pixal3D-ComfyUI.git "$cn\Pixal3D-ComfyUI" }

# ---------- 4) Pixal3D requirements (ตัด natten ออก -- sm_89 ไม่มี wheel) ----------
Write-Host "`n[4/9] ติดตั้ง Pixal3D requirements (ข้าม natten)..." -ForegroundColor Yellow
$reqSrc = "$cn\Pixal3D-ComfyUI\requirements.txt"
$reqTmp = "$Target\_req_no_natten.txt"
Get-Content $reqSrc | Where-Object { $_ -notmatch '^\s*natten' } | Set-Content $reqTmp -Encoding UTF8
& $py -m pip install -r $reqTmp; Check "pixal3d requirements"

# ---------- 5) CUDA wheels cp313/cu130/torch2.10 ----------
Write-Host "`n[5/9] ติดตั้ง 5 CUDA wheels (cp313)..." -ForegroundColor Yellow
$base = "https://github.com/PozzettiAndrea/cuda-wheels/releases/download"
$wheels = @(
    "$base/flex_gemm_ap-latest/flex_gemm_ap-1.0.0%2Bcu130torch2.10-cp313-cp313-win_amd64.whl",
    "$base/cumesh_vb-latest/cumesh_vb-1.0%2Bcu130torch2.10-cp313-cp313-win_amd64.whl",
    "$base/o_voxel_vb_ap-latest/o_voxel_vb_ap-0.0.1%2Bcu130torch2.10-cp313-cp313-win_amd64.whl",
    "$base/drtk-latest/drtk-0.1.0%2Bcu130torch2.10-cp313-cp313-win_amd64.whl",
    "$base/flash_attn-latest/flash_attn-2.8.3%2Bcu130torch2.10-cp313-cp313-win_amd64.whl"
)
& $py -m pip install --no-deps @wheels; Check "cuda wheels"
& $py -m pip install zstandard "triton-windows<3.7"; Check "triton+zstandard"

# ---------- 6) แก้ triton: เติม Python dev files ที่ portable ไม่มี ----------
Write-Host "`n[6/9] เติม Python dev files (Python.h + python313.lib) ให้ triton compile ได้..." -ForegroundColor Yellow
if (-not (Test-Path "$Target\python_embeded\libs\python313.lib")) {
    $nz = "$env:TEMP\python_nuget.zip"; $nx = "$env:TEMP\python_nuget_x"
    Invoke-WebRequest -Uri "https://www.nuget.org/api/v2/package/python/3.13.12" -OutFile $nz -UseBasicParsing
    if (Test-Path $nx) { Remove-Item $nx -Recurse -Force }
    Expand-Archive -Path $nz -DestinationPath $nx -Force
    New-Item -ItemType Directory -Force -Path "$Target\python_embeded\include","$Target\python_embeded\libs" | Out-Null
    Copy-Item "$nx\tools\include\*" "$Target\python_embeded\include\" -Recurse -Force
    Copy-Item "$nx\tools\libs\python313.lib" "$Target\python_embeded\libs\python313.lib" -Force
    Remove-Item $nz,$nx -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "    เติม dev files แล้ว" -ForegroundColor Green
} else { Write-Host "    มีอยู่แล้ว ข้าม" }

# ---------- 7) ตั้ง env var git ----------
Write-Host "`n[7/9] ตั้ง GIT_PYTHON_GIT_EXECUTABLE..." -ForegroundColor Yellow
[Environment]::SetEnvironmentVariable("GIT_PYTHON_GIT_EXECUTABLE", $git, "User")

# ---------- 8) verify ----------
Write-Host "`n[8/9] ตรวจ env..." -ForegroundColor Yellow
$verify = Join-Path $PSScriptRoot "verify_env.py"
if (Test-Path $verify) { & $py $verify } else {
    & $py -c "import torch,importlib.util as u; print(' torch',torch.__version__,'cuda',torch.cuda.is_available()); print(' wheels missing:', [m for m in ['flash_attn','flex_gemm_ap','cumesh_vb','o_voxel_vb_ap','drtk','triton'] if u.find_spec(m) is None] or 'none')"
}

# ---------- 9) เสร็จ ----------
Write-Host "`n[9/9] เสร็จ!" -ForegroundColor Green
Write-Host "เปิดใช้งาน: ดับเบิลคลิก $Target\run_nvidia_gpu.bat -> http://127.0.0.1:8188" -ForegroundColor Cyan
Write-Host "โหลด workflow จาก ComfyUI\custom_nodes\Pixal3D-ComfyUI\example_workflows\" -ForegroundColor Cyan
Write-Host "ครั้งแรกโมเดล ~30GB จะ auto-download (ตั้ง download_if_missing=true ใน Model Loader)" -ForegroundColor Cyan
Write-Host "NAF: sm_89 ไม่มี NATTEN -> ใช้ naf_mode=fallback_if_missing (ค่ามาตรฐาน)" -ForegroundColor Cyan
Read-Host "`nกด Enter เพื่อปิด"
