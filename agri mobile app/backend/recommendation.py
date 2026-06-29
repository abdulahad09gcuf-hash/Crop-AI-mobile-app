"""
Recommendation engine.
Maps predicted class label → treatment / fertilizer advice.
"""

recommendations = {
    "Magnessium deficiency": {
        "type":       "Nutrient Deficiency",
        "Fertilizer": "Magnesium Sulfate (Epsom Salt)",
        "Rate":       "25–50 kg/acre",
        "Tip":        "Apply foliar spray (2% MgSO4 solution) and incorporate dolomitic lime to improve soil Mg levels long-term.",
    },
    "Nitrogen_Deficiency": {
        "type":       "Nutrient Deficiency",
        "Fertilizer": "Urea (46-0-0)",
        "Rate":       "50 kg/acre",
        "Tip":        "Apply in split doses — 50% at planting, 50% at vegetative stage. Avoid excess to prevent leaching.",
    },
    "Pepper__bell___Bacterial_spot": {
        "type":       "Bacterial Disease",
        "Treatment":  "Copper-based bactericide (Copper Hydroxide)",
        "Rate":       "2–3 g/l water",
        "Tip":        "Remove and destroy infected leaves. Avoid overhead irrigation. Apply bactericide every 7–10 days.",
    },
    "Pepper__bell___healthy": {
        "type":   "Healthy",
        "Status": "✅ Healthy Plant",
        "Tip":    "Maintain regular irrigation, balanced NPK fertilization, and monitor weekly for early pest/disease signs.",
    },
    "Phosphorous  deficiency": {
        "type":       "Nutrient Deficiency",
        "Fertilizer": "DAP (Di-Ammonium Phosphate 18-46-0)",
        "Rate":       "40 kg/acre",
        "Tip":        "Apply near the root zone at planting. Acidic soils — raise pH to 6–7 for best phosphorus availability.",
    },
    "Potato___Early_blight": {
        "type":      "Fungal Disease",
        "Fungicide": "Mancozeb 75% WP",
        "Rate":      "2.5 g/l water",
        "Tip":       "Spray every 7–10 days. Avoid excess moisture. Remove lower infected leaves. Rotate crops annually.",
    },
    "Potato___Late_blight": {
        "type":      "Fungal Disease",
        "Fungicide": "Metalaxyl + Mancozeb",
        "Rate":      "2.5 g/l water",
        "Tip":       "Act fast — late blight spreads rapidly. Remove and destroy infected plants. Do NOT compost infected debris.",
    },
    "Potato___healthy": {
        "type":   "Healthy",
        "Status": "✅ Healthy Plant",
        "Tip":    "Continue regular care. Ensure proper hilling, adequate potassium, and scout for Colorado potato beetle.",
    },
    "Pottasium deficiency": {
        "type":       "Nutrient Deficiency",
        "Fertilizer": "Muriate of Potash (MOP / KCl 0-0-60)",
        "Rate":       "30 kg/acre",
        "Tip":        "Apply around the root zone. Avoid excess — high K can interfere with Mg and Ca uptake.",
    },
    "Tomato_Bacterial_spot": {
        "type":      "Bacterial Disease",
        "Treatment": "Copper Oxychloride spray",
        "Rate":      "3 g/l water",
        "Tip":       "Avoid overhead watering. Use drip irrigation. Apply copper spray preventively every 7 days in wet weather.",
    },
    "Tomato_Early_blight": {
        "type":      "Fungal Disease",
        "Fungicide": "Chlorothalonil 75% WP",
        "Rate":      "2 g/l water",
        "Tip":       "Remove infected lower leaves. Mulch around plants. Spray every 7–10 days starting at first symptom.",
    },
    "Tomato_Late_blight": {
        "type":      "Fungal Disease",
        "Fungicide": "Metalaxyl 8% + Mancozeb 64%",
        "Rate":      "2.5 g/l water",
        "Tip":       "Destroy all infected debris. Do not save seeds from infected plants. Apply fungicide at first sign.",
    },
    "Tomato_Leaf_Mold": {
        "type":      "Fungal Disease",
        "Treatment": "Copper-based fungicide or Chlorothalonil",
        "Rate":      "2 g/l water",
        "Tip":       "Improve air circulation. Reduce humidity in greenhouse. Avoid wetting foliage when watering.",
    },
    "Tomato_Septoria_leaf_spot": {
        "type":      "Fungal Disease",
        "Fungicide": "Mancozeb or Chlorothalonil",
        "Rate":      "2 g/l water",
        "Tip":       "Remove lower infected leaves immediately. Avoid splashing water on leaves. Rotate crops.",
    },
    "Tomato__Target_Spot": {
        "type":      "Fungal Disease",
        "Treatment": "Chlorothalonil or Azoxystrobin",
        "Rate":      "2 g/l water",
        "Tip":       "Avoid leaf wetness. Ensure proper plant spacing for air flow. Apply fungicide preventively.",
    },
    "Tomato_healthy": {
        "type":   "Healthy",
        "Status": "✅ Healthy Plant",
        "Tip":    "Maintain proper NPK fertilization, consistent watering, and stake plants for support. Scout weekly.",
    },
}


def get_recommendation(label: str) -> dict:
    """Return recommendation dict for a predicted class label."""
    return recommendations.get(
        label,
        {"message": f"No recommendation found for class: '{label}'"}
    )
