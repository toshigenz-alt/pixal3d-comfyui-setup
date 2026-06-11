# Pixal3D-ComfyUI — คู่มือย้ายไปเครื่องอื่น (สเปคเดียวกัน)

ติดตั้งเสร็จและทดสอบได้ `.glb` จริงบน RTX 4090 / Windows 11 / Python 3.13.12 / torch 2.10.0+cu130

---

## วิธีย้ายไปเครื่องใหม่ (สเปคเดียวกัน = NVIDIA RTX 4090, Windows)

### ขั้นที่ 1 — copy ทั้งโฟลเดอร์
copy โฟลเดอร์ `ComfyUI` ทั้งอัน (ตอนนี้อยู่ที่ `C:\_Ai\ComfyUI`, ~35GB รวมโมเดล) ไปวางที่เครื่องใหม่
วางที่ไหนก็ได้ (เช่น `D:\ComfyUI`) — ตัว portable ใช้ path แบบ relative ย้ายได้อิสระ

> ทุกอย่างติดไปด้วย: Python + แพ็กเกจทั้งหมด + Python dev files (สำหรับ triton) + โมเดล Pixal3D/RMBG/MoGe ~30GB
> แนะนำ copy ผ่าน external SSD หรือแชร์ไฟล์ในเครือข่าย (zip ก่อนก็ได้ แต่ก้อนใหญ่)

### ขั้นที่ 2 — เครื่องใหม่ต้องมี
1. **NVIDIA driver ล่าสุด** (รองรับ CUDA 13) — การ์ด 4090 อยู่แล้ว แค่อัปเดต driver ให้ใหม่
2. **Git** — สคริปต์ติดตั้งให้อัตโนมัติในขั้นที่ 3

### ขั้นที่ 3 — รันสคริปต์ติดตั้งครั้งเดียว
เข้าโฟลเดอร์ **`Er`** (อยู่ใน ComfyUI) ดับเบิลคลิก **`setup_new_machine.bat`**
สคริปต์จะ:
- ตรวจ GPU
- ติดตั้ง Git (ผ่าน winget) ถ้ายังไม่มี + ตั้ง env var ให้ ComfyUI-Manager
- ตรวจ Python env (torch, CUDA wheels, triton compile) ว่าครบ

### ขั้นที่ 4 — เปิดใช้งาน
ดับเบิลคลิก **`run_nvidia_gpu.bat`** → เปิดเบราว์เซอร์ http://127.0.0.1:8188
โหลด workflow จาก `ComfyUI\custom_nodes\Pixal3D-ComfyUI\example_workflows\`

---

## สิ่งที่ทำไว้แล้ว (อย่าไปแก้)
- **torch ถูก pin ที่ 2.10.0+cu130** เพื่อให้ตรงกับ CUDA wheels — อย่าให้ pip เปลี่ยน torch
- CUDA wheels (cp313/cu130/torch2.10): `flex_gemm_ap`, `cumesh_vb`, `o_voxel_vb_ap`, `drtk`, `flash_attn` + `triton-windows`, `zstandard`
- **NATTEN ข้ามไป** (ไม่มี wheel สำหรับ sm_89) — ใช้ `naf_mode=fallback_if_missing`
- **Python dev files** (`python_embeded\include\Python.h`, `python_embeded\libs\python313.lib`) เติมไว้ให้ triton compile ได้
- โมเดลครบใน `ComfyUI\models\`: Pixal3D (TencentARC_Pixal3D ~22GB), RMBG-2.0 (gated), MoGe

## ตั้งค่า workflow ที่ใช้ได้ชัวร์บน 4090
- Model Loader: `vram_mode=dynamic_vram`, `naf_mode=fallback_if_missing`
- Image-to-3D: `pipeline_type=1024_cascade`
- ลบพื้นหลัง: `background_mode=auto_remove` + `load_rembg=true` (ใช้ RMBG-2.0 ที่โหลดไว้)
  หรือถ้าภาพโปร่งใสอยู่แล้ว ใช้ `keep_alpha`; ถ้าไม่อยากลบ ใช้ `none`
- มุมกล้อง: `camera_mode=moge` (มี MoGe แล้ว) หรือ `manual`

## ไฟล์อ้างอิง
- `env_lock_requirements.txt` — รายการแพ็กเกจ (pip freeze) ของ env ที่ทำงานได้
- `submit_pixal3d_test.py` — สคริปต์ทดสอบรัน workflow ผ่าน API (สร้าง .glb)

## หมายเหตุ
- เครื่องที่ **สเปคต่างกัน** (GPU คนละรุ่น) อาจต้องเปลี่ยน CUDA wheels ให้ตรง arch — wheel ปัจจุบัน build สำหรับ cp313/cu130/torch2.10 (รองรับ sm_75/80/86/89/90/100/120 = RTX 20/30/40/50 ซีรีส์ส่วนใหญ่)
- ถ้า ComfyUI-Manager ขึ้น error เรื่อง git ให้เปิด PowerShell ใหม่ (รับ env var ที่เพิ่งตั้ง) แล้วรัน bat อีกครั้ง
