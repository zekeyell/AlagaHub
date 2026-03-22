# AlagaHub — Rural Health Connect 🏥
**Healthcare kahit saan (Healthcare wherever you are)**

---

## Quick Start (VS Code)

### Prerequisites
- Flutter SDK 3.x+ → https://flutter.dev/docs/get-started/install
- Android Studio (for Android emulator) or Xcode (for iOS)
- VS Code with the **Flutter** and **Dart** extensions

### 1. Open in VS Code
```
File → Open Folder → select this `alagahub` folder
```

### 2. Run the error fixer
Open a terminal in VS Code (`Ctrl+`` ` ```) and run:
```bash
python fix_errors.py
```
This will:
- Create the Flutter project structure (`flutter create .`)
- Run `flutter pub get`
- Apply `dart fix --apply`
- Check Android permissions and build.gradle
- Verify Firebase config files

### 3. Run the app
```bash
flutter run
```
Or press **F5** in VS Code with an emulator/device connected.

---

## Demo Login (No Firebase Required)

The app ships with a **Demo Access panel** on the Login screen.
Tap the yellow panel and choose:

| Button | Role | Access |
|--------|------|--------|
| **Patient** | Pasyente | Home, Consultations, Medicine, Messages, Account |
| **Worker** | Healthcare Worker | Dashboard, Patients, Consultations, Medicine, Messages |
| **Admin** | System Admin | Dashboard, Users, Records, Content, Export |

> Remove the Demo panel before production — it's clearly marked in `lib/screens/auth/login_screen.dart`.

---

## Firebase Setup (OTP + Real-time Sync)

1. Create a Firebase project at https://console.firebase.google.com
2. Enable **Phone Authentication** (Authentication → Sign-in method → Phone)
3. Enable **Cloud Firestore**
4. Enable **Firebase Cloud Messaging**
5. Download config files:
   - **Android**: `google-services.json` → place in `android/app/`
   - **iOS**: `GoogleService-Info.plist` → place in `ios/Runner/`
6. In `lib/main.dart`, uncomment:
   ```dart
   await Firebase.initializeApp();
   ```
7. In `lib/services/auth_service.dart`, uncomment the `verifyPhone` method

---

## Google Maps Setup

1. Get an API key from https://console.cloud.google.com
2. Enable **Maps SDK for Android** and **Maps SDK for iOS**
3. Replace `YOUR_MAPS_API_KEY` in `android/app/src/main/AndroidManifest.xml`
4. For iOS, add to `ios/Runner/AppDelegate.swift`:
   ```swift
   GMSServices.provideAPIKey("YOUR_MAPS_API_KEY")
   ```

---

## SMS Health Center Number

Update the health center number in `lib/screens/patient/messages_tab.dart`:
```dart
const _healthCenterNumber = '+639XXXXXXXXXX'; // Replace with actual
```

---

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── utils/
│   ├── app_router.dart                # All routes (go_router)
│   ├── app_theme.dart                 # Colors, typography, components
│   └── id_generator.dart              # RHC-*, CASE-*, MED-* IDs
├── services/
│   ├── auth_service.dart              # Firebase phone auth
│   ├── database_service.dart          # SQLite offline DB
│   ├── connectivity_service.dart      # Online/offline detection
│   └── registration_provider.dart     # Registration state (Riverpod)
├── screens/
│   ├── auth/
│   │   ├── splash_screen.dart         # S01 — Auto-redirect
│   │   ├── onboarding_screen.dart     # S02 — 3 slides
│   │   ├── login_screen.dart          # Login + Demo panel
│   │   ├── phone_entry_screen.dart    # S03 — Phone input
│   │   ├── otp_verification_screen.dart # S04 — OTP verify
│   │   └── registration/
│   │       ├── reg_step1_screen.dart  # S05 — Personal info
│   │       ├── reg_step2_screen.dart  # S06 — Address
│   │       ├── reg_step3_screen.dart  # S07 — Health profile
│   │       ├── reg_step4_screen.dart  # S08 — Insurance
│   │       └── reg_review_screen.dart # S09 — Review & submit
│   ├── patient/
│   │   ├── patient_shell.dart         # Bottom nav (5 tabs)
│   │   ├── home_tab.dart              # S10 — Dashboard
│   │   ├── consultations_tab.dart     # S11-S15 — Consultations
│   │   ├── medicine_tab.dart          # S16-S20 — Medicine requests
│   │   ├── messages_tab.dart          # S21 — Native SMS messages
│   │   └── account_tab.dart          # S22 — Profile & records
│   ├── worker/
│   │   └── worker_shell.dart          # S23-S27 — Worker screens
│   └── admin/
│       └── admin_shell.dart           # S29-S33 — Admin drawer
└── widgets/
    ├── app_bar_widget.dart            # Consistent AppBar
    ├── connectivity_banner.dart       # Online/offline/syncing banner
    └── reg_progress_bar.dart          # Registration step indicator
```

---

## Architecture

- **Offline-first**: All patient data saved to SQLite (sqflite). Auto-syncs to Firebase when online.
- **Dual submission**: Every consultation/medicine request can be submitted online OR copied as SMS (no API cost).
- **Native SMS**: Uses `url_launcher` to open device SMS app with pre-filled message — zero cost, works offline.
- **State management**: Riverpod (`flutter_riverpod`) for all app state.
- **Navigation**: `go_router` with role-based redirects.
- **Authentication**: Firebase Phone Auth OTP + SharedPreferences session.

---

## SDG Alignment
- **SDG 3**: Good Health & Well-being
- **SDG 10**: Reduced Inequalities

---

*AlagaHub v1.0 — Confidential Draft*
