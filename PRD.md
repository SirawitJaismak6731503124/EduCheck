# EduCheck — Product Requirements Document

**Version:** 1.0  
**Date:** March 13, 2026  
**Author:** Senior Flutter & Firebase Developer  

---

## 1. Problem Statement

University students frequently attend classes without reflecting on prior learning or setting intentional goals for each session. Instructors lack lightweight tools to capture real-time attendance combined with qualitative feedback. EduCheck bridges this gap by providing a mobile-first check-in system that combines:

- **Location verification** (GPS capture at check-in and check-out)  
- **Identity verification** (QR code scan per class event)  
- **Pre-class reflection** (previous topic recall, expected topic, mood)  
- **Post-class reflection** (what was learned, instructor feedback)

All data is persisted locally on-device using SQLite, with a Flutter Web build deployable to Firebase Hosting for a zero-backend MVP.

---

## 2. Goals & Non-Goals

### Goals
- Allow a student to check in to a class with GPS + QR + pre-class reflection form.
- Allow a student to check out with GPS + QR + post-class reflection form.
- Store all session data locally (SQLite on native, SharedPreferences on web).
- Provide a session history view with expandable detail cards.
- Be deployable to Firebase Hosting as a Flutter Web app.

### Non-Goals (v1)
- Instructor-side dashboard or admin panel.
- Real-time server sync or push notifications.
- Multi-user / multi-class scheduling.
- Authentication / login flows.

---

## 3. User Personas

| Persona | Description |
|---|---|
| **Student** | Primary user. Checks in/out of classes, fills in reflections. |
| **Instructor** *(future)* | Views exported session data or a web dashboard. |

---

## 4. User Flow

### 4.1 Check-In Flow

```
Home Screen
  └─ Tap "Check In"
       └─ Check-In Screen
            ├─ [1] Tap "Capture GPS"  → device location captured
            ├─ [2] Tap "Scan QR"      → camera opens, QR scanned & validated
            ├─ [3] Fill "Previous Topic" (text field, required)
            ├─ [4] Fill "Expected Topic" (text field, required)
            ├─ [5] Adjust "Mood Score" (slider 1–5 with emoji labels)
            └─ [6] Tap "Confirm Check-In"
                    → ClassSession created & saved to SQLite
                    → Navigate back to Home (Active Session banner shown)
```

### 4.2 Check-Out Flow

```
Home Screen (Active Session banner visible)
  └─ Tap "Finish Class"
       └─ Finish Screen
            ├─ [1] Tap "Capture GPS"  → end location captured
            ├─ [2] Tap "Scan QR"      → camera opens, QR scanned
            ├─ [3] Fill "What I Learned" (text area, required)
            ├─ [4] Fill "Instructor Feedback" (text area, required)
            └─ [5] Tap "Complete Session"
                    → ClassSession updated with check-out data
                    → Navigate back to Home (Idle state restored)
```

### 4.3 History Flow

```
Home Screen
  └─ Tap History icon (top-right)
       └─ History Screen
            └─ Scrollable list of all ClassSessions (newest first)
                 └─ Tap any card → Expanded detail view
```

---

## 5. Data Schema

### `ClassSession` Model

| Field | Type | Source | Description |
|---|---|---|---|
| `id` | `String` (UUID v4) | Auto-generated | Unique session identifier |
| `checkInTime` | `DateTime` | System clock | Timestamp when check-in was confirmed |
| `checkOutTime` | `DateTime?` | System clock | Timestamp when check-out was confirmed; null if active |
| `startLat` | `double` | GPS at check-in | Latitude at check-in location |
| `startLng` | `double` | GPS at check-in | Longitude at check-in location |
| `endLat` | `double?` | GPS at check-out | Latitude at check-out location |
| `endLng` | `double?` | GPS at check-out | Longitude at check-out location |
| `prevTopic` | `String` | User input | Topic covered in the previous class |
| `expectedTopic` | `String` | User input | Topic expected to be covered today |
| `mood` | `int` (1–5) | Slider | Pre-class mood score (1=Struggling, 5=Great) |
| `learnedText` | `String?` | User input | Post-class: what the student learned |
| `feedback` | `String?` | User input | Post-class: feedback about the instructor/session |

### SQLite Table: `sessions`

```sql
CREATE TABLE sessions (
  id            TEXT    PRIMARY KEY,
  checkInTime   TEXT    NOT NULL,
  checkOutTime  TEXT,
  startLat      REAL    NOT NULL,
  startLng      REAL    NOT NULL,
  endLat        REAL,
  endLng        REAL,
  prevTopic     TEXT    NOT NULL,
  expectedTopic TEXT    NOT NULL,
  mood          INTEGER NOT NULL,
  learnedText   TEXT,
  feedback      TEXT
);
```

---

## 6. Screen Specifications

### 6.1 Home Screen
- **Header banner:** Deep blue gradient when idle; green gradient when a session is active (shows topic, check-in time, mood emoji).
- **Primary CTA button:** "Check In" (blue) when idle; "Finish Class" (red) when active.
- **Stats row:** Two cards — total sessions count and completed sessions count.
- **History icon:** AppBar trailing action → navigates to History Screen.

### 6.2 Check-In Screen
- Two action tiles (GPS capture, QR scan) with live confirmation state (grey → green with ✓).
- Two text fields: Previous Topic, Expected Topic.
- `MoodSlider` widget: emoji display + label + Material Slider with 5 stops.
- "Confirm Check-In" button (disabled while submitting).

### 6.3 Finish Screen
- Session info card showing active session topic and check-in time.
- Two action tiles (GPS capture, QR scan).
- Two text areas: What I Learned, Instructor Feedback.
- "Complete Session" button.

### 6.4 QR Scanner Screen
- Full-screen camera view via `mobile_scanner`.
- Overlay frame with corner markers.
- Instruction text at bottom.
- Auto-pops and returns scanned string on first valid scan.

### 6.5 History Screen
- Empty state with icon when no sessions exist.
- `ExpansionTile` cards per session: mood emoji avatar, topic title, date, active badge.
- Expanded view: all session fields rendered in a two-column detail layout.

---

## 7. Technical Architecture

```
lib/
├── main.dart                    # App entry + ChangeNotifierProvider
├── models/
│   └── class_session.dart       # Data model + toMap/fromMap
├── services/
│   └── database_helper.dart     # SQLite (native) + SharedPreferences (web)
├── providers/
│   └── session_provider.dart    # Global state: active session + history
├── screens/
│   ├── home_screen.dart
│   ├── checkin_screen.dart
│   ├── finish_screen.dart
│   ├── history_screen.dart
│   └── qr_scanner_screen.dart
└── widgets/
    ├── mood_slider.dart          # Reusable mood slider component
    └── form_widgets.dart         # Shared section header + action tile
```

### State Management
- **Provider** (`ChangeNotifier`) holds `activeSession` and `sessions` list.
- Loading triggered on app startup via `SessionProvider.loadData()`.

### Storage Strategy
| Platform | Storage |
|---|---|
| Android / iOS | SQLite via `sqflite` |
| Web (Firebase Hosting) | `SharedPreferences` (browser localStorage via JSON) |

---

## 8. Acceptance Criteria

| # | Criteria |
|---|---|
| AC-1 | User can check in with GPS + QR + form; session persists across app restart (native). |
| AC-2 | Only one active session at a time; "Check In" button is replaced by "Finish Class". |
| AC-3 | QR scanner detects and returns barcode value; screen auto-closes on scan. |
| AC-4 | GPS coordinates are displayed (5 decimal places) after capture. |
| AC-5 | Mood slider renders correct emoji for each of the 5 levels. |
| AC-6 | History screen shows all sessions, newest first, with full details expandable. |
| AC-7 | Flutter Web build deploys successfully to Firebase Hosting. |

---

## 9. Future Enhancements (v2+)

- Firebase Firestore sync for cloud backup and instructor dashboard.
- Firebase Authentication (Google SSO) for multi-user support.
- Class schedule integration (import iCal / Google Calendar).
- Weekly reflection summary with charts (mood trends, topics covered).
- Export to PDF / CSV for academic records.
- Geofence validation (alert if check-in GPS is outside campus boundary).
