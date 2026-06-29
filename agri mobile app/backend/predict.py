"""
Model loading and inference.
Backbone: MobileNet-V3-Large  (confirmed from checkpoint inspection)
Classifier: 3-layer custom head  (indices 0, 3, 6)
Checkpoint format: dict with key 'model_state_dict'

Non-crop rejection: images with max confidence < CONFIDENCE_THRESHOLD
raise a ValueError that app.py converts to a 400 error response.
"""

import os
import torch
import torch.nn as nn
import torchvision.transforms as T
from torchvision import models
from PIL import Image
from config import MODEL_PATH, IMG_SIZE, CLASS_NAMES, DEVICE, NUM_CLASSES

# ─────────────────────────────────────────────
# Non-crop image rejection threshold
# ─────────────────────────────────────────────
CONFIDENCE_THRESHOLD = 0.20   # 20 % — lowered so real leaf photos are accepted


# ─────────────────────────────────────────────
# Build model — matches training architecture
# ─────────────────────────────────────────────
def build_model(num_classes: int, backbone: str = "mobilenet_v3_large") -> nn.Module:
    b = backbone.lower().strip()

    if b in ("mobilenet_v3_large", "mobilenet_v3", "mobilenetv3_large", "mobilenetv3"):
        base = models.mobilenet_v3_large(weights=None)
        in_features = base.classifier[0].in_features   # 960
        base.classifier = nn.Sequential(
            nn.Linear(in_features, 1280),
            nn.Hardswish(),
            nn.Dropout(p=0.2, inplace=True),
            nn.Linear(1280, 512),
            nn.Hardswish(),
            nn.Dropout(p=0.2, inplace=True),
            nn.Linear(512, num_classes),
        )
        return base

    if b in ("mobilenet_v3_small", "mobilenetv3_small"):
        base = models.mobilenet_v3_small(weights=None)
        in_features = base.classifier[0].in_features
        base.classifier = nn.Sequential(
            nn.Linear(in_features, 1024),
            nn.Hardswish(),
            nn.Dropout(p=0.2, inplace=True),
            nn.Linear(1024, num_classes),
        )
        return base

    if b in ("efficientnet_b0", "efficientnet", "efficientnet-b0"):
        base = models.efficientnet_b0(weights=None)
        base.classifier = nn.Sequential(
            nn.Dropout(p=0.3, inplace=True),
            nn.Linear(base.classifier[1].in_features, num_classes),
        )
        return base

    if b in ("efficientnet_b3", "efficientnet-b3"):
        base = models.efficientnet_b3(weights=None)
        base.classifier = nn.Sequential(
            nn.Dropout(p=0.3, inplace=True),
            nn.Linear(base.classifier[1].in_features, num_classes),
        )
        return base

    if b in ("resnet50", "resnet"):
        base = models.resnet50(weights=None)
        base.fc = nn.Linear(base.fc.in_features, num_classes)
        return base

    print(f"[predict] WARNING: unknown backbone '{backbone}', defaulting to mobilenet_v3_large")
    return build_model(num_classes, "mobilenet_v3_large")


# ─────────────────────────────────────────────
# Singleton state
# ─────────────────────────────────────────────
_model       = None
_class_names = None


def load_model() -> nn.Module:
    global _model, _class_names

    if _model is not None:
        return _model

    if not os.path.exists(MODEL_PATH):
        raise FileNotFoundError(
            f"Model file not found at: {MODEL_PATH}\n"
            "Place crop_model_final.pt inside the model/ folder."
        )

    device = torch.device(DEVICE)
    print(f"[predict] Loading: {MODEL_PATH}")

    try:
        checkpoint = torch.load(MODEL_PATH, map_location=device, weights_only=False)
    except TypeError:
        checkpoint = torch.load(MODEL_PATH, map_location=device)

    if isinstance(checkpoint, nn.Module):
        print("[predict] Format: full model object")
        checkpoint.to(device)
        checkpoint.eval()
        _model = checkpoint
        return _model

    if isinstance(checkpoint, dict):
        backbone    = checkpoint.get("backbone",    "mobilenet_v3_large")
        num_classes = checkpoint.get("num_classes", NUM_CLASSES)
        img_size    = checkpoint.get("img_size",    IMG_SIZE)
        saved_names = checkpoint.get("class_names", None)

        if saved_names is not None:
            _class_names = list(saved_names)

        print(f"[predict] backbone={backbone}  classes={num_classes}  img_size={img_size}")

        state_dict = None
        for key in ("model_state_dict", "state_dict", "model", "weights", "net"):
            if key in checkpoint:
                state_dict = checkpoint[key]
                print(f"[predict] Weights key: '{key}'")
                break

        if state_dict is None:
            if all(isinstance(v, torch.Tensor) for v in checkpoint.values()):
                state_dict = checkpoint
                print("[predict] Format: raw state dict")
            else:
                raise RuntimeError(
                    f"Cannot find weights in checkpoint.\n"
                    f"Keys found: {list(checkpoint.keys())}"
                )

        model = build_model(num_classes, backbone)

        try:
            model.load_state_dict(state_dict, strict=True)
            print("[predict] ✅ Weights loaded (strict=True)")
        except RuntimeError:
            c0_out = state_dict.get("classifier.0.weight", None)
            c3_out = state_dict.get("classifier.3.weight", None)
            c6_out = state_dict.get("classifier.6.weight", None)

            if c0_out is not None and c3_out is not None and c6_out is not None:
                dim0 = c0_out.shape[0]
                dim3 = c3_out.shape[0]
                in_f = c0_out.shape[1]

                print(f"[predict] Rebuilding classifier: "
                      f"Linear({in_f}→{dim0}) → Linear({dim0}→{dim3}) → Linear({dim3}→{num_classes})")

                base = models.mobilenet_v3_large(weights=None)
                base.classifier = nn.Sequential(
                    nn.Linear(in_f,   dim0),
                    nn.Hardswish(),
                    nn.Dropout(p=0.2, inplace=True),
                    nn.Linear(dim0,   dim3),
                    nn.Hardswish(),
                    nn.Dropout(p=0.2, inplace=True),
                    nn.Linear(dim3,   num_classes),
                )
                model = base
                model.load_state_dict(state_dict, strict=True)
                print("[predict] ✅ Weights loaded after auto-dim fix (strict=True)")
            else:
                result  = model.load_state_dict(state_dict, strict=False)
                missing = result.missing_keys
                extra   = result.unexpected_keys
                print(f"[predict] ⚠️  strict=False used. Missing={len(missing)} Extra={len(extra)}")

        model.to(device)
        model.eval()
        _model = model
        return _model

    raise RuntimeError(f"Unrecognised checkpoint type: {type(checkpoint)}")


def get_class_names() -> list:
    return _class_names if _class_names is not None else CLASS_NAMES


# ─────────────────────────────────────────────
# Preprocessing — must match training
# ─────────────────────────────────────────────
def get_preprocess(img_size: int = IMG_SIZE) -> T.Compose:
    return T.Compose([
        T.Resize((img_size, img_size)),
        T.ToTensor(),
        T.Normalize(mean=[0.485, 0.456, 0.406],
                    std =[0.229, 0.224, 0.225]),
    ])

preprocess = get_preprocess(IMG_SIZE)


# ─────────────────────────────────────────────
# Inference
# ─────────────────────────────────────────────
def predict_image(image_path: str) -> dict:
    """
    Returns
    -------
    {
        "label":         str,
        "confidence":    float (0-1),
        "class_index":   int,
        "probabilities": {class_name: prob, ...}
    }

    Raises
    ------
    ValueError — if the image is not a recognisable crop leaf
                 (max confidence < CONFIDENCE_THRESHOLD).
    """
    model       = load_model()
    class_names = get_class_names()
    device      = torch.device(DEVICE)

    try:
        img = Image.open(image_path).convert("RGB")
    except Exception as e:
        raise ValueError(f"Cannot open image '{image_path}': {e}")

    tf     = get_preprocess(256)
    tensor = tf(img).unsqueeze(0).to(device)

    with torch.no_grad():
        logits = model(tensor)
        probs  = torch.softmax(logits, dim=1)[0]

    class_idx  = int(probs.argmax().item())
    confidence = float(probs[class_idx].item())

    # ── Non-crop rejection ────────────────────
    if confidence < CONFIDENCE_THRESHOLD:
        raise ValueError(
            f"Image does not appear to be a crop leaf. "
            f"Highest confidence was only {confidence * 100:.1f}% "
            f"(threshold: {CONFIDENCE_THRESHOLD * 100:.0f}%). "
            f"Please upload a clear, close-up photo of a plant leaf."
        )

    label = class_names[class_idx] if class_idx < len(class_names) else f"class_{class_idx}"

    prob_dict = {
        (class_names[i] if i < len(class_names) else f"class_{i}"): round(float(probs[i].item()), 4)
        for i in range(len(probs))
    }

    return {
        "label":         label,
        "confidence":    round(confidence, 4),
        "class_index":   class_idx,
        "probabilities": prob_dict,
    }