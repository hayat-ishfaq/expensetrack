# CoSpend — Product Requirements Document (PRD)

**Product Name**: CoSpend (formerly FlatSplit)  
**Platform**: Android & iOS (Flutter)  
**Version**: 1.4.0  
**Target Audience**: Flatmates, roommates, co-living groups, students, and shared households  
**Document Owner**: Engineering & Product Team  
**Status**: Active / In Production  

---

## 1. Executive Summary
**CoSpend** is a modern, high-performance mobile application designed to simplify shared living expenses. Unlike generic bill-splitting applications that focus exclusively on one-off dinner receipts or complex corporate balance sheets, CoSpend is tailored for **household day-to-day operations**: shared groceries, utilities, rent, recurring household supplies, and monthly category-specific spending caps.

With automated debt minimization, role-based budget management, instant invite links, custom category icon/color engines, and zero-loss offline-first caching, CoSpend eliminates roommate money friction and provides full financial transparency.

---

## 2. Problem Statement
Living with flatmates often leads to interpersonal friction caused by:
1. **Ambiguous Accounting**: Unclear records of who paid for groceries, milk, Wi-Fi, or electricity bills.
2. **Budget Drift**: Households have no visibility into how much they have collectively spent on food or utilities until the month ends and budgets are blown.
3. **Unequal Burdens**: Some flatmates do not consume certain items (e.g. non-vegetarians vs vegetarians, non-smokers, specific grocery runs) yet are pressured to split costs evenly.
4. **Complicated Settlements**: 5 roommates with criss-cross debts create a chaotic matrix of payments instead of simple, single net transfers.
5. **Lack of Role Separation**: In typical shared apps, anyone can accidentally overwrite household budgets, flat names, or remove members without permissions.

---

## 3. Product Vision & Goals

### 3.1 Vision
To be the most intuitive, beautiful, and effortless co-living financial operating system for roommates worldwide.

### 3.2 Core Objectives
- **Zero Calculation Fatigue**: Automated integer-safe debt settlement using greedy bipartite minimization algorithms.
- **Strict Role-Based Integrity**: The household creator (Owner) controls budgets, custom categories, and flat configurations, while joined members focus on adding expenses and settling debts.
- **Granular Category Budgets**: Overall household spending limits paired with per-member category allocations (e.g. Flat Food Budget = Rs. 30,000; Member A = Rs. 10,000, Member B = Rs. 20,000).
- **Proactive Budget Alerts**: Real-time notifications when a member or the entire flat exhausts category quotas.
- **Effortless Onboarding**: One-tap shareable invite codes (`FLAT-XXXX`) that can be pasted directly from WhatsApp messages.

---

## 4. User Personas

### Persona A: The Flat Admin (Bilal, 24)
- **Role**: Leaseholder / Primary account manager of an apartment with 3 roommates.
- **Pain Points**: Collects utility bills, pays rent, and constantly has to remind roommates to pay their share. Needs control over the flat's monthly budget so members don't overspend.
- **Goals**: Set monthly targets for Groceries and Bills, allocate quotas, monitor spending against targets in real time, and share clean invite codes.

### Persona B: The Busy Roommate (Hamza, 22)
- **Role**: Software engineer sharing a flat.
- **Pain Points**: Forgets who paid for groceries yesterday; hates calculating percentages or asking for money.
- **Goals**: Quickly log an expense on the go (under 10 seconds), see exact personal balance ("Hamza gets back Rs. 4,500"), and settle debts with one tap.

---

## 5. Functional Requirements

### 5.1 Authentication & Profile
- **FR-AUTH-1**: Email & password authentication with Firebase Auth.
- **FR-AUTH-2**: Password reset via secure email tokens.
- **FR-AUTH-3**: Persistent session with biometric/auto-login state.
- **FR-AUTH-4**: User Profile Management: Name, verified email, contact phone/WhatsApp number, UPI ID/payment handle, and room note/bio.
- **FR-AUTH-5**: Avatar Studio & Profile Customization:
  - **Gallery & Device Albums**: Users can pick custom profile pictures directly from their phone gallery, albums, or camera. Photos are automatically scaled and encoded as lightweight base64 data URIs for instant, zero-latency cross-device synchronization without external storage bucket dependency.
  - **Curated Avatar Library**: 16 high-aesthetic persona avatar badges (Techie, Chef, Music, Coffee, Nature, Cat, Zen, etc.) with dual-tone gradient backdrops.
  - **Custom Image URL Support**: Compatible with public photo links (Google, Gravatar, Discord, Unsplash).
  - **Dynamic Monogram Initials**: Deterministic dual-tone gradient avatar generated from user initials.
  - **Cross-Household Sync**: Updates sync simultaneously across Firebase Auth, `users/{uid}`, and `households/{householdId}/members/{uid}` so flatmates immediately see new avatars and contact details.

### 5.2 Household Management & Onboarding
- **FR-HOUSE-1**: Household Creation: Allows user to create a new flat and automatically assigns them `Owner` role.
- **FR-HOUSE-2**: Unique Invite Codes: Generates cryptographically secure alphanumeric codes in format `FLAT-XXXX` (excluding ambiguous characters: 0, O, 1, I, L).
- **FR-HOUSE-3**: Smart Code Normalization: Intelligently parses invite codes from full shared text (e.g. WhatsApp/SMS shares), loose formats (`7k29`, `flat-7k29`), and auto-normalizes.
- **FR-HOUSE-4**: Self-Healing Join Lookup: Dual lookup in Firestore (`inviteCodes` index and `households` collection fallback) to guarantee seamless joins.
- **FR-HOUSE-5**: Multi-Flat Cleanup: Automatically cleans up previous flat memberships when switching or joining a new flat.
- **FR-HOUSE-6**: Leave Flat: Members can leave a flat, decrementing member count and preserving historic transaction integrity.

### 5.3 Expense Logging & Splitting
- **FR-EXP-1**: Quick Expense Creation: Title, Amount (in Paisa/Rupees), Category, Sub-Category, Date, Payer, and Split Mode.
- **FR-EXP-2**: Split Types:
  - *Equal Split*: Splits equally among selected participants with exact 1-paisa remainder distribution (no rounding leaks).
  - *Unequal / Custom Split*: Explicit rupee amounts per person.
  - *Percentage Split*: Custom percentage breakdown ensuring 100% total.
- **FR-EXP-3**: Participant Selection: Allows including or excluding specific roommates for any expense.
- **FR-EXP-4**: Sub-Category Tagging: Each category supports preset and dynamically added custom subcategories (e.g. Food -> Groceries, Takeout, Dining).

### 5.4 Custom Categories Engine
- **FR-CAT-1**: Create Custom Categories: The flat owner can create custom categories with a title, 36 curated material icons, and 12 curated color palettes.
- **FR-CAT-2**: Sub-Category Management: Inline addition of new subcategories on the fly during expense entry or category configuration.
- **FR-CAT-3**: System Categories: Defaults include Food, Utilities, Rent, Household, Transportation, Entertainment, Health, and Miscellaneous.

### 5.5 Financial Dashboard (4-Card Architecture)
- **FR-DASH-1**: Total Allocated Budget Card: Displays the flat's monthly combined budget limit across all categories with percentage used and remaining amount.
- **FR-DASH-2**: Total Spendings Card: Displays aggregate spending by all roommates in the current billing cycle.
- **FR-DASH-3**: Your Total Allocated Share Card: Displays the authenticated user's personal spending quota across categories (or fallback equal share).
- **FR-DASH-4**: Total Spending by You Card: Displays the authenticated user's cumulative out-of-pocket expenditure.
- **FR-DASH-5**: Settle-Up / Owes Removal: Removes confusing cross-debt matrices and "owes/lent" numbers from the primary home summary, focusing strictly on budget targets and actual spending.

### 5.6 Dedicated Budgets Navigation Tab
- **FR-TAB-1**: Primary Navigation: Replaces the bottom navigation tab "Settle Up" with a dedicated **"Budgets"** tab (`CategoryBudgetScreen`).
- **FR-TAB-2**: Quick Access: Allows roommates to instantly monitor category breakdown, remaining limits, and member quotas with one tap.

### 5.7 Real-Time Spending Notifications
- **FR-NOTIF-1**: Atomic Transaction Event Creation: Whenever a member records an expense, an event document is atomically written to `/households/{householdId}/notifications`.
- **FR-NOTIF-2**: In-App Real-Time Toast Banner: Roommates actively using the app receive an instant toast banner alert (`🔔 New Expense: [Payer] paid Rs. X for [Category]`).
- **FR-NOTIF-3**: Activity Notification Bell: Unread badge counter in the Home AppBar opening a dedicated Activity sheet with relative timestamps ("2m ago", "1h ago") and payer details.

### 5.8 Role-Based Budget Management
- **FR-BUD-1**: Owner-Only Budget Configuration: Only the household creator/owner can adjust the overall flat monthly budget and individual category budgets.
- **FR-BUD-2**: View-Only Member Mode: Members can inspect all budgets, limits, and progress bars, but all editing controls, save actions, and quick chips are locked.
- **FR-BUD-3**: Member Category Quotas: Owner can allocate category targets per roommate (e.g. Food budget divided equally or custom per member).
- **FR-BUD-4**: Exceeded Alerts: High-visibility dashboard warning cards triggered when an individual member or the flat exceeds a category budget limit.

### 5.9 Settlement & Debt Minimization
- **FR-SETTLE-1**: Greedy Bipartite Debt Simplification: Computes net balances ($Credits - Debts$) and generates the minimum number of transactions ($N - 1$ max) required to balance the flat.
- **FR-SETTLE-2**: One-Tap Settlement: Mark a transfer as paid to clear debts with persistent settlement transaction records.
- **FR-SETTLE-3**: Settlement History: Audit log of past recorded settlements.

---

## 6. Non-Functional Requirements

### 6.1 Performance
- **App Launch Time**: Cold launch $< 1.5$ seconds; warm launch $< 400$ ms.
- **List Scrolling**: 60–120 FPS buttery smooth scrolling with lazy `ListView.builder`.
- **Integer-Safe Calculations**: Zero floating-point arithmetic errors across all currencies; all values stored and manipulated as 64-bit integer paisas (`value * 100`).

### 6.2 Security & Compliance
- **Zero Cross-Household Leakage**: Strict Firestore document isolation ensuring users can only read documents from their active `householdId`.
- **Role Enforcement at Database Layer**: Database rules enforce that `monthlyBudgetPaisa` and `categoryBudgetsPaisa` can only be updated by `isOwnerOf(householdId)`.
- **Expense Immutability / Authorship**: Members can only create expenses where `createdByUserId == request.auth.uid`.

### 6.3 Usability & Aesthetics
- **Dark/Light Theme**: Automatic system detection with manual override.
- **Curated CoSpend Palette**:
  - *Jade Green* (`#00BC57` / `hsla(148, 100%, 37%, 1)`): Primary brand accent, progress fill, budget remainder, and CTAs.
  - *Prussian Blue* (`#0A2542` / `hsla(211, 74%, 15%, 1)`): Deep navy contrast headers, dark mode foundation canvas, and card borders.
  - *Crisp White & Soft Slate* (`#FFFFFF` / `#F8FAFC`): Clean, uncluttered light mode canvas eliminating visual noise.
- **Brand Identity & Iconography**:
  - Official high-resolution CoSpend emblem (`assets/images/app_logo.png`).
  - Production-ready Android mipmap launcher icons generated across all densities (`mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`).
- **Zero Non-Constant Icon Crashes**: Pre-indexed `IconData` maps to guarantee stability in Android AOT release builds.

---

## 7. Success Metrics & KPIs
1. **Onboarding Conversion**: $> 90\%$ of users who receive an invite code successfully join a flat on the first attempt.
2. **Expense Logging Speed**: Average time to log an expense $< 12$ seconds.
3. **Crash-Free Sessions**: $> 99.8\%$ stability across release builds.
4. **Budget Utilization**: $> 75\%$ of active flats set and maintain category limits.
