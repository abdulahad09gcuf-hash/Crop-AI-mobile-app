# 🌾 CropAI — Mobile App

> An AI-powered mobile application that detects crop diseases from photos, provides treatment recommendations, and helps farmers protect their harvest.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=flat&logo=fastapi&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=flat)

---

## ✨ Features

- 🔍 **Disease detection** — Snap a photo and get instant AI-powered crop disease diagnosis
- 💊 **Treatment advice** — Tailored treatment plans and pesticide recommendations
- 📊 **Dashboard** — Track scan history and monitor farm health over time
- 🔐 **Auth system** — Secure user accounts with JWT-based authentication
- 📱 **Cross-platform** — Runs on Android, iOS, Linux, and Windows from one codebase
- 🌐 **REST API** — FastAPI backend with well-documented endpoints

---

## 🚀 Quick Start

### Prerequisites

- Python 3.12+
- Flutter 3.x & Dart SDK
- Android Studio or VS Code

### Backend Setup

```bash
# Navigate to backend
cd "agri mobile app/backend"

# Install dependencies
pip install -r requirements.txt

# Start the server
python app.py
```

Server runs at `http://localhost:5000`

### Frontend Setup

```bash
# Navigate to frontend
cd "agri mobile app/frontend"

# Install Flutter dependencies
flutter pub get

# Run the app
flutter run
```

---

## 📁 Project Structure

```
crop_AI/
├── agri mobile app/
│   ├── backend/
│   │   ├── app.py              # Main FastAPI server
│   │   ├── predict.py          # AI disease prediction logic
│   │   ├── auth.py             # JWT authentication
│   │   ├── recommendation.py   # Treatment recommendations
│   │   ├── database.py         # Database models & queries
│   │   ├── config.py           # Configuration settings
│   │   └── requirements.txt    # Python dependencies
│   ├── frontend/
│   │   ├── lib/
│   │   │   ├── screens/        # App screens & UI
│   │   │   └── services/       # API service layer
│   │   ├── android/            # Android-specific files
│   │   ├── ios/                # iOS-specific files
│   │   └── pubspec.yaml        # Flutter dependencies
│   └── app.py                  # Root Flask app
└── README.md
```

---

## 🌐 API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/register` | Register a new user |
| POST | `/auth/login` | Login and receive JWT token |

### Disease Detection
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/predict` | Upload image for disease diagnosis |
| GET | `/history` | Get user's scan history |

### Recommendations
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/recommend/:disease` | Get treatment advice for a disease |

> All protected routes require `Authorization: Bearer <token>` header.

---

## 🧠 Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile frontend | Flutter + Dart |
| Backend API | Python + FastAPI |
| Authentication | JWT |
| Database | SQLite |
| AI/ML | Pytourch (image classification) |
| Platforms | Android, iOS, Linux, Windows |

---

## 📊 Model Info

- **16+ crop disease classes** detected
- **~95% accuracy** on test dataset
- Based on **PlantVillage dataset**
- Input: RGB crop leaf image
- Output: Disease name + confidence score + treatment recommendation

---

## 🤝 Contributing

Contributions are welcome!

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -m "Add my feature"`
4. Push to the branch: `git push origin feature/my-feature`
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License.

---

## 👨‍💻 Author

**Abdul Ahad** — [@abdulahad09gcuf-hash](https://github.com/abdulahad09gcuf-hash)

---

*Built with ❤️ to help farmers protect their crops using AI.*
