# 🎪 EventSphere — Event Equipment Rental System

> A comprehensive, full-stack event equipment rental platform featuring multi-role portals for Customers, Vendors, and Admins with real-time order tracking, messaging, analytics, and automated E2E testing suites.

----

## 📌 Table of Contents
- [✨ Key Features](#-key-features)
- [🛠️ Tech Stack](#️-tech-stack)
- [📁 Project Architecture](#-project-architecture)
- [🚀 Quick Start & Setup](#-quick-start--setup)
  - [Prerequisites](#prerequisites)
  - [Frontend Setup](#frontend-setup)
  - [Backend Setup](#backend-setup)
- [🧪 Automated Testing Suite](#-automated-testing-suite)
  - [Backend Security & Rules Simulation](#backend-security--rules-simulation)
  - [Frontend Flow Verification](#frontend-flow-verification)
- [📄 License](#-license)

---

## ✨ Key Features

### 🛒 Customer Portal
- **Catalog Browsing**: Explore event equipment by categories with search and dynamic filtering.
- **Product Details & Availability**: View item specifications, images, and rental pricing.
- **Cart & Checkout**: Interactive shopping cart with multi-item checkout and payment workflows.
- **Order Tracking**: Real-time status updates and order history.
- **Real-Time Communication**: In-app chat with vendors and support representatives.

### 🏪 Vendor Management
- **Inventory Control**: Add, update, and manage rental product listings.
- **Order Management**: Track customer orders and update rental fulfillment statuses in real time.

### 🛡️ Admin Dashboard
- **Platform Analytics**: Visualized revenue, booking trends, and user statistics powered by `fl_chart`.
- **User & Vendor Control**: Comprehensive user management and vendor onboarding approval workflows.

### 🔔 System Infrastructure
- **Real-time Notifications**: Firebase Messaging (FCM) and local notification integration.
- **Granular Security**: Fine-grained Firestore security rules and structured backend cloud functions.

---

## 🛠️ Tech Stack

| Domain | Technologies / Libraries |
| :--- | :--- |
| **Frontend Framework** | [Flutter](https://flutter.dev) (SDK `>=3.0.0 <4.0.0`) |
| **State & Navigation** | `go_router`, `flutter_staggered_animations` |
| **UI & Charts** | `google_fonts`, `fl_chart`, `cupertino_icons` |
| **Backend & Cloud** | Firebase Auth, Cloud Firestore, Firebase Cloud Messaging (FCM) |
| **Serverless Functions** | Node.js 18 (Firebase Cloud Functions) |
| **Testing & Tooling** | Python 3, Appium, Flutter Widget Tests |

---

## 📁 Project Architecture

```text
event_rental_pdd/
├── 📂 backend/                      # Backend configuration & automated tests
│   ├── 📂 automated_test/           # Python backend E2E simulation & report generator
│   ├── 📂 functions/                # Firebase Cloud Functions (Node.js 18)
│   ├── 📄 firestore.rules           # Firestore security rules
│   └── 📄 firestore.indexes.json    # Database index definitions
│
├── 📂 frontend/                     # Flutter cross-platform application
│   ├── 📂 assets/                   # Static assets (images, icons)
│   ├── 📂 lib/                      # Application source code
│   │   ├── 📂 models/               # Data schemas & object models
│   │   ├── 📂 screens/              # UI views (admin, auth, customer, vendor, features)
│   │   ├── 📂 services/             # Firebase & notification services
│   │   ├── 📂 theme/                # Global design system & theme tokens
│   │   ├── 📂 widgets/              # Reusable UI components & application shell
│   │   ├── 📄 firebase_options.dart # Generated Firebase configuration
│   │   ├── 📄 main.dart             # Application entry point
│   │   └── 📄 router.dart           # App navigation & route declarations
│   ├── 📂 test/                     # Unit & widget tests
│   ├── 📂 frontend_test/            # Python frontend E2E test runner
│   ├── 📂 apium testing/            # Appium integration test suite
│   └── 📄 pubspec.yaml              # Flutter dependencies manifest
│
└── 📄 firebase.json                 # Firebase project configuration
```

---

## 🚀 Quick Start & Setup

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.0.0`)
- [Python](https://www.python.org/) (`>= 3.8`) for running test simulators
- [Node.js](https://nodejs.org/) (`v18+`) & [Firebase CLI](https://firebase.google.com/docs/cli)

### Frontend Setup
1. Navigate to the `frontend` directory:
   ```bash
   cd frontend
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Launch the application:
   ```bash
   flutter run
   ```

### Backend Setup
1. Inspect or modify backend functions in `backend/functions`.
2. Emulate or deploy Firebase rules and functions:
   ```bash
   firebase emulators:start
   ```

---

## 🧪 Automated Testing Suite

EventSphere includes automated end-to-end simulation suites that produce Excel reports upon completion.

### Backend Security & Rules Simulation
Simulates backend API requests and validates Firestore rule execution:
```bash
python backend/automated_test/backend_test_runner.py
```
*Outputs detailed Excel report spreadsheets in `backend/automated_test/`.*

### Frontend Flow Verification
Simulates frontend user navigation, widget flows, and user interactions:
```bash
python frontend/frontend_test/frontend_test_runner.py
```
*Outputs detailed Excel report spreadsheets in `frontend/frontend_test/`.*

---

## 📄 License

This project is proprietary and maintained for EventSphere Event Equipment Rentals.