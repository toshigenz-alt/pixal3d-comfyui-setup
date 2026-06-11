# Pixal3D-ComfyUI — Setup & Migration Scripts

> Reproducible Windows setup scripts for Pixal3D-ComfyUI (image-to-3D) — RTX 4090/4080 working stack + RTX 50xx Blackwell builder. Torch 2.10+cu130, prebuilt CUDA wheels, no manual compiling.

สคริปต์/คู่มือสำหรับติดตั้ง **Pixal3D-ComfyUI** (image-to-3D ของ TencentARC บน ComfyUI) ที่ทดสอบใช้งานได้จริงบน **RTX 4090 / Windows 11**

> repo นี้เก็บแค่ "สูตรติดตั้ง" — **ไม่มีโมเดลหรือ binary** (โมเดล ~30GB โหลดจาก Hugging Face เอง หรือ copy ผ่าน SSD)

## Stack ที่ใช้งานได้
- Windows 11 + NVIDIA RTX 4090/4080 (Ada, sm_89)
- ComfyUI portable, **Python 3.13.12**, **torch 2.10.0+cu130**
- CUDA wheels (cp313/cu130/torch2.10): `flex_gemm_ap`, `cumesh_vb`, `o_voxel_vb_ap`, `drtk`, `flash_attn` + `triton-windows`, `zstandard`
- NATTEN ข้าม (ไม่มี wheel sm_89) → ใช้ `naf_mode=fallback_if_missing`

## ไฟล์ในนี้
| ไฟล์ | ใช้ทำอะไร |
|---|---|
| `build_env_4090.ps1` + `*.bat` | **build ใหม่จากศูนย์** สำหรับ **RTX 4090/4080 (cp313)** — clone repo แล้วรันได้เลย **ไม่ต้อง copy 35GB** (โหลด ComfyUI portable + ลงทุกอย่าง, โมเดล auto-download) |
| `setup_new_machine.ps1` + `*.bat` | ย้ายไปเครื่อง **สเปคเดียวกัน (4090/4080)** — รันหลัง copy โฟลเดอร์ ComfyUI มา (ติดตั้ง Git + ตั้ง env + verify) |
| `verify_env.py` | ตรวจ torch / CUDA wheels / triton compile |
| `build_env_cp312_blackwell.ps1` + `*.bat` | **build ใหม่** สำหรับ **RTX 50xx (Blackwell)** เป็น Python 3.12 + NATTEN → ใช้ **strict NAF** ได้ |
| `env_lock_requirements.txt` | pip freeze ของ env ที่ทำงานได้ (170 แพ็กเกจ) |
| `submit_pixal3d_test.py` | ทดสอบรัน workflow ผ่าน API ให้ได้ `.glb` |
| `INSTALL_NOTES.md` | คู่มือเต็ม + ค่าตั้ง workflow + ตัวแปรที่ปรับคุณภาพ |

## ติดตั้ง RTX 4090/4080 — เลือกได้ 2 ทาง

**ทาง A — build ใหม่จากศูนย์ (ไม่ต้อง copy 35GB):**
1. clone repo นี้ → ดับเบิลคลิก `build_env_4090.bat`
2. รอ build เสร็จ → `C:\ComfyUI\run_nvidia_gpu.bat` (โมเดล ~30GB โหลดตอนรันครั้งแรก)

**ทาง B — copy โฟลเดอร์ (เร็วกว่าถ้ามี env อยู่แล้ว):**
1. copy โฟลเดอร์ `ComfyUI` ทั้งอันไปเครื่องใหม่ (สำหรับคนที่มีโฟลเดอร์แบบ offline ที่พร้อมใช้ ไม่ได้มีให้ทาง online -> online ให้ใช้แบบ A)
2. รัน `setup_new_machine.bat`
3. รัน `run_nvidia_gpu.bat` → http://127.0.0.1:8188

## RTX 50xx (Blackwell) + NAF
รัน `build_env_cp312_blackwell.bat` → สร้าง venv Python 3.12 + ลง NATTEN Blackwell
ถ้า `HAS_LIBNATTEN=True` → ตั้ง `naf_mode=strict` ได้

## ⚠️ ข้อควรระวัง
- **อย่าให้ pip เปลี่ยน torch** — pin ที่ 2.10.0+cu130
- **อย่ารัน `setup.sh` ของ microsoft/TRELLIS.2** ลง env นี้ (มัน pin torch 2.6/cu124 → พังทั้งระบบ)
- โมเดล RMBG-2.0 เป็น gated (ต้องขอ access + HF token)

## ที่มา
- Node: https://github.com/Saganaki22/Pixal3D-ComfyUI
- โมเดล: https://huggingface.co/TencentARC/Pixal3D
- ฐาน: https://github.com/microsoft/TRELLIS.2
