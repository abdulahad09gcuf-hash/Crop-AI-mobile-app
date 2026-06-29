# Crop Disease Detection — Backend API

## Folder Structure
```
backend/
├── app.py              ← Flask REST API (main entry point)
├── predict.py          ← Model loading & inference
├── recommendation.py   ← Disease → treatment mapping
├── database.py         ← SQLite ORM (SQLAlchemy)
├── config.py           ← All settings in one place
├── requirements.txt
├── model/
│   └── crop_model_final.pt   ← YOUR trained model goes here
└── uploads/            ← Auto-created; stores uploaded images
```

## Setup

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Place your model file
cp /path/to/crop_model_final.pt model/

# 3. Run the server
python app.py
# Server starts at http://localhost:5000
```

## API Endpoints

### POST /predict
Upload a crop leaf image and get prediction + recommendation.

```bash
curl -X POST http://localhost:5000/predict \
  -F "file=@leaf.jpg"
```

**Response:**
```json
{
  "success": true,
  "record_id": 1,
  "filename": "abc123.jpg",
  "predicted_label": "Tomato_Early_blight",
  "confidence": 0.9432,
  "confidence_pct": "94.32%",
  "recommendation": {
    "type": "Fungal Disease",
    "Fungicide": "Chlorothalonil 75% WP",
    "Rate": "2 g/l water",
    "Tip": "Remove infected lower leaves..."
  },
  "top_5": [
    ["Tomato_Early_blight", 0.9432],
    ["Tomato_Late_blight", 0.034],
    ...
  ]
}
```

### GET /history
```bash
curl http://localhost:5000/history?limit=20
```

### GET /history/<id>
```bash
curl http://localhost:5000/history/1
```

### DELETE /history/<id>
```bash
curl -X DELETE http://localhost:5000/history/1
```

### DELETE /history
```bash
curl -X DELETE http://localhost:5000/history
```

### GET /classes
```bash
curl http://localhost:5000/classes
```

### GET /health
```bash
curl http://localhost:5000/health
```

## Config (config.py)
| Key | Default | Description |
|-----|---------|-------------|
| MODEL_PATH | model/crop_model_final.pt | Path to .pt file |
| IMG_SIZE | 224 | Input image size |
| NUM_CLASSES | 16 | Number of output classes |
| DEVICE | cpu | cpu or cuda |
| MAX_CONTENT_MB | 10 | Max upload size in MB |

## Supported Classes (16)
- Magnessium deficiency
- Nitrogen_Deficiency
- Pepper__bell___Bacterial_spot
- Pepper__bell___healthy
- Phosphorous deficiency
- Potato___Early_blight
- Potato___Late_blight
- Potato___healthy
- Pottasium deficiency
- Tomato_Bacterial_spot
- Tomato_Early_blight
- Tomato_Late_blight
- Tomato_Leaf_Mold
- Tomato_Septoria_leaf_spot
- Tomato__Target_Spot
- Tomato_healthy
