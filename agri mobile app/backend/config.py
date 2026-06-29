import os

# ─────────────────────────────────────────────
# Paths
# ─────────────────────────────────────────────
BASE_DIR   = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "model", "crop_model_final.pt")
UPLOAD_DIR = os.path.join(BASE_DIR, "uploads")

os.makedirs(UPLOAD_DIR, exist_ok=True)
os.makedirs(os.path.join(BASE_DIR, "model"), exist_ok=True)

# ─────────────────────────────────────────────
# Model settings
# ─────────────────────────────────────────────
IMG_SIZE    = 256
NUM_CLASSES = 16
DEVICE      = "cpu"

# ─────────────────────────────────────────────
# Class labels
# ─────────────────────────────────────────────
CLASS_NAMES = [
    "Magnessium deficiency",
    "Nitrogen_Deficiency",
    "Pepper__bell___Bacterial_spot",
    "Pepper__bell___healthy",
    "Phosphorous  deficiency",
    "Potato___Early_blight",
    "Potato___Late_blight",
    "Potato___healthy",
    "Pottasium deficiency",
    "Tomato_Bacterial_spot",
    "Tomato_Early_blight",
    "Tomato_Late_blight",
    "Tomato_Leaf_Mold",
    "Tomato_Septoria_leaf_spot",
    "Tomato__Target_Spot",
    "Tomato_healthy",
]

# ─────────────────────────────────────────────
# Flask
# ─────────────────────────────────────────────
SECRET_KEY     = os.environ.get("SECRET_KEY", "change-me-in-production")
MAX_CONTENT_MB = 10
ALLOWED_EXTS   = {"png", "jpg", "jpeg", "webp", "bmp"}

# ─────────────────────────────────────────────
# JWT
# ─────────────────────────────────────────────
# In production set:  export JWT_SECRET="some-long-random-string"
JWT_SECRET      = os.environ.get("JWT_SECRET", "cropai-jwt-secret-change-in-prod")
JWT_EXPIRY_HOURS = int(os.environ.get("JWT_EXPIRY_HOURS", "720"))  # 30 days

# ─────────────────────────────────────────────
# MongoDB
# ─────────────────────────────────────────────
# For MongoDB Compass (local):  mongodb://localhost:27017/agri_db
# For Atlas (cloud):  export MONGODB_URI="mongodb+srv://user:pass@cluster.mongodb.net/agri_db"
DATABASE_URI = os.environ.get(
    "MONGODB_URI",
    "mongodb://localhost:27017/agri_db"   # ← default for MongoDB Compass
)