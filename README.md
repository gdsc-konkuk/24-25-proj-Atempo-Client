# MediCall

> An AI-based Emergency Room Matching System that connects emergency patients to the hospital that can admit them the fastest.

---

## 🚑 Project Overview

During patient transport, issues arise when hospitals cannot admit patients or lack available medical staff, causing a loss of the critical "golden time".  
**MediCall** allows paramedics to simply input patient condition and location; then, **AI simultaneously contacts nearby hospital emergency rooms** to  
**automatically recommend the first available hospital that responds**.

---

## 🛠 Key Features

- **Chat-based interface** for easy patient information entry
- **Gemini AI** for hospital candidate selection and message generation
- **Parallel calls using Twilio** → hospitals respond via dial (1: Accept / 2: Reject)
- **Optimal matching based on response speed and distance**
- **Real-time route guidance** via Google Maps API

---

## 🧩 System Architecture

```plaintext
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


## EMT License Information

The application supports different types of EMT license verification:

### License Types
- **NREMT**: National Registry of Emergency Medical Technicians (US)
- **KOREA**: Korean Emergency Medical Technician
- **EMS**: Emergency Medical Services

### License Number Formats
- **NREMT**: Alphanumeric (e.g., GDG143, MED911)
- **KOREA**: 6 digits (e.g., 123456)
- **EMS**: 12 digits (e.g., 123456789012)

This information is used during the verification process in the EMT License Verification screen.

---

## 🧑‍💻 Tech Stack

| Area      | Technologies                                             |
|-----------|----------------------------------------------------------|
| **Mobile**    | Flutter, Dart                                           |
| **Communication**  | Twilio (TTS Calls / Dial Response Handling)        |
| **Maps**  | Google Maps API                                          |
| **Deployment**  | (To be decided)                                      |

---

## 📌 Project Specification

| Item             | Details                                                          |
|------------------|------------------------------------------------------------------|
| Project Name     | MediCall                                                         |
| Objective        | Real-time hospital matching to secure the golden time for emergencies |
| Target Users     | Paramedics and healthcare professionals                          |
| Target Regions   | Korea, USA, and developing countries with limited infrastructure  |
| Differentiators  | Parallel simultaneous contact with hospitals, dial responses, AI recommendation |

---
