# CoSpend — Feature Ticket List & Development Epics

This document tracks the complete development lifecycle for **CoSpend** (formerly FlatSplit), organized into structured Epics and actionable development tickets with acceptance criteria and status tracking.

---

## Epic 1: Authentication & User Profile Management

### [DONE] CS-101: Email/Password Authentication & Session Persistence
- **Type**: Feature | **Priority**: P0 | **Status**: Closed
- **Description**: Implement email & password sign-up, login, and persistent session management via Firebase Authentication.
- **Acceptance Criteria**:
  - Validates email formats and enforces 8-character minimum passwords.
  - Automatically redirects signed-out users to onboarding/login.
  - Preserves session across app reboots.

### [DONE] CS-102: Password Reset via Email
- **Type**: Feature | **Priority**: P1 | **Status**: Closed
- **Description**: Allow users to request a password reset email from the login screen.
- **Acceptance Criteria**:
  - Surfaces friendly confirmation snackbar.
  - Maps Firebase auth exceptions to friendly user-facing messages.

---

## Epic 2: Household & Onboarding Architecture

### [DONE] CS-201: Household Creation & Owner Provisioning
- **Type**: Feature | **Priority**: P0 | **Status**: Closed
- **Description**: Enable users to create a new shared flat and become the designated flat owner.
- **Acceptance Criteria**:
  - Atomic batch write creates `household`, initial `member`, and sets user `householdId`.
  - Creator is assigned `MemberRole.owner`.

### [DONE] CS-202: Cryptographic Invite Code Generation
- **Type**: Feature | **Priority**: P0 | **Status**: Closed
- **Description**: Generate unique 4-character codes in format `FLAT-XXXX` avoiding ambiguous characters (`0, O, 1, I, L`).
- **Acceptance Criteria**:
  - Atomic collision check in `inviteCodes` Firestore collection.
  - Retry up to 6 times if collision occurs.

### [DONE] CS-203: Smart Invite Code Normalization & Multi-Flat Joining
- **Type**: Feature / Fix | **Priority**: P0 | **Status**: Closed
- **Description**: Resolve invite join failures by intelligently extracting `FLAT-XXXX` from full WhatsApp share messages and raw codes.
- **Acceptance Criteria**:
  - Supports `7k29`, `flat-7k29`, `FLAT-7K29`, and `Flat Invite Code: FLAT-7K29\nJoin my flat...`.
  - Fallback lookup on `households` collection if `inviteCodes` doc is missing.
  - Automatically navigates to `Routes.home` on successful join.
  - Cleans up lingering membership in previous household.

### [DONE] CS-204: Leave Flat Workflow
- **Type**: Feature | **Priority**: P1 | **Status**: Closed
- **Description**: Allow members to leave a flat with confirmation dialog.
- **Acceptance Criteria**:
  - Decrements `memberCount` and clears user `householdId`.
  - Preserves historic expense references.

---

## Epic 3: Expense Logging & Advanced Splitting

### [DONE] CS-301: Expense Entry Keypad & Metadata
- **Type**: Feature | **Priority**: P0 | **Status**: Closed
- **Description**: Fast, frictionless expense entry with rupee keypad, category, date, and payer attribution.
- **Acceptance Criteria**:
  - Average logging time $< 10$ seconds.
  - Supports Today, Yesterday, and custom date pickers.

### [DONE] CS-302: Integer-Safe Split Engine (Equal, Unequal, Percentage)
- **Type**: Feature | **Priority**: P0 | **Status**: Closed
- **Description**: Exact integer math (paisa) splitting across selected roommates with zero rounding drift.
- **Acceptance Criteria**:
  - Equal split distributes remainders 1 paisa at a time.
  - Unequal and percentage splits enforce sum validation.

---

## Epic 4: Custom Category Engine

### [DONE] CS-401: Custom Categories & Pre-Indexed Icons
- **Type**: Feature | **Priority**: P1 | **Status**: Closed
- **Description**: Allow flat owner to create custom categories with 36 curated icons and 12 pastel color accents.
- **Acceptance Criteria**:
  - Zero dynamic `IconData` crashes in release AOT tree-shaking builds.
  - On-the-fly subcategory tag creation.

---

## Epic 5: Role-Based Budget Management

### [DONE] CS-501: Role-Based Budget Security & Authorization
- **Type**: Feature / Security | **Priority**: P0 | **Status**: Closed
- **Description**: Ensure only the flat owner can set or adjust overall and category budgets, while members are view-only.
- **Acceptance Criteria**:
  - Non-owner members see View-Only banner on `CategoryBudgetScreen`.
  - All input fields, quick chips, and save actions are disabled or replaced with plain text for members.
  - Firestore security rules enforce owner-only budget edits.

### [DONE] CS-502: Member Category Quota Allocation
- **Type**: Feature | **Priority**: P1 | **Status**: Closed
- **Description**: Enable flat owner to divide category budgets among members equally or with custom amounts.
- **Acceptance Criteria**:
  - "Divide Equally" button distributes category budget across all flatmates.
  - Custom member quotas tracked in `memberCategoryBudgetsPaisa`.

### [DONE] CS-503: Exceeded Budget Warning Alerts
- **Type**: Feature | **Priority**: P1 | **Status**: Closed
- **Description**: High-visibility alerts on dashboard when a member or flat exceeds category spending limits.

---

## Epic 6: Debt Minimization & Settlement Engine

### [DONE] CS-601: Greedy Bipartite Settlement Algorithm
- **Type**: Feature | **Priority**: P0 | **Status**: Closed
- **Description**: Mathematical engine to compute net roommate balances and minimize settlement transactions to at most $N - 1$.

### [DONE] CS-602: One-Tap Settlement Recording
- **Type**: Feature | **Priority**: P0 | **Status**: Closed
- **Description**: Record settlements and persist audit log in `/households/{id}/settlements`.

---

## Epic 7: Financial Dashboard & Budgets Tab Streamlining

### [DONE] CS-701: 4-Card Financial Metric Grid Architecture
- **Type**: Enhancement | **Priority**: P0 | **Status**: Closed
- **Description**: Replace confusing debt/owes matrices on Home with 4 intuitive spending cards:
  1. Total Allocated Budget
  2. Total Spendings
  3. Your Total Allocated Share
  4. Total Spending by You

### [DONE] CS-702: Dedicated Budgets Bottom Navigation Tab
- **Type**: Enhancement | **Priority**: P0 | **Status**: Closed
- **Description**: Elevate `CategoryBudgetScreen` into a top-level bottom navigation tab replacing Settle Up on primary shell.

---

## Epic 8: Real-Time Spending Notifications

### [DONE] CS-801: Atomic Transaction Notification Writer
- **Type**: Feature | **Priority**: P1 | **Status**: Closed
- **Description**: Atomically write notification document to `/households/{id}/notifications` on every expense creation.

### [DONE] CS-802: Real-Time In-App Notification Sheet & Toast
- **Type**: Feature | **Priority**: P1 | **Status**: Closed
- **Description**: Surface instant toast alerts and an activity sheet with relative timestamps ("2m ago") and unread badges.

---

## Epic 9: Profile Customization & Avatar Studio

### [DONE] CS-901: User Profile Management & Payment Handles
- **Type**: Feature | **Priority**: P1 | **Status**: Closed
- **Description**: Edit display name, phone/WhatsApp number, UPI/payment handles, and room notes.

### [DONE] CS-902: Gallery & Album Image Picker
- **Type**: Feature | **Priority**: P0 | **Status**: Closed
- **Description**: Select photos directly from device gallery or camera, compressed to 256x256 base64 data URIs.
- **Acceptance Criteria**:
  - Instant dismissal returning URI on selection.
  - Whitespace sanitization on base64 decode preventing crashes.
  - Zero photoURL format exceptions with Firebase Auth.

### [DONE] CS-903: Curated 16-Avatar Studio & Initials Monograms
- **Type**: Feature | **Priority**: P1 | **Status**: Closed
- **Description**: Illustrated persona badges with dual-tone gradient backdrops and deterministic initials generator.

---

## Epic 10: Official Rebranding to CoSpend

### [DONE] CS-1001: App Rebrand to CoSpend
- **Type**: Chore / Brand | **Priority**: P0 | **Status**: Closed
- **Description**: Update app name across Dart constants, AndroidManifest, Gradle, Auth screens, and splash assets.

### [DONE] CS-1002: Android Launcher Icon Generation
- **Type**: Enhancement | **Priority**: P1 | **Status**: Closed
- **Description**: Generate production mipmaps across `mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, and `xxxhdpi` from official emblem.

---

## Epic 11: Premium Fintech UI/UX Redesign (Phase 12)

### [DONE] CS-1101: Centralized Design System (`lib/core/theme/design_system.dart`)
- **Type**: Enhancement / Architecture | **Priority**: P0 | **Status**: Closed
- **Description**: Encapsulate Prussian Blue (`#0A2542`), Jade Green (`#00BC57`), White (`#FFFFFF`), Off-White Canvas (`#F7F8FA`), and Alert Red (`#EF4444`).
- **Acceptance Criteria**:
  - 12px rounded corner radii for cards and inputs.
  - 999px full-pill stadium geometry for buttons, chips, search bar.
  - Soft Prussian-Blue-tinted shadows (`rgba(10, 37, 66, 0.05)`).
  - Tactile `BouncingButton` micro-interaction with 0.97 scale feedback.

### [DONE] CS-1102: Screen-by-Screen Fintech Polish Pass
- **Type**: Enhancement | **Priority**: P0 | **Status**: Closed
- **Description**: Overhaul Home (2x2 stats + Prussian Blue gradient hero card), Expenses (stadium search + solid Prussian chips), Add Expense (hero amount + sliding segmented control + circular checks), Budgets (statement typography for members), and More (profile card + standardized 52px rows).
- **Acceptance Criteria**:
  - 0 static analysis issues across all 86 files.
  - 92/92 automated unit and widget tests passing.
  - Release APK built successfully.

---

## Epic 12: Future Roadmap & Backlog (Next Sprints)

### [BACKLOG] CS-1201: Push Notifications via FCM
- **Type**: Feature | **Priority**: P1 | **Status**: Planned
- **Description**: Send background push notifications via Firebase Cloud Messaging when roommate spends or limits are exceeded.

### [BACKLOG] CS-1202: Smart Receipt OCR Scanner
- **Type**: Feature | **Priority**: P2 | **Status**: Planned
- **Description**: Scan grocery / utility receipts using ML Kit and automatically extract total amount, vendor, and line items.

### [BACKLOG] CS-1203: Export to CSV / PDF Statement
- **Type**: Feature | **Priority**: P2 | **Status**: Planned
- **Description**: Generate and download monthly household expense statements and tax reports.
