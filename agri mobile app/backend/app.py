"""
Crop Disease Detection — Flask REST API
Fixed: Auth routes now properly registered (/auth/signup, /auth/login, /auth/me)
"""

import os
import uuid

from flask import Flask, request, jsonify
from flask_cors import CORS

from config import (
    UPLOAD_DIR,
    ALLOWED_EXTS,
    MAX_CONTENT_MB,
    SECRET_KEY
)

from predict import (
    predict_image,
    load_model,
    get_class_names
)

from recommendation import (
    get_recommendation
)

from database import (
    init_db,
    save_prediction,
    get_all_predictions,
    get_prediction_by_id,
    delete_prediction,
    clear_all_predictions,
)

# ── Import auth handlers ──────────────────────────────────────────────────────
from auth import signup, login, me

# ==========================================
# APP SETUP
# ==========================================

app = Flask(__name__)
app.secret_key = SECRET_KEY
app.config["MAX_CONTENT_LENGTH"] = MAX_CONTENT_MB * 1024 * 1024

CORS(
    app,
    resources={r"/*": {"origins": "*"}},
    allow_headers=["Content-Type", "Authorization", "X-Requested-With"],
    methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    supports_credentials=False,
)

@app.before_request
def handle_options():
    if request.method == "OPTIONS":
        response = jsonify({"status": "ok"})
        response.headers["Access-Control-Allow-Origin"] = "*"
        response.headers["Access-Control-Allow-Methods"] = \
            "GET, POST, PUT, DELETE, OPTIONS"
        response.headers["Access-Control-Allow-Headers"] = \
            "Content-Type, Authorization, X-Requested-With"
        return response, 200

# ==========================================
# STARTUP
# ==========================================

with app.app_context():
    init_db()
    try:
        load_model()
        print("✅ Model loaded successfully.")
    except FileNotFoundError as e:
        print(f"⚠️  Warning: {e}")
    except Exception as e:
        print(f"❌ Model load error: {e}")

# ==========================================
# HELPERS
# ==========================================

def allowed_file(filename: str) -> bool:
    return (
        "." in filename
        and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTS
    )

def error(msg: str, code: int = 400):
    return jsonify({"success": False, "error": msg}), code

# ==========================================
# AUTH  ← THIS WAS MISSING — NOW FIXED
# ==========================================

app.add_url_rule("/auth/signup", view_func=signup, methods=["POST"])
app.add_url_rule("/auth/login",  view_func=login,  methods=["POST"])
app.add_url_rule("/auth/me",     view_func=me,      methods=["GET"])

# ==========================================
# HEALTH
# ==========================================

@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "service": "Crop Disease API"}), 200

# ==========================================
# CLASSES
# ==========================================

@app.route("/classes", methods=["GET"])
def classes():
    names = get_class_names()
    return jsonify({"success": True, "classes": names, "count": len(names)}), 200

# ==========================================
# MODEL INFO
# ==========================================

@app.route("/model-info", methods=["GET"])
def model_info():
    from predict import _model
    if _model is None:
        return jsonify({"success": False, "error": "Model not loaded"}), 503
    params = sum(p.numel() for p in _model.parameters()) / 1e6
    return jsonify({
        "success":      True,
        "model_type":   type(_model).__name__,
        "parameters_M": round(params, 2),
        "class_names":  get_class_names(),
        "num_classes":  len(get_class_names())
    }), 200

# ==========================================
# PREDICT
# ==========================================

@app.route("/predict", methods=["POST"])
def predict():
    if "file" not in request.files:
        return error("No file part in request.")

    file = request.files["file"]

    if not file:
        return error("No file selected")
    if file.filename == "":
        return error("No filename selected")
    if not allowed_file(file.filename):
        return error("Unsupported file type")

    ext       = file.filename.rsplit(".", 1)[1].lower()
    safe_name = f"{uuid.uuid4().hex}.{ext}"
    save_path = os.path.join(UPLOAD_DIR, safe_name)
    file.save(save_path)

    try:
        result = predict_image(save_path)
    except Exception as e:
        if os.path.exists(save_path):
            os.remove(save_path)
        return error(f"Prediction failed: {e}", 500)

    label      = result["label"]
    confidence = result["confidence"]
    rec        = get_recommendation(label)

    record_id = None
    try:
        record    = save_prediction(safe_name, label, confidence, rec)
        record_id = record.get("id")
    except Exception as e:
        print("DB Error:", e)

    return jsonify({
        "success":         True,
        "record_id":       record_id,
        "filename":        safe_name,
        "predicted_label": label,
        "confidence":      confidence,
        "confidence_pct":  f"{confidence * 100:.2f}%",
        "recommendation":  rec,
        "top_5": sorted(
            result["probabilities"].items(),
            key=lambda x: x[1],
            reverse=True
        )[:5],
    }), 200

# ==========================================
# HISTORY
# ==========================================

@app.route("/history", methods=["GET"])
def history():
    limit   = request.args.get("limit", 50, type=int)
    records = get_all_predictions(limit=limit)
    return jsonify({"success": True, "count": len(records), "records": records}), 200

@app.route("/history/<string:record_id>", methods=["GET"])
def history_detail(record_id):
    record = get_prediction_by_id(record_id)
    if not record:
        return error("Not found", 404)
    return jsonify({"success": True, "record": record})

@app.route("/history/<string:record_id>", methods=["DELETE"])
def delete_record(record_id):
    ok = delete_prediction(record_id)
    if not ok:
        return error("Not found", 404)
    return jsonify({"success": True})

@app.route("/history", methods=["DELETE"])
def clear_history():
    count = clear_all_predictions()
    return jsonify({"success": True, "message": f"Deleted {count}"})

# ==========================================
# RUN (local only — Render uses gunicorn)
# ==========================================

if __name__ == "__main__":
    import platform
    reloader = platform.system() != "Windows"
    app.run(
        debug=True,
        host="0.0.0.0",
        port=5000,
        use_reloader=reloader,
        threaded=True,
    )