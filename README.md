<div align="center">

<br/>

```
░█████╗░██╗░░░░░░█████╗░░██████╗░░█████╗░██╗░░██╗██╗░░░██╗██████╗░
██╔══██╗██║░░░░░██╔══██╗██╔════╝░██╔══██╗██║░░██║██║░░░██║██╔══██╗
███████║██║░░░░░███████║██║░░██╗░███████║███████║██║░░░██║██████╦╝
██╔══██║██║░░░░░██╔══██║██║░░╚██╗██╔══██║██╔══██║██║░░░██║██╔══██╗
██║░░██║███████╗██║░░██║╚██████╔╝██║░░██║██║░░██║╚██████╔╝██████╦╝
╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝░╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝░╚═════╝░╚═════╝░
```

### *Bridging Patients and Healthcare Workers — Seamlessly.*

<br/>

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Active-brightgreen?style=for-the-badge)

</div>

---

## 🩺 What is AlagaHub?

**AlagaHub** is a cross-platform mobile application built with Flutter that connects **patients** with **healthcare workers** in a streamlined, accessible way. Whether you're booking a consultation, messaging your doctor, or managing your health profile — AlagaHub brings it all into one place.

> *"Alaga"* (Filipino) — to care for, to tend to, to look after.

---

## ✨ Features

| Feature | Description |
|---|---|
| 🔐 **Authentication** | Phone number-based login with OTP verification via Firebase |
| 👤 **Multi-role System** | Separate experiences for Patients, Healthcare Workers, and Admins |
| 📅 **Appointment Booking** | Browse and book consultations with available healthcare workers |
| 💬 **Real-time Messaging** | In-app inbox for patient-worker communication |
| 💊 **Medicine Tab** | Track and manage medicine-related information |
| 🔔 **Notifications** | Stay updated on appointments and messages |
| 🌐 **Offline Support** | Connectivity-aware with background sync service |
| 🌍 **Multi-language Ready** | Language selection support built in |

---

## 🏗️ Project Structure

```
alagahub/
├── lib/
│   ├── main.dart                  # App entry point
│   ├── firebase_options.dart      # Firebase configuration
│   ├── screens/
│   │   ├── auth/                  # Login, OTP, Onboarding
│   │   ├── registration/          # Multi-step registration flow
│   │   ├── patient/               # Patient shell & tabs
│   │   ├── worker/                # Healthcare worker shell & tabs
│   │   ├── admin/                 # Admin shell
│   │   └── settings/              # Account, help, language, notifications
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── booking_service.dart
│   │   ├── database_service.dart
│   │   ├── firebase_service.dart
│   │   ├── offline_sync_service.dart
│   │   └── connectivity_service.dart
│   ├── widgets/                   # Reusable UI components
│   ├── utils/                     # Theme, router, helpers
│   └── providers/                 # State management
├── android/
├── ios/
├── pubspec.yaml
└── firebase.json
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x or later)
- [Dart](https://dart.dev/get-dart)
- [Firebase CLI](https://firebase.google.com/docs/cli)
- An Android or iOS device / emulator

### Installation

**1. Clone the repository**
```bash
git clone https://github.com/zekeyell/AlagaHub.git
cd AlagaHub
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Set up Firebase**

> ⚠️ Firebase config files are excluded from this repo for security.

- Go to [Firebase Console](https://console.firebase.google.com/)
- Create a new project
- Add Android and/or iOS apps
- Download `google-services.json` → place in `android/app/`
- Download `GoogleService-Info.plist` → place in `ios/Runner/`
- Run `flutterfire configure` to generate `firebase_options.dart`

**4. Run the app**
```bash
flutter run
```

---

## 🔒 Security Notes

The following files are **intentionally excluded** from this repository via `.gitignore`:

```
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
firebase_options.dart
```

Never commit these files. Add your own when setting up locally.

---

## 🛠️ Built With

- **[Flutter](https://flutter.dev/)** — UI framework
- **[Firebase Auth](https://firebase.google.com/products/auth)** — Phone/OTP authentication
- **[Firebase Realtime Database](https://firebase.google.com/products/realtime-database)** — Live data sync
- **[Firebase Firestore](https://firebase.google.com/products/firestore)** — Structured data storage
- **[Go Router](https://pub.dev/packages/go_router)** — Navigation & routing

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

1. Fork the project
2. Create your branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 👥 The Team

AlagaHub was designed and developed by a group of 2nd Year BS Computer Science students from the **Technological University of the Philippines — Manila**.

<div align="center">

| | Name |
|:---:|:---|
| 🧑‍💻 | **Ezekiel Jairus Solitario** |
| 🧑‍💻 | **Zendy Santos** |
| 🧑‍💻 | **Jose Salvador Rentoria** |
| 🧑‍💻 | **Nicole Drew Lazo** |
| 🧑‍💻 | **Mitch Angela Maisog** |

🏫 **Technological University of the Philippines — Manila**
📚 BS Computer Science, 2nd Year

</div>

---

## 📄 License

This project is licensed under the MIT License.

---

## 🌍 SDG Alignment

AlagaHub is designed with the United Nations Sustainable Development Goals in mind:

| Goal | Description |
|---|---|
| 🟢 **SDG 3: Good Health & Well-being** | Improves access to healthcare services by connecting patients directly with healthcare workers through a digital platform |
| 🟠 **SDG 10: Reduced Inequalities** | Helps bridge the gap in healthcare access for underserved communities by making consultations and health services more reachable |

---

<div align="center">

*Made with ❤️ and Flutter*

<br/>

**AlagaHub v1.0 — Confidential Draft**

</div>
