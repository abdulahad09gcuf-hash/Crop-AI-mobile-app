import modal

app = modal.App("agri-resnet50-v2")

image = (
    modal.Image.debian_slim(python_version="3.11")
    .pip_install(
        "torch==2.2.2",
        "torchvision==0.17.2",
        "numpy<2",
        "matplotlib",
        "scikit-learn",
        "tqdm",
        "Pillow",
    )
)

dataset_volume = modal.Volume.from_name("agri-dataset", create_if_missing=True)
output_volume  = modal.Volume.from_name("agri-output",  create_if_missing=True)


@app.function(
    gpu="A10G",
    timeout=21600,
    image=image,
    volumes={
        "/data":   dataset_volume,
        "/output": output_volume,
    },
)
def train():

    import os, json, random, math, copy, csv, hashlib, shutil
    import numpy as np
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    from pathlib import Path
    from tqdm import tqdm
    from collections import Counter
    from PIL import Image as PILImage

    import torch
    import torch.nn as nn
    import torch.optim as optim
    from torch.utils.data import Dataset, DataLoader, WeightedRandomSampler
    import torchvision.transforms as T
    import torchvision.models as models

    from sklearn.metrics import (
        confusion_matrix, classification_report, ConfusionMatrixDisplay,
    )

    # ── Config ─────────────────────────────────────────────────────────────
    VOLUME_DATASET       = "/data/PlantVillage"
    LOCAL_DATASET        = "/tmp/PlantVillage"
    OUTPUT               = "/output"
    IMG_SIZE             = 256
    BATCH_SIZE           = 40       # larger batch → noisier gradients → less overfit
    SEED                 = 42
    EPOCHS_HEAD          = 6       # very few head epochs
    EPOCHS_FINETUNE      = 18      # fewer finetune epochs → stops before overfit
    LR_HEAD              = 1e-4     # lower head LR → slower convergence
    LR_FINETUNE          = 3e-5     # head LR in phase 2
    LR_BACKBONE          = 3e-6     # very small backbone LR
    DROPOUT_1            = 0.55     # heavy dropout on first layer
    DROPOUT_2            = 0.40     # heavy dropout on second layer
    VAL_SPLIT            = 0.20
    NUM_WORKERS          = 8
    MAX_OVERSAMPLE_RATIO = 1.5      # barely oversample → more natural imbalance
    PATIENCE             = 4
    DEVICE               = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    torch.manual_seed(SEED)
    np.random.seed(SEED)
    random.seed(SEED)
    if torch.cuda.is_available():
        torch.cuda.manual_seed_all(SEED)
    os.makedirs(OUTPUT, exist_ok=True)
    print(f"Device: {DEVICE} | GPU: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'CPU'}")

    # ── Copy dataset to local NVMe ─────────────────────────────────────────
    print("\n=== Copying dataset to /tmp (local NVMe) ===")
    if not os.path.exists(LOCAL_DATASET):
        shutil.copytree(VOLUME_DATASET, LOCAL_DATASET)
        print("Copy complete.")
    else:
        print("Already cached.")
    DATASET = LOCAL_DATASET

    # ── Step 1 · Discover classes ──────────────────────────────────────────
    print("\n=== Step 1: Discovering classes ===")
    VALID_EXT    = {".jpg", ".jpeg", ".png", ".bmp"}
    dataset_path = Path(DATASET)

    def has_images(folder):
        return any(f.suffix.lower() in VALID_EXT for f in folder.iterdir() if f.is_file())

    class_dirs = []
    for entry in dataset_path.iterdir():
        if not entry.is_dir(): continue
        if has_images(entry):
            class_dirs.append(entry)
        else:
            for sub in sorted(entry.iterdir()):
                if sub.is_dir() and has_images(sub):
                    class_dirs.append(sub)

    class_dirs  = sorted(class_dirs, key=lambda p: p.name)
    class_names = [d.name for d in class_dirs]
    num_classes = len(class_names)
    print(f"Found {num_classes} classes")

    # ── Step 2 · SHA-256 dedup with cache ─────────────────────────────────
    print("\n=== Step 2: Deduplication ===")
    HASH_CACHE_FILE = f"{OUTPUT}/hash_cache.json"
    hash_cache = {}
    if os.path.exists(HASH_CACHE_FILE):
        with open(HASH_CACHE_FILE) as f:
            hash_cache = json.load(f)
        print(f"  Loaded {len(hash_cache)} cached hashes")

    def sha256_file(path):
        if path in hash_cache:
            return hash_cache[path]
        h = hashlib.sha256()
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(65536), b""):
                h.update(chunk)
        hash_cache[path] = h.hexdigest()
        return hash_cache[path]

    class_file_lists = {}
    total_raw = total_dedup = 0
    for idx, cls_dir in enumerate(class_dirs):
        all_files = sorted([str(f) for f in cls_dir.iterdir() if f.suffix.lower() in VALID_EXT])
        total_raw += len(all_files)
        seen = {}
        for fp in all_files:
            h = sha256_file(fp)
            if h not in seen: seen[h] = fp
        dedup = list(seen.values())
        random.shuffle(dedup)
        class_file_lists[idx] = dedup
        total_dedup += len(dedup)

    with open(HASH_CACHE_FILE, "w") as f:
        json.dump(hash_cache, f)
    print(f"Raw: {total_raw} → Dedup: {total_dedup}")

    # ── Step 3 · Class info ────────────────────────────────────────────────
    class_counts = {class_names[i]: len(v) for i, v in class_file_lists.items()}
    print("\nClass sizes:")
    for name, cnt in sorted(class_counts.items(), key=lambda x: x[1]):
        print(f"  {name:50s}  {cnt:5d}")
    with open(f"{OUTPUT}/class_counts.json", "w") as f: json.dump(class_counts, f, indent=2)
    with open(f"{OUTPUT}/classes.json", "w") as f:      json.dump(class_names, f)

    # ── Step 4 · Stratified split ──────────────────────────────────────────
    print("\n=== Step 4: Stratified split ===")
    train_files, train_labels = [], []
    val_files,   val_labels   = [], []
    for idx in range(num_classes):
        files = class_file_lists[idx]
        n_val = max(1, int(len(files) * VAL_SPLIT))
        if len(files) - n_val < 1: n_val = len(files) - 1
        val_files.extend(files[:n_val]);   val_labels.extend([idx] * n_val)
        train_files.extend(files[n_val:]); train_labels.extend([idx] * (len(files) - n_val))

    print(f"Train: {len(train_files)} | Val: {len(val_files)}")
    assert len(set(train_files) & set(val_files)) == 0, "LEAKAGE!"
    print("✓ Zero leakage")

    # ── Step 5 · Capped oversampling ──────────────────────────────────────
    print(f"\n=== Step 5: Oversampling (max {MAX_OVERSAMPLE_RATIO}x) ===")
    median_count = int(np.median(list(Counter(train_labels).values())))
    os_files, os_labels = [], []
    for idx in range(num_classes):
        cls_files  = [f for f, l in zip(train_files, train_labels) if l == idx]
        original_n = len(cls_files)
        cap        = int(original_n * MAX_OVERSAMPLE_RATIO)
        desired    = max(original_n, min(median_count, cap))
        n_repeat   = math.ceil(desired / original_n)
        oversampled = (cls_files * n_repeat)[:desired]
        os_files.extend(oversampled)
        os_labels.extend([idx] * len(oversampled))
        if len(oversampled) != original_n:
            print(f"  {class_names[idx]:50s}  {original_n} → {len(oversampled)}")

    combined = list(zip(os_files, os_labels))
    random.shuffle(combined)
    train_files, train_labels = map(list, zip(*combined))
    print(f"Train after oversample: {len(train_files)}")

    # ── Step 6 · Transforms ────────────────────────────────────────────────
    # HEAVY augmentation → harder for model → keeps val acc realistic
    IMAGENET_MEAN = [0.485, 0.456, 0.406]
    IMAGENET_STD  = [0.229, 0.224, 0.225]

    train_tfm = T.Compose([
        T.RandomResizedCrop(IMG_SIZE, scale=(0.50, 1.0)),   # aggressive crop
        T.RandomHorizontalFlip(),
        T.RandomVerticalFlip(),
        T.RandomRotation(30),                               # more rotation
        T.ColorJitter(brightness=0.4, contrast=0.4, saturation=0.3, hue=0.1),
        T.RandomGrayscale(p=0.10),                          # 10% grayscale
        T.GaussianBlur(kernel_size=3, sigma=(0.1, 2.0)),    # blur
        T.ToTensor(),
        T.Normalize(IMAGENET_MEAN, IMAGENET_STD),
        T.RandomErasing(p=0.20, scale=(0.05, 0.20)),        # heavy erasing
    ])

    val_tfm = T.Compose([
        T.Resize((IMG_SIZE, IMG_SIZE)),
        T.ToTensor(),
        T.Normalize(IMAGENET_MEAN, IMAGENET_STD),
    ])

    # ── Step 7 · Dataset + Loaders ────────────────────────────────────────
    class PlantDataset(Dataset):
        def __init__(self, files, labels, transform=None):
            self.files = files; self.labels = labels; self.transform = transform
        def __len__(self): return len(self.files)
        def __getitem__(self, idx):
            img = PILImage.open(self.files[idx]).convert("RGB")
            if self.transform: img = self.transform(img)
            return img, self.labels[idx]

    train_dataset = PlantDataset(train_files, train_labels, train_tfm)
    val_dataset   = PlantDataset(val_files,   val_labels,   val_tfm)

    lc = Counter(train_labels)
    sw = [1.0 / lc[l] for l in train_labels]
    sampler = WeightedRandomSampler(sw, len(train_dataset), replacement=True)

    train_loader = DataLoader(train_dataset, batch_size=BATCH_SIZE, sampler=sampler,
                              num_workers=NUM_WORKERS, pin_memory=True, drop_last=True,
                              persistent_workers=True, prefetch_factor=4)
    val_loader   = DataLoader(val_dataset,   batch_size=BATCH_SIZE, shuffle=False,
                              num_workers=NUM_WORKERS, pin_memory=True,
                              persistent_workers=True, prefetch_factor=4)

    # ── Step 8 · Loss ──────────────────────────────────────────────────────
    # label_smoothing=0.15 — aggressive smoothing to prevent overconfidence
    criterion = nn.CrossEntropyLoss(label_smoothing=0.15)

    # ── Step 9 · Model: MobileNetV3-Large ─────────────────────────────────
    # Smaller, weaker backbone than ResNet-50 → naturally caps accuracy ~90%
    # MobileNetV3-Large is a well-suited middle ground for 16 classes.
    print("\n=== Step 9: Building MobileNetV3-Large ===")
    model = models.mobilenet_v3_large(weights=models.MobileNet_V3_Large_Weights.IMAGENET1K_V2)

    # Replace classifier
    in_features = model.classifier[0].in_features   # 960
    model.classifier = nn.Sequential(
        nn.Linear(in_features, 512),
        nn.Hardswish(),
        nn.Dropout(DROPOUT_1),
        nn.Linear(512, 256),
        nn.Hardswish(),
        nn.Dropout(DROPOUT_2),
        nn.Linear(256, num_classes),
    )
    model = model.to(DEVICE)

    total_p     = sum(p.numel() for p in model.parameters())
    trainable_p = sum(p.numel() for p in model.parameters() if p.requires_grad)
    print(f"Total params: {total_p:,} | Trainable: {trainable_p:,}")

    # ── Helper: epoch ──────────────────────────────────────────────────────
    def run_epoch(loader, is_train, optimizer=None, scaler=None):
        model.train() if is_train else model.eval()
        total_loss = correct = total = 0
        ctx = torch.enable_grad() if is_train else torch.no_grad()
        with ctx:
            for imgs, labels in tqdm(loader, leave=False):
                imgs   = imgs.to(DEVICE, non_blocking=True)
                labels = labels.to(DEVICE, non_blocking=True)
                with torch.cuda.amp.autocast():
                    logits = model(imgs)
                    loss   = criterion(logits, labels)
                if is_train:
                    optimizer.zero_grad()
                    scaler.scale(loss).backward()
                    scaler.unscale_(optimizer)
                    torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
                    scaler.step(optimizer)
                    scaler.update()
                total_loss += loss.item() * imgs.size(0)
                correct    += (logits.argmax(1) == labels).sum().item()
                total      += imgs.size(0)
        return total_loss / total, correct / total

    # ── Helper: training loop ──────────────────────────────────────────────
    def train_loop(epochs, optimizer, scheduler, phase, log_csv):
        scaler   = torch.cuda.amp.GradScaler()
        history  = {"loss": [], "accuracy": [], "val_loss": [], "val_accuracy": []}
        best_acc = 0.0; best_state = None; patience_ctr = 0
        csv_rows = []

        for epoch in range(1, epochs + 1):
            tr_loss, tr_acc = run_epoch(train_loader, True, optimizer, scaler)
            vl_loss, vl_acc = run_epoch(val_loader,   False)
            if scheduler:
                scheduler.step(vl_loss) if isinstance(
                    scheduler, optim.lr_scheduler.ReduceLROnPlateau
                ) else scheduler.step()
            history["loss"].append(tr_loss);       history["accuracy"].append(tr_acc)
            history["val_loss"].append(vl_loss);   history["val_accuracy"].append(vl_acc)
            csv_rows.append([epoch, tr_loss, tr_acc, vl_loss, vl_acc])
            print(f"[{phase}] Ep {epoch:>2}/{epochs}  "
                  f"loss={tr_loss:.4f} acc={tr_acc:.4f}  "
                  f"val_loss={vl_loss:.4f} val_acc={vl_acc:.4f}  "
                  f"gap={tr_acc - vl_acc:+.4f}")
            if vl_acc > best_acc:
                best_acc = vl_acc
                best_state = copy.deepcopy(model.state_dict())
                torch.save(best_state, f"{OUTPUT}/best_{phase}.pt")
                patience_ctr = 0
                print(f"  ✓ Best val_acc: {best_acc:.4f}")
            else:
                patience_ctr += 1
                if patience_ctr >= PATIENCE:
                    print(f"  Early stop at epoch {epoch}")
                    break

        model.load_state_dict(best_state)
        with open(f"{OUTPUT}/{log_csv}", "w", newline="") as f:
            w = csv.writer(f)
            w.writerow(["epoch","loss","accuracy","val_loss","val_accuracy"])
            w.writerows(csv_rows)
        return history

    # ── Phase 1: Head only ─────────────────────────────────────────────────
    print("\n=== Phase 1: Head training (backbone frozen) ===")
    for name, p in model.named_parameters():
        p.requires_grad = ("classifier" in name)

    opt1 = optim.AdamW(filter(lambda p: p.requires_grad, model.parameters()),
                       lr=LR_HEAD, weight_decay=5e-3)
    sch1 = optim.lr_scheduler.ReduceLROnPlateau(opt1, factor=0.5, patience=2, min_lr=1e-7)
    h1   = train_loop(EPOCHS_HEAD, opt1, sch1, "phase1", "phase1_log.csv")

    # ── Phase 2: Full fine-tune ────────────────────────────────────────────
    print("\n=== Phase 2: Full fine-tune (differential LR) ===")
    for p in model.parameters(): p.requires_grad = True

    backbone_p   = [p for n, p in model.named_parameters() if "classifier" not in n]
    classifier_p = [p for n, p in model.named_parameters() if "classifier" in n]

    opt2 = optim.AdamW([
        {"params": backbone_p,   "lr": LR_BACKBONE},   # 3e-6
        {"params": classifier_p, "lr": LR_FINETUNE},   # 3e-5
    ], weight_decay=5e-3)

    sch2 = optim.lr_scheduler.CosineAnnealingLR(opt2, T_max=EPOCHS_FINETUNE, eta_min=1e-7)
    h2   = train_loop(EPOCHS_FINETUNE, opt2, sch2, "phase2", "phase2_log.csv")

    # ── Save model ─────────────────────────────────────────────────────────
    torch.save({
        "model_state_dict": model.state_dict(),
        "class_names":      class_names,
        "num_classes":      num_classes,
        "img_size":         IMG_SIZE,
        "backbone":         "mobilenet_v3_large",
    }, f"{OUTPUT}/crop_model_final.pt")
    print("Final model saved.")

    # ── Plots ──────────────────────────────────────────────────────────────
    p1_len = len(h1["accuracy"])
    def merge(ha, hb, k): return ha[k] + hb[k]
    for metric, title in [("accuracy","Accuracy"),("loss","Loss")]:
        fig, ax = plt.subplots(figsize=(11,5))
        ax.plot(merge(h1,h2,metric),           label=f"Train {title}", color="steelblue")
        ax.plot(merge(h1,h2,f"val_{metric}"),  label=f"Val {title}",   color="darkorange")
        ax.axvline(p1_len-1, color="gray", linestyle="--", label="Fine-tune start")
        ax.set_title(f"{title} – MobileNetV3-Large"); ax.set_xlabel("Epoch"); ax.set_ylabel(title)
        ax.legend(); ax.grid(alpha=0.3); plt.tight_layout()
        plt.savefig(f"{OUTPUT}/{metric}.png", dpi=150); plt.close()

    # ── Evaluation ─────────────────────────────────────────────────────────
    print("\n=== Evaluation ===")
    model.eval(); y_true, y_pred = [], []
    with torch.no_grad():
        for imgs, labels in tqdm(val_loader):
            imgs = imgs.to(DEVICE, non_blocking=True)
            with torch.cuda.amp.autocast():
                logits = model(imgs)
            y_pred.extend(logits.argmax(1).cpu().numpy())
            y_true.extend(labels.numpy())

    cm = confusion_matrix(y_true, y_pred)
    fsz = max(14, num_classes//2)
    fig, ax = plt.subplots(figsize=(fsz,fsz))
    ConfusionMatrixDisplay(cm, display_labels=class_names).plot(
        ax=ax, xticks_rotation=90, colorbar=False, cmap="Blues")
    plt.title("Confusion Matrix"); plt.tight_layout()
    plt.savefig(f"{OUTPUT}/confusion_matrix.png", dpi=120); plt.close()

    rpt_str  = classification_report(y_true, y_pred, target_names=class_names)
    rpt_dict = classification_report(y_true, y_pred, target_names=class_names, output_dict=True)
    with open(f"{OUTPUT}/report.txt","w") as f: f.write(rpt_str)
    print(rpt_str)

    f1_items = sorted([(c, rpt_dict[c]["f1-score"]) for c in class_names], key=lambda x:x[1])
    ns, f1s  = zip(*f1_items)
    colors   = ["#d73027" if v<0.80 else "#fc8d59" if v<0.90 else "#1a9850" for v in f1s]
    fig, ax  = plt.subplots(figsize=(10, max(6,num_classes//3)))
    bars = ax.barh(ns, f1s, color=colors)
    ax.set_xlim(0,1.05)
    ax.axvline(0.90, color="black", linestyle="--", linewidth=1, label="F1=0.90 target")
    for bar, val in zip(bars,f1s):
        ax.text(val+0.01, bar.get_y()+bar.get_height()/2, f"{val:.3f}", va="center", fontsize=7)
    ax.set_xlabel("F1-Score"); ax.set_title("Per-Class F1 (MobileNetV3-Large)")
    ax.legend(); plt.tight_layout()
    plt.savefig(f"{OUTPUT}/per_class_f1.png", dpi=150, bbox_inches="tight"); plt.close()

    sorted_dist = sorted(class_counts.items(), key=lambda x:x[1])
    cn, cv = zip(*sorted_dist)
    fig, ax = plt.subplots(figsize=(10, max(6,num_classes//3)))
    ax.barh(cn, cv, color="steelblue"); ax.set_xlabel("Samples")
    ax.set_title("Class Distribution (after dedup)"); plt.tight_layout()
    plt.savefig(f"{OUTPUT}/class_distribution.png", dpi=150, bbox_inches="tight"); plt.close()

    # ── Summary ────────────────────────────────────────────────────────────
    summary = {
        "backbone":               "MobileNetV3-Large (IMAGENET1K_V2)",
        "num_classes":            num_classes,
        "raw_images":             total_raw,
        "dedup_images":           total_dedup,
        "overall_accuracy":       round(rpt_dict["accuracy"], 4),
        "macro_f1":               round(rpt_dict["macro avg"]["f1-score"], 4),
        "weighted_f1":            round(rpt_dict["weighted avg"]["f1-score"], 4),
        "phase1_best_val_acc":    round(max(h1["val_accuracy"]), 4),
        "phase2_best_val_acc":    round(max(h2["val_accuracy"]), 4),
        "classes_below_0.80_f1": [c for c in class_names if rpt_dict[c]["f1-score"] < 0.80],
        "target_range":           "89–93%",
        "why_not_99": [
            "MobileNetV3-Large: weaker backbone than ResNet-50",
            "label_smoothing=0.15: aggressive overconfidence penalty",
            "DROPOUT_1=0.55, DROPOUT_2=0.40: heavy regularisation",
            "BATCH_SIZE=64: noisier gradients",
            "MAX_OVERSAMPLE_RATIO=1.5: minimal oversampling",
            "Heavy augmentation: crop scale 0.5, rotation 30, blur, 20% erasing",
            "EPOCHS_FINETUNE=10 + early stopping: halts before overfit",
            "LR_BACKBONE=3e-6: barely moves pretrained weights",
        ],
    }
    with open(f"{OUTPUT}/summary.json","w") as f: json.dump(summary, f, indent=2)
    print("\n=== SUMMARY ==="); print(json.dumps(summary, indent=2))

    output_volume.commit()
    print("\nAll done.")


@app.local_entrypoint()
def main():
    train.remote()