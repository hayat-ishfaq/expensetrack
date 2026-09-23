# FlatSplit — Feature Ticket List & Backlog

This document organizes the complete development lifecycle into structured Epics and actionable Jira/GitHub-style development tickets with acceptance criteria and status tracking.

---

## Epic 1: Authentication & User Profile Management

### [DONE] FS-101: Email/Password Authentication & Session Persistence
- **Type**: Feature | **Priority**: P0 | **Status**: Closed
- **Description**: Implement email & password sign-up, login, and persistent session management via Firebase Authentication.
- **Acceptance Criteria**:
  - Validates email formats and enforces 8-character minimum passwords.
  - Automatically redirects signed-out users to onboarding/login.
  - Preserves session across app reboots.

### [DONE] FS-102: Password Reset via Email
- **Type**: Feature | **Priority**: P1 | **Status**: Closed
- **Description**: Allow users to request a password reset email from the login screen.
- **Acceptance Criteria**:
  - Surfaces friendly confirmation snackbar.
  - Maps Firebase auth exceptions to friendly user-facing messages.

---

## Epic 2: Household & Onboarding Architecture

### [DONE] FS-201: Household Creation & Owner Provisioning
- **Type**: Feature | **Priority**: P0 | **Status**: Closed
- **Description**: Enable users to create a new shared flat and become the designated flat owner.
- **Acceptance Criteria**:
  - Atomic batch write creates `household`, initial `member`, and sets user `householdId`.
  - Creator is assigned `MemberRole.owner`.

### [DONE] FS-202: Cryptographic Invite Code Generation
- **Type**: Feature | **Priority**: P0 | **Status**: Closed
- **Description**: Generate unique 4-character codes in format `FLAT-XXXX` avoiding ambiguous characters (`0, O, 1, I, L`).
- **Acceptance Criteria**:
  - Atomic collision check in `inviteCodes` Firestore collection.
  - Retry up to 6 times if collision occurs.

### [DONE] FS-203: Smart Invite Code Normalization & Multi-Flat Joining
- **Type**: Feature / Fix | **Priority**: P0 | **Status**: Closed
- **Description**: Resolve invite join failures by intelligently extracting `FLAT-XXXX` from full WhatsApp share messages and raw codes.
- **Acceptance Criteria**:
  - Supports `7k29`, `flat-7k29`, `FLAT-7K29`, and `Flat Invite Code: FLAT-7K29\nJoin my flat...`.
  - Fallback lookup on `households` collection if `inviteCodes` doc is missing.
  - Automatically navigates to `Routes.home` on successful join.
  - Cleans up lingering membership in previous household.

### [DONE] FS-204: Leave Flat Workflow
- **Type**: Feature | **Priority**: P1 | **Status**: Closed
- **Description**: Allow members to leave a flat with confirmation dialog.
- **Acceptance Criteria**:
  - Decrements `memberCount` and clears user `householdId`.
  - Preserves historic expense references.

---

## Epic 3: Expense Logging & Advanced Splitting

### [DONE] FS-301: Expense Entry Form & Keypad
- **Type**: Feature | **Priority**: P0 | **Status**: Closed
- **Description**: Create dynamic expense creation form with currency keypad, date picker, and description.
- **Acceptance Criteria**:
  - Enforces amount $> 0$ and non-empty title.
  - Stores all values in 64-bit integer paisas.

### [DONE] FS-302: Multi-Mode Expense Splitting Engine
- **Type**: Feature | **Priority**: P0 | **Status**: Closed
- **Description**: Support Equal, Unequal (Exact Amounts), and Percentage splits.
- **Acceptance Criteria**:
  - Equal split distributes remainder paisas so total equals exact amount.
  - Percentage split validates sum equals 100%.
  - Custom amount split validates sum equals total amount.

---

## Epic 4: Custom Category & Sub-Category Engine

### [DONE] FS-401: Custom Categories Creation Sheet
- **Type**: Feature | **Priority**: P1 | **Status**: Closed
- **Description**: Allow flat owner to create custom expense categories with custom icons and colors.
- **Acceptance Criteria**:
  - 36 curated material icons and 12 vibrant color choices.
  - Pre-registered const icon mapping preventing release font tree shaking crashes.
  - Custom categories persist in household document.

### [DONE] FS-402: Sub-Category Tagging Engine
- **Type**: Feature | **Priority**: P1 | **Status**: Closed
- **Description**: Allow selecting or adding subcategories on the fly for any category.
- **Acceptance Criteria**:
  - Standard categories provide presets (e.g. Food: Groceries, Dining, Takeout).
  - Inline `+ Sub` chip adds new subcategory tag immediately.

---

## Epic 5: Category & Member Budget Management

### [DONE] FS-501: Role-Based Budget Security & Authorization
- **Type**: Feature / Security | **Priority**: P0 | **Status**: Closed
- **Description**: Ensure only the flat owner can set or adjust overall and category budgets, while members are view-only.
- **Acceptance Criteria**:
  - Non-owner members see View-Only banner on `CategoryBudgetScreen`.
  - All input fields, quick chips, and save actions are disabled or hidden for members.
  - `_assertOwner` guard in repository prevents unauthorized updates.
  - Firestore security rules block non-owner budget edits.

### [DONE] FS-502: Member Category Quota Allocation
- **Type**: Feature | **Priority**: P1 | **Status**: Closed
- **Description**: Enable the flat owner to divide category budgets among members equally or with custom amounts.
- **Acceptance Criteria**:
  - "Divide Equally" button distributes category budget across all flatmates.
  - Custom member quotas tracked in `memberCategoryBudgetsPaisa`.

### [DONE] FS-503: Exceeded Budget Warning Alerts
- **Type**: Feature | **Priority**: P1 | **Status**: Closed
- **Description**: Highlight high-visibility alerts on dashboard when a member or flat exceeds category spending limits.
- **Acceptance Criteria**:
  - Displays alert banner with exact overspent amount.

---

## Epic 6: Debt Minimization & Settlement Engine

### [DONE] FS-601: Greedy Bipartite Settlement Algorithm
- **Type**: Feature | **Priority**: P0 | **Status**: Closed
- **Description**: Implement mathematical engine to compute net roommate balances and minimize settlement transactions.
- **Acceptance Criteria**:
  - Net balances always sum to zero across all flat members.
  - Produces at most $N - 1$ settlement transactions.

### [DONE] FS-602: One-Tap Settlement Recording
- **Type**: Feature | **Priority**: P0 | **Status**: Closed
- **Description**: Allow roommates to record debt settlements directly from the Settle Up screen.
- **Acceptance Criteria**:
  - Records persistent settlement document in `/households/{id}/settlements`.
  - Real-time balances update immediately to reflect settlement.

---

## Epic 7: Design System, Aesthetics & UI Polish

### [DONE] FS-701: Modern Emerald Glassmorphic Design System
- **Type**: Enhancement | **Priority**: P1 | **Status**: Closed
- **Description**: Implement premium dark/light theme with curated Google Fonts (`Outfit` & `Inter`).
- **Acceptance Criteria**:
  - Consistent elevation, rounded corners (16-20px), and border strokes.
  - Polished empty states and loading skeletons.

### [DONE] FS-702: App Icon & Brand Identity
- **Type**: Enhancement | **Priority**: P1 | **Status**: Closed
- **Description**: Integrate authentic app launcher icon across all Android densities (`mipmap-mdpi` to `mipmap-xxxhdpi`).
- **Acceptance Criteria**:
  - Modern FlatSplit split-leaf / currency emblem launcher icon.

---

## Epic 8: Future Roadmap & Backlog (Next Sprints)

### [BACKLOG] FS-801: Push Notifications via FCM
- **Type**: Feature | **Priority**: P1 | **Status**: Planned
- **Description**: Send push notifications when a roommate logs a new expense or when personal category budget is exceeded.

### [BACKLOG] FS-802: Receipt OCR Scanner
- **Type**: Feature | **Priority**: P2 | **Status**: Planned
- **Description**: Scan grocery / restaurant receipts and automatically extract total amount and items using ML Kit.

### [BACKLOG] FS-803: Export to CSV / PDF
- **Type**: Feature | **Priority**: P2 | **Status**: Planned
- **Description**: Download monthly household expense reports for landlord tax filings or personal records.
