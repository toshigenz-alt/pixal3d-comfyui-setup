"""ตรวจว่า Python env ของ ComfyUI พร้อมรัน Pixal3D (torch / CUDA wheels / triton)."""
import importlib.util as u
import torch

print("  torch:", torch.__version__, "| cuda:", torch.version.cuda, "| avail:", torch.cuda.is_available())
if torch.cuda.is_available():
    print("  GPU:", torch.cuda.get_device_name(0), "| cap:", torch.cuda.get_device_capability(0))

mods = ["flash_attn", "flex_gemm_ap", "cumesh_vb", "o_voxel_vb_ap", "drtk", "triton", "zstandard"]
miss = [m for m in mods if u.find_spec(m) is None]
print("  modules missing:", miss if miss else "none")

try:
    import triton
    import triton.language as tl

    @triton.jit
    def _k(x, o, n, B: tl.constexpr):
        i = tl.program_id(0) * B + tl.arange(0, B)
        m = i < n
        tl.store(o + i, tl.load(x + i, mask=m) * 2.0, mask=m)

    a = torch.rand(256, device="cuda")
    b = torch.empty_like(a)
    _k[(1,)](a, b, 256, B=256)
    torch.cuda.synchronize()
    ok = bool(torch.allclose(b, a * 2.0))
    print("  triton JIT compile:", "OK" if ok else "FAIL (wrong result)")
except Exception as e:
    print("  triton JIT compile: FAIL ->", type(e).__name__, e)

print("  RESULT:", "READY" if not miss else "MISSING MODULES")
