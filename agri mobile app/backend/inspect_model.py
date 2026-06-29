"""
Run this ONCE to inspect your checkpoint and print the correct settings.
Usage:  python inspect_model.py
"""

import torch
import sys

MODEL_PATH = "model/crop_model_final.pt"

print("=" * 60)
print("CHECKPOINT INSPECTOR")
print("=" * 60)

try:
    ckpt = torch.load(MODEL_PATH, map_location="cpu", weights_only=False)
except TypeError:
    ckpt = torch.load(MODEL_PATH, map_location="cpu")

print(f"\nCheckpoint type : {type(ckpt)}")

# ── Full model object ─────────────────────────
if hasattr(ckpt, "parameters"):
    import torch.nn as nn
    params = sum(p.numel() for p in ckpt.parameters()) / 1e6
    print(f"Format          : Full model object (torch.save(model, ...))")
    print(f"Parameters      : {params:.2f} M")
    print(f"Architecture    : {type(ckpt).__name__}")
    print(f"\n✅ predict.py will load this automatically — no changes needed.")
    sys.exit(0)

# ── Dict checkpoint ───────────────────────────
if isinstance(ckpt, dict):
    print(f"Format          : Dict checkpoint")
    print(f"Top-level keys  : {list(ckpt.keys())}")
    print()

    # Metadata
    for meta_key in ("backbone", "num_classes", "img_size", "class_names"):
        if meta_key in ckpt:
            val = ckpt[meta_key]
            if meta_key == "class_names":
                print(f"  {meta_key:15s}: {val}")
            else:
                print(f"  {meta_key:15s}: {val}")

    # Find state dict
    state_dict = None
    for key in ("model_state_dict", "state_dict", "model", "weights"):
        if key in ckpt:
            state_dict = ckpt[key]
            print(f"\n  State dict key  : '{key}'")
            break
    if state_dict is None and all(isinstance(v, torch.Tensor) for v in ckpt.values()):
        state_dict = ckpt
        print(f"\n  Format: raw state dict (no wrapper key)")

    if state_dict:
        keys = list(state_dict.keys())
        print(f"  State dict keys : {len(keys)} total")
        print(f"  First 5 keys    : {keys[:5]}")
        print(f"  Last  5 keys    : {keys[-5:]}")

        # Detect architecture
        first_conv = "features.0.0.weight"
        if first_conv in state_dict:
            shape = state_dict[first_conv].shape
            print(f"\n  First conv shape: {list(shape)}")
            print(f"  → Use this info to identify your backbone:")
            print(f"    [32, 3, 3, 3] = EfficientNet-B0 or B1")
            print(f"    [24, 3, 3, 3] = EfficientNet-V2-S or V2-M")
            print(f"    [16, 3, 3, 3] = Custom / non-standard model")
            print(f"    [48, 3, 3, 3] = EfficientNet-B4")

        clf_keys = [k for k in keys if k.startswith("classifier")]
        print(f"\n  Classifier keys : {clf_keys}")

        max_feat = max((int(k.split(".")[1]) for k in keys if k.startswith("features.")), default=-1)
        print(f"  Max feature idx : {max_feat}")

    print("\n" + "=" * 60)
    print("ACTION REQUIRED: check predict.py build_model() matches your architecture.")
    print("If backbone is non-standard, you MUST use torch.save(model, path) format.")
    print("=" * 60)

else:
    print(f"Unknown checkpoint format: {type(ckpt)}")