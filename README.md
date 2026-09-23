# CoSpend — Co-Living Expense & Budget Manager

<p align="center">
  <img src="assets/images/app_logo.png" alt="CoSpend Logo" width="120" />
</p>

<p align="center">
  <strong>Co-living budgets, perfectly tracked.</strong><br>
  A modern, integer-safe financial operating system tailored for roommates, flatmates, and shared households.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-1.5.0-blue.svg" alt="Version 1.5.0" />
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B.svg?logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2.svg?logo=dart" alt="Dart" />
  <img src="https://img.shields.io/badge/Firebase-Auth%20%26%20Firestore-FFCA28.svg?logo=firebase" alt="Firebase" />
  <img src="https://img.shields.io/badge/Riverpod-2.x-00D2B8.svg" alt="Riverpod" />
  <img src="https://img.shields.io/badge/Tests-92%2F92%20Passing-brightgreen.svg" alt="Tests" />
  <img src="https://img.shields.io/badge/License-Proprietary-red.svg" alt="License" />
</p>

---

## 🌟 Overview

**CoSpend** (formerly FlatSplit) solves the day-to-day financial friction of shared living. Unlike generic receipt splitters, CoSpend provides complete household budget visibility: recurring groceries, utilities, rent, supplies, and real-time category spending limits.

Designed with a **premium fintech aesthetic** (inspired by Revolut, Wise, and Monarch Money), CoSpend features a clutter-free financial dashboard, role-based controls, real-time spending notifications, gallery avatar uploads, and integer-safe debt minimization.

---

## ✨ Key Features

### 📊 4-Card Financial Dashboard & Gradient Hero
- **Total Allocated Budget**: Combined household spending limit with remaining balance.
- **Total Spendings**: Aggregate expenditure across all roommates for the active month.
- **Your Total Allocated Share**: Current user's personal quota across all categories.
- **Total Spending by You**: Cumulative personal out-of-pocket expenses.
- **Deep Prussian Blue Gradient Card**: High-contrast hero card with a bright Jade Green progress bar.
- **Proactive Exceeded Alerts**: High-visibility alert banner when limits are breached.

### 💰 Expense Logging & Precision Splitting
- **Minimalist Hero Input**: Large numeric entry with currency prefix (`Rs.`) and instant formatting.
- **3 Split Modes**:
  - *Equal*: Exact 1-paisa remainder allocation (zero calculation drift).
  - *Unequal*: Custom rupee amounts per flatmate.
  - *Percentage*: Custom percentage breakdown ensuring 100% total.
- **Sub-Category Tagging**: Inline dynamic subcategory pills (e.g. Food $\to$ Groceries, Dining, Snacks).
- **Roommate Selection**: Custom circular check toggles to include or exclude specific roommates.

### 🎯 Dedicated Budgets & Role-Based Control
- **Dedicated Budgets Tab**: Centralized spending cap hub (`CategoryBudgetScreen`).
- **Owner Mode**: Flat creator can adjust household caps, category limits, member quotas, and quick adjustment chips (`+1k`, `+5k`, `+10k`).
- **Member View-Only Mode**: Roommates see clean, bold statement-style numbers without disabled form clutter.

### 🔔 Real-Time Spending Notifications
- Instant in-app notifications whenever any roommate records an expense.
- Activity notification sheet with relative timestamps (`"2m ago"`, `"1h ago"`) and unread counter badge.

### 👤 Profile & Avatar Studio
- **Gallery & Device Albums**: Pick custom profile pictures directly from gallery or camera, compressed and synced instantly across all flatmates.
- **16 Curated Illustrated Badges**: Vibrant gradient avatars.
- **Monogram Initials**: Dynamic dual-tone avatar generated from initials.
- **Contact Info**: Phone/WhatsApp numbers, room notes, and UPI/EasyPaisa/JazzCash payment handles.

### 🤝 Debt Minimization Engine
- **Greedy Bipartite Simplification**: Computes net balances and generates the minimum number of transactions ($N - 1$ max) to balance the household.
- **One-Tap Settlement**: Record settlements with an immutable audit log.

---

## 🎨 Theme & Brand Design System

CoSpend uses a strict, high-contrast, modern banking color palette defined in `lib/core/theme/design_system.dart`:

| Token | Hex | Role |
|---|---|---|
| **Prussian Blue** | `#0A2542` | Primary brand color, headers, hero numbers, deep gradient cards, active filters |
| **Jade Green** | `#00BC57` | Primary accent, CTAs, on-track progress indicators, active navigation tabs |
| **Off-White Canvas** | `#F7F8FA` | App surface canvas providing clean separation from white cards |
| **Pure White** | `#FFFFFF` | Elevated cards, dialogs, bottom sheets |
| **Alert Red** | `#EF4444` | Exclusively for budget-exceeded alerts and destructive actions |

- **Geometry**: Strict `12px` card/input corner radii; `999px` stadium pills for buttons, chips, tags, and search bars.
- **Depth**: Soft Prussian-Blue-tinted shadows (`rgba(10, 37, 66, 0.05)`).
- **Micro-Interactions**: Tactile `BouncingButton` scale-down feedback on press.

---

## 📁 Project Architecture

```
lib/
├── app/                        # App composition root & GoRouter configuration
├── core/
│   ├── constants/              # AppConstants, FirestoreCollections
│   ├── errors/                 # AppException hierarchy & FirebaseErrorMapper
│   ├── theme/                  # design_system.dart & app_theme.dart
│   └── utils/                  # Money (Paisa integer math), Validators, Formatters
├── features/
│   ├── auth/                   # Firebase Auth, Profile editing, Avatar picker
│   ├── household/              # Flat creation, invite codes (FLAT-XXXX), notifications
│   ├── expenses/               # Expense logging, custom categories, splitting
│   ├── dashboard/              # 4-card metric grid, hero budget card, category limits
│   ├── settlement/             # Greedy bipartite debt minimization engine
│   └── shell/                  # AppShellScreen (BottomNav), HomeScreen, MoreScreen
└── shared/                     # Reusable widgets (CoSpendCard, TintedIcon, LoadingButton)
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `^3.13.4` (or newer Dart 3.x)
- Android SDK (API 21+) / iOS 13+
- Firebase project configured with Authentication & Cloud Firestore

### Installation & Run

1. **Clone the repository**:
   ```bash
   git clone https://github.com/hayat-ishfaq/expensetrack.git
   cd expensetrack
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run Static Analysis**:
   ```bash
   flutter analyze
   ```
   *(Expected: 0 issues found)*

4. **Run Test Suite**:
   ```bash
   flutter test
   ```
   *(Expected: 92/92 tests passing)*

5. **Run the App**:
   ```bash
   flutter run
   ```

6. **Build Production Release APK**:
   ```bash
   flutter build apk --release --no-tree-shake-icons
   ```
   Release binary generated at: `build/app/outputs/flutter-apk/app-release.apk` (or root `CoSpend-release.apk`).

---

## 📚 Documentation Directory

Detailed specifications are maintained in the [`docs/`](./docs) folder:
- [docs/PRD.md](./docs/PRD.md) — Product Requirements Document (v1.5.0)
- [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md) — System Architecture, State Machine & Algorithms
- [docs/FRONTEND_SPEC.md](./docs/FRONTEND_SPEC.md) — Design System Tokens & UI Specifications
- [docs/SECURITY.md](./docs/SECURITY.md) — RBAC, Firestore Security Rules & Data Isolation
- [docs/TICKETS.md](./docs/TICKETS.md) — Development Epics, Completed Tickets & Roadmap
- [Progress.md](./Progress.md) — Milestone History & Progress Tracking
