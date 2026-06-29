"""
MongoDB database layer using PyMongo.
All prediction CRUD is scoped to user_id for per-user data isolation.
"""

from datetime import datetime
from bson import ObjectId
from pymongo import MongoClient, DESCENDING
from pymongo.errors import ConnectionFailure
from config import DATABASE_URI

# ── Connection ────────────────────────────────────────────────────────────────
client = MongoClient(DATABASE_URI, serverSelectionTimeoutMS=5000)

try:
    client.admin.command("ping")
    print("✅ MongoDB connected successfully!")
except ConnectionFailure as e:
    print(f"❌ MongoDB connection failed: {e}")
    raise

db         = client.get_default_database()   # DB name comes from URI (agri_db)
collection = db["predictions"]


# ── Helpers ───────────────────────────────────────────────────────────────────
def _serialize(record: dict) -> dict:
    import json
    record["id"] = str(record.pop("_id"))
    if "user_id" in record:
        del record["user_id"]          # don't expose to client
    if isinstance(record.get("recommendation"), str):
        record["recommendation"] = json.loads(record["recommendation"])
    if isinstance(record.get("created_at"), datetime):
        record["created_at"] = record["created_at"].strftime("%Y-%m-%d %H:%M:%S")
    return record


def _user_filter(user_id: str | None) -> dict:
    """Returns a MongoDB filter dict scoped to the given user (or empty for all)."""
    if user_id:
        return {"user_id": user_id}
    return {}


# ── Init ──────────────────────────────────────────────────────────────────────
def init_db():
    collection.create_index([("created_at", DESCENDING)])
    collection.create_index("predicted_label")
    collection.create_index("user_id")          # for per-user queries
    print("✅ MongoDB indexes ready.")


# ── CRUD ──────────────────────────────────────────────────────────────────────
def save_prediction(
    filename: str,
    label: str,
    confidence: float,
    recommendation: dict,
    user_id: str | None = None,
) -> dict:
    doc = {
        "filename":        filename,
        "predicted_label": label,
        "confidence":      round(confidence, 4),
        "recommendation":  recommendation,
        "created_at":      datetime.utcnow(),
        "user_id":         user_id,
    }
    result = collection.insert_one(doc)
    doc["_id"] = result.inserted_id
    return _serialize(doc)


def get_all_predictions(limit: int = 50, user_id: str | None = None) -> list:
    filt = _user_filter(user_id)
    records = (
        collection.find(filt)
        .sort("created_at", DESCENDING)
        .limit(limit)
    )
    return [_serialize(r) for r in records]


def get_prediction_by_id(
    record_id: str, user_id: str | None = None
) -> dict | None:
    filt = {"_id": ObjectId(record_id)}
    if user_id:
        filt["user_id"] = user_id
    try:
        record = collection.find_one(filt)
    except Exception:
        return None
    return _serialize(record) if record else None


def delete_prediction(record_id: str, user_id: str | None = None) -> bool:
    filt = {"_id": ObjectId(record_id)}
    if user_id:
        filt["user_id"] = user_id
    try:
        result = collection.delete_one(filt)
        return result.deleted_count == 1
    except Exception:
        return False


def clear_all_predictions(user_id: str | None = None) -> int:
    filt = _user_filter(user_id)
    result = collection.delete_many(filt)
    return result.deleted_count


# ── Stats aggregation ─────────────────────────────────────────────────────────
def get_stats(user_id: str | None = None) -> dict:
    """Returns totals + per-label breakdown for the Analytics screen."""
    filt  = _user_filter(user_id)
    total = collection.count_documents(filt)

    pipeline = [
        {"$match": filt},
        {"$group": {
            "_id":   "$predicted_label",
            "count": {"$sum": 1},
            "avg_confidence": {"$avg": "$confidence"},
        }},
        {"$sort": {"count": -1}},
    ]
    by_label_raw = list(collection.aggregate(pipeline))
    by_label     = {
        r["_id"]: {"count": r["count"],
                   "avg_confidence": round(r["avg_confidence"], 3)}
        for r in by_label_raw
    }

    healthy    = sum(v["count"] for k, v in by_label.items()
                     if "healthy" in k.lower())
    deficiency = sum(v["count"] for k, v in by_label.items()
                     if any(w in k.lower() for w in
                            ["deficiency", "nitrogen", "phosphorous",
                             "potassium", "pottasium", "magnessium"]))
    diseased   = total - healthy - deficiency

    return {
        "total":      total,
        "healthy":    healthy,
        "diseased":   diseased,
        "deficiency": deficiency,
        "by_label":   by_label,
    }