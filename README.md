# EduCheck — University Check-in & Reflection

A Flutter MVP for students to check in to class using **GPS + QR code**, with pre- and post-class reflections stored locally via SQLite (or browser `localStorage` on web).

---

## Features

| Feature | Description |
|---|---|
| **Check-In** | Capture GPS location, scan class QR code, log Previous Topic, Expected Topic, and Mood (1–5 emoji slider) |
| **Finish Class** | Capture GPS, scan QR, log What I Learned and Instructor Feedback |
| **Session History** | Expandable list of all sessions with full detail view |
| **Cross-platform Storage** | SQLite on Android/iOS; `SharedPreferences` (localStorage) on Web |
| **Firebase Hosting** | Flutter Web build deployable via `firebase deploy` |

---

## Project Structure

```
lib/
├── main.dart                    # App entry + Provider setup
├── models/
│   └── class_session.dart       # Data model + SQLite serialisation
├── services/
│   └── database_helper.dart     # SQLite (native) / SharedPreferences (web)
├── providers/
│   └── session_provider.dart    # Global state (active session + history)
├── screens/
│   ├── home_screen.dart         # Dashboard with status banner & stats
│   ├── checkin_screen.dart      # GPS + QR + pre-class reflection form
│   ├── finish_screen.dart       # GPS + QR + post-class reflection form
│   ├── history_screen.dart      # Expandable session history list
│   └── qr_scanner_screen.dart  # Full-screen camera QR scanner
└── widgets/
    ├── mood_slider.dart          # Emoji mood slider (1–5)
    └── form_widgets.dart         # SectionHeader, ActionTile, ScreenScaffold
```

---

## Prerequisites

| Tool | Minimum Version |
|---|---|
| Flutter SDK | 3.19+ (Dart ≥ 3.3) |
| Android Studio / Xcode | Latest stable |
| Firebase CLI | 13+ |
| Node.js | 18+ (required by Firebase CLI) |

---

## Local Setup

### 1. Generate platform files

```bash
# Inside the project root — this generates android/, ios/, web/ etc.
flutter create . --project-name edu_check
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Android permissions

Add the following inside `<manifest>` in `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- GPS -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Camera (QR scanner) -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
```

Also set `minSdkVersion 21` in `android/app/build.gradle`:

```groovy
defaultConfig {
    minSdkVersion 21
    targetSdkVersion 34
    // ...
}
```

### 4. iOS permissions

Add to `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>EduCheck uses your location to verify class attendance.</string>
<key>NSCameraUsageDescription</key>
<string>EduCheck uses the camera to scan the class QR code.</string>
```

### 5. Run the app

```bash
# Android / iOS
flutter run

# Web (local preview)
flutter run -d chrome
```

---

## Firebase Hosting Deployment

### Step 1 — Create a Firebase project

1. Go to [console.firebase.google.com](https://console.firebase.google.com).
2. Click **Add project** and follow the wizard (Analytics is optional).
3. Note your **Project ID** (e.g. `edu-check-prod`).

### Step 2 — Install & log in with Firebase CLI

```bash
npm install -g firebase-tools
firebase login
```

### Step 3 — Update `.firebaserc`

Replace `YOUR_FIREBASE_PROJECT_ID` in `.firebaserc` with your actual Project ID:

```json
{
  "projects": {
    "default": "edu-check-prod"
  }
}
```

### Step 4 — Build Flutter Web

```bash
flutter build web --release
```

The output is placed in `build/web/`. The `firebase.json` already points there.

### Step 5 — Deploy

```bash
firebase deploy --only hosting
```

Firebase CLI will print a **Hosting URL** like:
```
https://edu-check-prod.web.app
```

### Step 6 — (Optional) Custom domain

In the Firebase Console → Hosting → **Add custom domain** and follow the DNS verification steps.

---

## Web Storage Note

On the web build `sqflite` is not available. `DatabaseHelper` automatically falls back to **`SharedPreferences`** (browser `localStorage`), so session data persists across page refreshes but is device/browser-local and not synced to a server.

---

## Future Roadmap

- [ ] Firebase Auth (Google SSO) for multi-student support
- [ ] Firestore sync for instructor dashboard
- [ ] Geofence validation (alert if GPS is outside campus boundary)
- [ ] Weekly mood trend charts
- [ ] Export sessions to PDF / CSV

---

## Dependencies

| Package | Purpose |
|---|---|
| `provider` | State management |
| `sqflite` | SQLite on Android/iOS |
| `shared_preferences` | localStorage on Web |
| `geolocator` | GPS coordinate capture |
| `mobile_scanner` | QR / Barcode camera scanning |
| `uuid` | RFC 4122 unique session IDs |
| `intl` | Date / time formatting |
| `path` + `path_provider` | Database file path resolution |

---

## License

MIT — free to use, modify, and distribute.