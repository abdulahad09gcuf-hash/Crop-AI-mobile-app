"""
JWT Authentication — signup, login, token verification.
Uses PyJWT + bcrypt. Stores users in MongoDB 'users' collection.
"""

import datetime
import functools
import os

import bcrypt
import jwt
from bson import ObjectId
from flask import request, jsonify

from config import JWT_SECRET, JWT_EXPIRY_HOURS
from database import db

# ── users collection ──────────────────────────────────────────────────────────
users_col = db["users"]
users_col.create_index("email", unique=True)


# ── helpers ───────────────────────────────────────────────────────────────────
def _hash_password(plain: str) -> str:
    return bcrypt.hashpw(plain.encode(), bcrypt.gensalt()).decode()


def _check_password(plain: str, hashed: str) -> bool:
    return bcrypt.checkpw(plain.encode(), hashed.encode())


def _make_token(user_id: str, email: str) -> str:
    payload = {
        "sub":   user_id,
        "email": email,
        "iat":   datetime.datetime.utcnow(),
        "exp":   datetime.datetime.utcnow()
                 + datetime.timedelta(hours=JWT_EXPIRY_HOURS),
    }
    return jwt.encode(payload, JWT_SECRET, algorithm="HS256")


def decode_token(token: str) -> dict:
    """
    Returns decoded payload or raises jwt.InvalidTokenError.
    """
    return jwt.decode(token, JWT_SECRET, algorithms=["HS256"])


# ── route handlers ────────────────────────────────────────────────────────────
def signup():
    """POST /auth/signup  { name, email, password }"""
    data = request.get_json(silent=True) or {}
    name     = (data.get("name",     "") or "").strip()
    email    = (data.get("email",    "") or "").strip().lower()
    password = (data.get("password", "") or "").strip()

    if not name or not email or not password:
        return jsonify({"success": False,
                        "error": "name, email and password are required"}), 400

    if len(password) < 6:
        return jsonify({"success": False,
                        "error": "Password must be at least 6 characters"}), 400

    if users_col.find_one({"email": email}):
        return jsonify({"success": False,
                        "error": "Email already registered"}), 409

    doc = {
        "name":     name,
        "email":    email,
        "password": _hash_password(password),
        "created_at": datetime.datetime.utcnow(),
    }
    result = users_col.insert_one(doc)
    uid    = str(result.inserted_id)
    token  = _make_token(uid, email)

    return jsonify({
        "success": True,
        "token":   token,
        "user":    {"id": uid, "name": name, "email": email},
    }), 201


def login():
    """POST /auth/login  { email, password }"""
    data = request.get_json(silent=True) or {}
    email    = (data.get("email",    "") or "").strip().lower()
    password = (data.get("password", "") or "").strip()

    if not email or not password:
        return jsonify({"success": False,
                        "error": "email and password are required"}), 400

    user = users_col.find_one({"email": email})
    if not user or not _check_password(password, user["password"]):
        return jsonify({"success": False,
                        "error": "Invalid email or password"}), 401

    uid   = str(user["_id"])
    token = _make_token(uid, email)

    return jsonify({
        "success": True,
        "token":   token,
        "user":    {"id": uid, "name": user.get("name",""), "email": email},
    }), 200


def me():
    """GET /auth/me  — returns logged-in user info from token."""
    auth = request.headers.get("Authorization", "")
    if not auth.startswith("Bearer "):
        return jsonify({"success": False, "error": "No token"}), 401
    token = auth[7:]
    try:
        payload = decode_token(token)
    except jwt.ExpiredSignatureError:
        return jsonify({"success": False, "error": "Token expired"}), 401
    except jwt.InvalidTokenError:
        return jsonify({"success": False, "error": "Invalid token"}), 401

    user = users_col.find_one({"_id": ObjectId(payload["sub"])})
    if not user:
        return jsonify({"success": False, "error": "User not found"}), 404

    return jsonify({
        "success": True,
        "user": {
            "id":    str(user["_id"]),
            "name":  user.get("name", ""),
            "email": user.get("email", ""),
            "joined": user["created_at"].strftime("%Y-%m-%d")
                      if "created_at" in user else "",
        },
    }), 200


# ── decorator ─────────────────────────────────────────────────────────────────
def jwt_required(f):
    """
    Decorator — protects a route.
    Injects `user_id` kwarg into the view function if it accepts it,
    otherwise just validates and proceeds.
    """
    @functools.wraps(f)
    def wrapper(*args, **kwargs):
        auth = request.headers.get("Authorization", "")
        if not auth.startswith("Bearer "):
            return jsonify({"success": False,
                            "error": "Authorization header missing"}), 401
        token = auth[7:]
        try:
            payload = decode_token(token)
        except jwt.ExpiredSignatureError:
            return jsonify({"success": False, "error": "Token expired"}), 401
        except jwt.InvalidTokenError:
            return jsonify({"success": False, "error": "Invalid token"}), 401

        # Optionally pass user_id to the view
        import inspect
        sig = inspect.signature(f)
        if "user_id" in sig.parameters:
            kwargs["user_id"] = payload["sub"]
        return f(*args, **kwargs)
    return wrapper