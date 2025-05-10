# MediCall

> **An AI-powered Emergency Room Matching System** connecting emergency patients to the nearest available hospital in seconds.

---

## 🚑 Project Overview

During emergency transport, critical time is often lost when paramedics must manually contact hospitals to find an available bed. **MediCall** streamlines this process by allowing paramedics to input patient details and location, after which **AI simultaneously contacts multiple hospitals**, recommending the first hospital that confirms availability. This approach ensures swift decision-making, protecting the vital "golden hour" for emergency treatment.

---

## 🛠 Key Features

- **Chat-based Interface**: Quickly enter patient condition and location.
- **Gemini AI**: Analyzes patient information, recommends suitable hospitals.
- **Twilio API**: Parallel automated hospital calls (1: Accept / 2: Reject via dial-tone).
- **TTS (Text-to-Speech)**: Delivers automated voice messages to hospitals.
- **Mapbox Navigation**: Provides accurate, real-time route guidance.
- **Material Design**: Intuitive UI aligned with Google's Material Design.
- **EMT Verification**: Exclusive secure access for verified paramedics.

---

## 📱 How MediCall Works

```

[Paramedics - Flutter App] 
  → Send patient condition and location
       ↓
[Server - Gemini AI] 
  → Select hospital list and generate guidance message
       ↓
[Twilio] 
  → Parallel calls; hospital responds with dial (1: Accept / 2: Reject)
       ↓
[Analyze response results + calculate distance]
       ↓
[Final hospital recommendation + Google Maps route guidance]

```

---

## 👨‍⚕️ EMT Verification

MediCall access is exclusively for **verified paramedics**. EMT credentials must be verified during initial signup.

### Supported EMT License Types:
- **NREMT**: National Registry of Emergency Medical Technicians (US)
- **KOREA**: Korean Emergency Medical Technician
- **EMS**: General Emergency Medical Services

### License Number Formats:
- **NREMT**: Alphanumeric (e.g., GDG143, MED911)
- **KOREA**: 6-digit numeric (e.g., 123456)
- **EMS**: 12-digit numeric (e.g., 123456789012)

📌 **Demo EMT Verification Code**: `MED119`

*(Future updates will allow general users to locate emergency hospitals.)*

---

## 📚 Frequently Asked Questions (FAQ)


### ❓ **Who can use MediCall?**
Currently, verified paramedics only. Future versions will include hospital search features for general public use.

### ❓ **How do hospitals respond?**
Hospitals receive automated voice messages detailing patient conditions. They reply using dial-tone inputs, which are recorded in real-time.

### ❓ **How is user data handled?**
MediCall does not store personal data (names, IDs). Information is encrypted and transmitted securely without storage.

### ❓ **Can MediCall be used outside emergencies?**
MediCall is exclusively for real emergencies or authorized training simulations. Unauthorized use is restricted.

---

## 🧑‍💻 Tech Stack

| Area                   | Technologies                                  |
|------------------------|-----------------------------------------------|
| **Mobile**             | Flutter, Dart, Material Design                |
| **AI & Server**        | Gemini AI (hospital matching logic)           |
| **Communication**      | Twilio API (TTS & dial-tone responses)        |
| **Maps & Navigation**  | Mapbox Navigation API, Google Maps API        |
| **Authentication**     | 	Google Sign-In                               |
| **State Management**   | Provider                                      |
| **Secure Storage**     | flutter_secure_storage, shared_preferences    |
| **HTTP Communication** | Dio, HTTP, Cookie Management                  |
| **Deep Linking**       | Uni Links                                     |
| **Deployment**         | (Android)Firebase App Distribution, (iOS)TestFlight |

---

## 📌 Project Specifications

| Item                  | Details                                                               |
|-----------------------|-----------------------------------------------------------------------|
| **Project Name**      | MediCall                                                              |
| **Objective**         | Real-time hospital matching to protect the golden hour                |
| **Target Users**      | Certified paramedics, healthcare professionals                        |
| **Regions Covered**   | Worldwide Coverage                                                    |
| **Unique Advantages** | AI-driven decision making, parallel calls, instant hospital matching  |

---

📧 **Contact:** [medicall.developer@gmail.com](mailto:medicall.developer@gmail.com)