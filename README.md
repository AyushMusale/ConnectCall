# ConnectCall

> **"Stay close, no matter the distance"**  
> A real-time, peer-to-peer audio and video calling application built with Flutter, Firebase, and WebRTC.

---

## 📱 Project Description

**ConnectCall** is a modern cross-platform communication application built to deliver seamless, low-latency audio and HD video calls. It combines Google's WebRTC engine for peer-to-peer media streaming with Firebase Cloud Firestore for lightning-fast signaling and session orchestration. The UI is designed with a warm, modern aesthetic featuring responsive glassmorphic layouts, floating action docks, dynamic call statuses, and real-time profile synchronization.

---

## ✨ Features

- **Authentication & Session Management**
  - Secure email & password registration and login via Firebase Authentication.
  - Automatic session restoration on app launch with splash screen routing.
  - Profile state reset on sign-out with cached session invalidation.

- **Real-Time 1-on-1 Audio & Video Calling**
  - Peer-to-peer (P2P) WebRTC communication for ultra-low latency voice and video.
  - Instant signaling using Cloud Firestore (SDP offer/answer exchange, trickle ICE candidate gathering).
  - Outgoing call screen (`MakeCallPage`) with ringing feedback and auto-start capability.
  - Incoming call dialog (`PickupCallPage`) with audio/video indicators, caller details, and 30-second timeout.
  - Symmetrical In-Call Experience (`OnCallPage`): full-screen remote video, floating picture-in-picture local preview (bottom-right), and responsive action controls dock.

- **In-Call Controls**
  - Microphone mute/unmute toggle.
  - Camera enable/disable (privacy mode).
  - Front / rear camera switching.
  - Speakerphone / earpiece audio routing toggle.
  - Live call duration timer and one-touch call termination.

- **Contacts Management**
  - Real-time contact directory populated from Firestore `/profile` documents (automatically excluding current user).
  - Instant search filtering by name and email prefix.
  - Quick-action buttons to initiate instant audio or video calls.

- **Call History Logs**
  - Comprehensive call logs tracking incoming, outgoing, and missed calls.
  - Call duration formatting, timestamp display, and media type indicators.
  - Filter chips for All, Missed, and Incoming call history.
  - Direct redial from any call history entry.

- **User Profile**
  - UI matching design specification ([`profile.png`](./profile.png)).
  - Circular avatar with camera edit badge overlay.
  - Editable user display name with real-time sync across Firestore and Firebase Auth (`currentUser.updateDisplayName`).
  - Dedicated Log Out button with confirmation and clean state teardown.

- **Floating Capsule Navigation**
  - Floating bottom navigation dock (`AppBottomNav`) with smooth animations across **Calls**, **Contacts**, and **Profile**.

---

## 🛠️ Flutter & Dart Version

- **Flutter SDK**: `3.29.0` (channel stable)
- **Dart SDK**: `^3.7.0`
- **Framework Compatibility**: Material 3 Design (`useMaterial3: true`)

---

## 📦 Packages Used

| Package | Version | Purpose |
|---|---|---|
| [`flutter_bloc`](https://pub.dev/packages/flutter_bloc) | `^9.1.1` | Predictable state management (AuthBloc, ContactBloc, HistoryBloc, CallBloc) |
| [`get_it`](https://pub.dev/packages/get_it) | `^8.0.3` | Inversion of Control & service locator dependency injection |
| [`go_router`](https://pub.dev/packages/go_router) | `^15.1.2` | Declarative URL-based routing and deep linking |
| [`firebase_core`](https://pub.dev/packages/firebase_core) | `^4.14.0` | Firebase platform initialization and app bindings |
| [`firebase_auth`](https://pub.dev/packages/firebase_auth) | `^6.5.7` | User authentication, token lifecycle, and session tracking |
| [`cloud_firestore`](https://pub.dev/packages/cloud_firestore) | `^6.1.2` | Real-time database for signaling, user profiles, and call history |
| [`flutter_webrtc`](https://pub.dev/packages/flutter_webrtc) | `^1.6.2+hotfix.1` | WebRTC audio/video capture, peer connection, and rendering |
| [`permission_handler`](https://pub.dev/packages/permission_handler) | `^13.0.2` | Android & iOS runtime permissions for Camera and Microphone |
| [`flutter_test`](https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html) | SDK | Unit, BLoC, and widget interaction test suites |
| [`flutter_lints`](https://pub.dev/packages/flutter_lints) | `^5.0.0` | Recommended Dart and Flutter code linting rules |

---

## 🏗️ Architecture

ConnectCall is built using **Clean Architecture** principles combined with the **BLoC (Business Logic Component)** design pattern:

```
connectcall/lib/
├── core/
│   └── router/
│       └── app_router.dart            # GoRouter configuration & routes
├── models/
│   ├── call_model.dart                # WebRTC Call entity & status enums
│   ├── contacts_model.dart            # Contact directory models
│   ├── profile_model.dart             # User profile data model
│   └── user_model.dart                # User credentials model
├── services/
│   ├── firebase/
│   │   ├── auth.service.dart          # Firebase Auth operations
│   │   ├── contact.service.dart       # Firestore contact queries
│   │   ├── history.service.dart       # Call history logging
│   │   ├── home.service.dart          # Home call log feed
│   │   ├── login.service.dart         # Login handling
│   │   ├── profile.service.dart       # Profile updates (name, avatar, signOut)
│   │   ├── search.service.dart        # Firestore search querying
│   │   ├── session.service.dart       # Session verification & restore
│   │   └── signaling.service.dart     # WebRTC signaling via Firestore
│   ├── calls.service.dart             # High-level calling coordinator
│   ├── permissions.service.dart       # Runtime camera/mic permissions
│   └── webRTC.service.dart            # RTCPeerConnection & MediaStream wrapper
├── usecases/
│   └── auth/
│       ├── login_usecase.dart         # Encapsulated login logic
│       └── signup_usecase.dart        # Encapsulated sign-up logic
├── screens/
│   ├── auth/                          # Login & SignUp views and AuthBloc
│   ├── call/                          # MakeCall, PickupCall, OnCall & CallBloc
│   ├── contacts/                      # Contacts directory & ContactBloc
│   ├── home/                          # Call history feeds & HistoryBloc
│   ├── profile/                       # User profile view & editor
│   └── splash/                        # Splash screen session router
├── widgets/
│   ├── app_bottom_nav.dart            # Capsule bottom navigation bar
│   ├── app_header.dart                # Brand top header & incoming call listener
│   └── brand_logo.dart                # Brand typography widget
├── injection.dart                     # GetIt dependency injection registry
├── firebase_options.dart              # FlutterFire platform configuration
└── main.dart                          # App entry point & MultiBlocProvider
```

### Key Architectural Highlights
- **Unidirectional Data Flow**: BLoCs emit immutable states in response to strongly-typed events; widgets rebuild reactively.
- **Service Decoupling**: All services are registered via `GetIt` and accept optional client instances in constructors for full offline unit and widget testability.
- **Resilient Fallbacks**: Services gracefully handle uninitialized Firebase environments (e.g. offline test harnesses) by falling back to mock or cached data.

---

## ☁️ Backend Used

- **Google Firebase**:
  - **Firebase Authentication**: User identity management, email/password verification, and bearer token refreshes.
  - **Cloud Firestore**:
    - `/profile/{uid}`: Profile documents containing `name`, `namelower` (for case-insensitive search), `email`, and `avatar`.
    - `/calls/{callId}`: Real-time signaling documents storing call participants (`callerId`, `receiverId`), status (`ringing`, `ongoing`, `ended`, `rejected`, `missed`), media type (`audio`, `video`), and SDP offer/answer payloads.
    - `/calls/{callId}/callerCandidates` & `/receiverCandidates`: Sub-collections for trickling ICE candidates.
    - `/history/{uid}/logs/{callId}`: Call history records including durations and timestamps.

---

## 📡 Calling SDK Used

- **`flutter_webrtc` (WebRTC P2P)**
  - Direct peer-to-peer audio and video transmission.
  - Hardware-accelerated rendering using `RTCVideoRenderer`.
  - Configured with Google public STUN servers for NAT discovery:
    - `stun:stun.l.google.com:19302`
    - `stun:stun1.l.google.com:19302`
  - Audio constraints configured for voice optimization: echo cancellation, auto gain control, and noise suppression.

---

## 🚀 Setup Instructions

### Prerequisites
1. Install [Flutter SDK 3.29.x](https://docs.flutter.dev/get-started/install) and ensure `flutter doctor` passes.
2. Install Android Studio (with Android SDK platform-tools) or Xcode for iOS development.
3. Install [Firebase CLI](https://firebase.google.com/docs/cli) and [FlutterFire CLI](https://firebase.flutter.dev/docs/cli).

### Installation Steps

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/AyushMusale/ConnectCall.git
   cd ConnectCall/connectcall
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Platform Permissions Setup**:
   - **Android (`android/app/src/main/AndroidManifest.xml`)**:
     Ensure the following permissions are present:
     ```xml
     <uses-permission android:name="android.permission.CAMERA" />
     <uses-permission android:name="android.permission.RECORD_AUDIO" />
     <uses-permission android:name="android.permission.INTERNET" />
     <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
     <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
     <uses-permission android:name="android.permission.BLUETOOTH" />
     ```
   - **iOS (`ios/Runner/Info.plist`)**:
     Ensure camera and microphone privacy strings are present:
     ```xml
     <key>NSCameraUsageDescription</key>
     <string>ConnectCall requires camera access for video calling.</string>
     <key>NSMicrophoneUsageDescription</key>
     <string>ConnectCall requires microphone access for audio and video calling.</string>
     ```

4. **Run the App**:
   ```bash
   # Run on connected device or emulator
   flutter run
   ```

5. **Run Automated Tests**:
   ```bash
   # Run profile service and profile UI tests
   flutter test test/profile_service_test.dart test/profile_page_test.dart
   ```

---

## 🔐 Environment Variables & Configuration

- **Firebase Configuration**:
  Pre-configured in [`connectcall/lib/firebase_options.dart`](connectcall/lib/firebase_options.dart) using the `connect-call-cb941` Firebase project. To configure your own Firebase project, run:
  ```bash
  flutterfire configure
  ```
- **WebRTC ICE Server Configuration**:
  Configured in [`connectcall/lib/services/webRTC.service.dart`](connectcall/lib/services/webRTC.service.dart):
  ```dart
  Map<String, dynamic> configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
  };
  ```

---

## ⚠️ Known Limitations

1. **NAT Traversal in Restrictive Networks**:
   WebRTC currently utilizes public STUN servers. Under symmetric NATs or restrictive corporate firewalls, a TURN relay server (e.g. Coturn or Twilio Network Traversal) is required for guaranteed connection establishment.
2. **One-on-One Calling Only**:
   The current architecture is optimized for peer-to-peer 1-on-1 voice and video calling. Multi-party conferencing requires a Selective Forwarding Unit (SFU) or MCU (e.g. LiveKit, mediasoup).
3. **Background Push Notifications**:
   Incoming call alerts are listened to in real-time while the application is active in foreground. Full background / terminated device ringing requires integrating Apple Push Notification Service (APNs) with CallKit on iOS, and Firebase Cloud Messaging (FCM) with Android Full-Screen Intent ConnectionService.

---

## 🤖 AI Tools Used

- **Antigravity AI (by Google DeepMind)**:
  - Implementation of WebRTC SDP and ICE signaling services with Firestore.
  - BLoC state management and event-driven calling workflow.
  - Responsive pixel-perfect UI replication from visual design mockups (`profile.png`, `on_call_page.png`, `pickup-call-page.png`).
  - Unit and widget test suite generation and regression verification.
  - **ChatGpt**
  - UI Design
