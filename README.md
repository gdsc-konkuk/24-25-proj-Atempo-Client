# [MediCall](https://atempo-medicall.vercel.app/)

<img src="https://github.com/user-attachments/assets/94009b08-9255-41e7-8422-2f607d19b346" width="200"/>

> **An AI-powered Emergency Room Matching System** connecting paramedics to the nearest available hospital in seconds.


## 🚨 The Problem: Critical Minutes Lost During Emergencies

During medical emergencies, **every second counts**. The "golden hour" - the critical time window immediately following a traumatic injury - is essential for patient survival. However, this precious time is often wasted when:

- Paramedics must **manually call multiple hospitals** to find an available emergency room
- Emergency Medical Technicians (EMTs) spend **valuable minutes on administrative tasks** instead of patient care
- Hospital selection is based on incomplete information, leading to **inefficient patient routing**
- **Communication delays** between ambulances and hospiatals create unnecessary wait times

These inefficiencies can mean the difference between life and death for critically injured patients.

## 💡 Our Solution: MediCall

MediCall revolutionizes emergency response by creating a direct, AI-powered connection between paramedics and available emergency rooms. The system:

- Allows paramedics to **quickly input patient condition and location data**
- Uses **Gemini AI to analyze patient information** and identify suitable hospitals
- **Automatically contacts multiple hospitals simultaneously** using Twilio API
- Collects **real-time availability data** through automated voice response systems
- **Recommends the optimal hospital** based on availability, proximity, and compatibility with the patient's condition
- Provides **turn-by-turn navigation guidance** to the selected facility



The result: **Hospital matching in under 1 minute**, 5x faster than traditional methods, with 100% secure patient data handling.

## 🛠️ Key Features

- **Chat-based Interface**: Quickly enter patient condition and location
- **Gemini AI**: Analyzes patient information, recommends suitable hospitals
- **Twilio API**: Parallel automated hospital calls IVR (1: Accept / 2: Reject via dial-tone)
- **TTS (Text-to-Speech)**: Delivers automated voice messages to hospitals
- **Mapbox Navigation**: Provides accurate, real-time route guidance
- **Material Design**: Intuitive UI aligned with Google's Material Design
- **EMT Verification**: Exclusive secure access for verified paramedics

### Differentiation from Existing Solutions

- Traditional methods rely heavily on **manual phone calls** or centralized emergency medical centers to verify hospital availability, leading to significant delays
- MediCall uniquely integrates Gemini AI and IVR API to **automatically and simultaneously contact multiple hospitals**, collect real-time responses, and instantly recommend the optimal hospital
- This greatly reduces the administrative workload for paramedics and helps preserve the critical golden hour for patients

## 🧑‍💻 Working Flow
![Group 96](https://github.com/user-attachments/assets/84170401-0e1a-4d0a-aa6d-04180c8b1e3e)



## 🧑‍💻 Technology Stack

### Google Technologies
- **Gemini API**: AI-driven data analysis and hospital candidate recommendation
- **Google Maps API**: Route guidance and mapping services
- **Google Sign-In**: OAuth authentication for secure login
- **Flutter**: Cross-platform mobile app development with Material Design
- **Flutter Material Design**: Consistent and intuitive UI design
- **Google Fonts**: Customizable and modern font integration

### Other Key Technologies
- **Twilio API**: Parallel phone calls, TTS (Text-to-Speech) call content, and dial response collection
- **MapBox API**: Real-time navigation and custom route guidance

### Full Stack Breakdown

| Area                   | Technologies                                  |
|------------------------|-----------------------------------------------|
| **Mobile**             | Flutter, Dart, Material Design                |
| **AI & Server**        | Gemini AI (hospital matching logic)           |
| **Communication**      | Twilio API (TTS & dial-tone responses)        |
| **Maps & Navigation**  | Mapbox Navigation API, Google Maps API        |
| **Authentication**     | Google Sign-In                               |
| **State Management**   | Provider                                      |
| **Secure Storage**     | flutter_secure_storage, shared_preferences    |
| **HTTP Communication** | Dio, HTTP, Cookie Management                  |
| **Deep Linking**       | Uni Links                                     |
| **Deployment**         | (Android) Firebase App Distribution, (iOS) TestFlight |

## 🏗️ System Architecture

MediCall's architecture is designed for speed, reliability, and security during emergency situations:

![Group 99](https://github.com/user-attachments/assets/3a615b44-283a-49dd-b1ff-f046ff34b5a5)

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

📌 **Demo EMT Verification Code**: Select `NREMT` and type `MED911`

## 📚 Frequently Asked Questions (FAQ)

### ❓ **Who can use MediCall?**
Currently, verified paramedics only. Future versions will include hospital search features for general public use.

### ❓ **How do hospitals respond?**
Hospitals receive automated voice messages detailing patient conditions. They reply using dial-tone inputs, which are recorded in real-time.

### ❓ **How is user data handled?**
MediCall does not store personal data (names, IDs). Information is encrypted and transmitted securely without storage.

### ❓ **Can MediCall be used outside emergencies?**
MediCall is exclusively for real emergencies or authorized training simulations. Unauthorized use is restricted.

## 📌 Project Specifications

| Item                  | Details                                                               |
|-----------------------|-----------------------------------------------------------------------|
| **Project Name**      | MediCall                                                              |
| **Objective**         | Real-time hospital matching to protect the golden hour                |
| **Target Users**      | Certified paramedics, healthcare professionals                        |
| **Regions Covered**   | Worldwide Coverage                                                    |
| **Unique Advantages** | AI-driven decision making, parallel calls, instant hospital matching  |


# Wanna See more Details? visit our [website](https://atempo-medicall.vercel.app/).

📧 **Contact:** [medicall.developer@gmail.com](mailto:medicall.developer@gmail.com)
