import json, sys, urllib.request, os
import numpy as np
from PIL import Image

INPUT_DIR = r"C:\_Ai\ComfyUI\ComfyUI\input"
os.makedirs(INPUT_DIR, exist_ok=True)
IMG_NAME = "pixal3d_test_rgba.png"

# --- make a simple shaded sphere on a transparent background ---
S = 512
yy, xx = np.mgrid[0:S, 0:S]
cx, cy, r = S/2, S/2, S*0.40
dx, dy = (xx - cx) / r, (yy - cy) / r
d2 = dx*dx + dy*dy
inside = d2 <= 1.0
dz = np.sqrt(np.clip(1.0 - d2, 0, 1))
# light from upper-left-front
lx, ly, lz = -0.5, -0.6, 0.7
ln = (lx*dx + ly*dy + lz*dz)
shade = np.clip(0.25 + 0.85*ln, 0, 1)
base = np.array([235, 120, 40], dtype=np.float32)  # orange
rgb = (shade[..., None] * base).astype(np.uint8)
alpha = (inside * 255).astype(np.uint8)
rgba = np.dstack([rgb, alpha])
rgba[~inside] = [0, 0, 0, 0]
Image.fromarray(rgba, "RGBA").save(os.path.join(INPUT_DIR, IMG_NAME))
print("wrote test image:", os.path.join(INPUT_DIR, IMG_NAME))

# --- build API prompt ---
prompt = {
    "3": {"class_type": "Pixal3DModelLoader", "inputs": {
        "model_repo": "TencentARC/Pixal3D",
        "hf_endpoint": "https://huggingface.co",
        "attention_backend": "auto",
        "vram_mode": "dynamic_vram",
        "download_if_missing": True,
        "load_moge": False,
        "load_rembg": False,
        "naf_mode": "fallback_if_missing",
        "naf_target_size": "upstream",
        "preload_naf": False,
        "force_reload": False,
    }},
    "1": {"class_type": "LoadImage", "inputs": {"image": IMG_NAME}},
    "2": {"class_type": "Pixal3DImageTo3D", "inputs": {
        "model": ["3", 0],
        "image": ["1", 0],
        "seed": 12345,
        "pipeline_type": "1024_cascade",
        "background_mode": "none",
        "camera_mode": "manual",
        "manual_camera_angle_x": 0.857556,
        "manual_distance": 2.0,
        "mesh_scale": 1.0,
        "extend_pixel": 0,
        "camera_resolution": 512,
        "steps": 12,
        "guidance": 7.5,
        "texture_guidance": 1.0,
        "max_num_tokens": 49152,
        "force_offload": False,
    }},
    "4": {"class_type": "Pixal3DExportGLB", "inputs": {
        "pixal3d_result": ["2", 0],
        "decimation_target": 1000000,
        "texture_size": 2048,
        "remesh": True,
        "filename_prefix": "pixal3d_test",
    }},
}

body = json.dumps({"prompt": prompt}).encode("utf-8")
req = urllib.request.Request("http://127.0.0.1:8188/prompt", data=body,
                             headers={"Content-Type": "application/json"})
try:
    resp = urllib.request.urlopen(req, timeout=60)
    out = json.loads(resp.read().decode("utf-8"))
    print("SUBMIT_OK", json.dumps(out))
except urllib.error.HTTPError as e:
    print("SUBMIT_HTTP_ERROR", e.code)
    print(e.read().decode("utf-8"))
    sys.exit(1)
