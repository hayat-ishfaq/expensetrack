# CoSpend — Technical Architecture Document

**System Version**: 2.0.0  
**Stack**: Flutter (Dart 3.x), Riverpod 3.x, Firebase (Auth & Cloud Firestore), GoRouter, Lottie  
**Target Environments**: Android (API 21+), iOS (iOS 13+)  

---

## 1. Architectural Philosophy & Overview
**CoSpend** (formerly FlatSplit) is engineered around **Feature-First Clean Architecture** principles, enforcing strict separation of concerns, single-direction data flow, and isolated testability.

```
┌────────────────────────────────────────────────────────┐
│                   Presentation Layer                   │
│   (Widgets, Screens, AsyncNotifiers, Riverpod State)    │
└───────────────────────────┬────────────────────────────┘
                            │ depends on
┌───────────────────────────▼────────────────────────────┐
│                      Domain Layer                       │
│    (Entities, Business Logic Engines, Repositories)    │
└───────────────────────────▲────────────────────────────┘
                            │ implemented by
┌───────────────────────────┴────────────────────────────┐
│                       Data Layer                       │
│   (Firebase Repositories, DTO Mappers, Firestore API)   │
└────────────────────────────────────────────────────────┘
```

### Key Pillars:
1. **Unidirectional Reactive Flow**: UI triggers actions on Riverpod Notifiers -> Notifiers invoke Domain Repositories -> Data Layer updates Firestore -> Firestore Streams emit real-time snapshots back into Riverpod providers -> UI reacts smoothly.
2. **Integer-Safe Monetary Engine**: Floating-point rounding errors (`0.1 + 0.2 = 0.30000000000000004`) are strictly prohibited in financial code. All amounts are stored and computed in 64-bit integer paisas (`1 PKR = 100 Paisa`).
3. **Strict Domain Purity**: Domain entities and mathematical engines (e.g. `SettlementEngine`, `SplitCalculator`, `InviteCode`) have zero dependencies on Flutter or Firebase, enabling blazing fast unit test execution ($< 2$ seconds for the entire test suite).
4. **Fintech Design System Layer**: Centralized visual tokens, geometry, and micro-interactions encapsulated in `lib/core/theme/design_system.dart`.

---

## 2. Directory & Package Structure
The codebase follows a modular feature-first layout under `lib/`:

```
lib/
├── main.dart                   # Application entrypoint (instant non-blocking start)
├── splash_screen.dart          # Lottie animated splash & startup coordinator
├── app/                        # Application composition root
│   ├── app.dart                # MaterialApp.router configuration & theme bindings
│   ├── router/                 # Navigation contracts & route definitions
│   │   ├── app_router.dart     # GoRouter instance & dynamic auth/household redirect logic
│   │   ├── routes.dart         # Path constants
│   │   └── not_found_screen.dart
│
├── core/                       # Shared platform primitives & utilities
│   ├── constants/              # AppConstants, FirestoreCollections
│   ├── errors/                 # AppException hierarchy & FirebaseErrorMapper
│   ├── theme/                  # Design System, Lufga Typography & Theme Engine
│   │   ├── app_theme.dart      # ThemeData configuration (Light & Dark)
│   │   └── design_system.dart  # Tokens, Colors, Shadows, Radii & Reusable Widgets
│   └── utils/                  # Money (Paisa formatting), Validators, DateFormatters
│
├── features/                   # Encapsulated vertical feature slices
│   ├── auth/                   # Authentication, profile & avatar studio
│   │   ├── domain/             # AuthUser, AuthRepository, SessionState
│   │   ├── data/               # FirebaseAuthRepository
│   │   └── presentation/       # Login, SignUp, Onboarding, EditProfileScreen, AvatarPickerSheet
│   ├── household/              # Flat setup, members, invite codes & notifications
│   │   ├── domain/             # Household, HouseholdMember, InviteCode, SpendNotification
│   │   ├── data/               # FirebaseHouseholdRepository
│   │   └── presentation/       # CreateFlat, JoinFlat, NotificationsSheet, HouseholdProviders
│   ├── expenses/               # Expense logging, custom categories, splitting
│   │   ├── domain/             # Expense, SplitCalculator, CustomCategory
│   │   ├── data/               # FirebaseExpenseRepository
│   │   └── presentation/       # AddExpenseScreen, ExpensesScreen, ExpenseProviders
│   ├── dashboard/              # Aggregations, financial cards, budget targets & velocity
│   │   ├── domain/             # DashboardStats
│   │   └── presentation/       # CategoryBudgetScreen, FinancialCard, BudgetProgressCard
│   ├── settlement/             # Debt minimization engine & settlement records
│   │   ├── domain/             # SettlementEngine, Balance, Transfer
│   │   ├── data/               # FirebaseSettlementRepository
│   │   └── presentation/       # SettleUpScreen, SettlementProviders
│   └── shell/                  # App shell & primary navigation
│       └── presentation/       # AppShellScreen, HomeScreen, MoreScreen
│
└── shared/                     # Reusable cross-feature widgets and models
    ├── models/                 # AppUser, Household, HouseholdMember
    └── widgets/                # AppAvatar, LoadingButton, AppSnackbar, ConfirmDialog
```

---

## 3. State Management Topology (Riverpod 2.x)

```mermaid
graph TD
    A[authStateProvider] --> B[currentUserProvider]
    B --> C[sessionProvider: SessionState]
    C --> D[appRouterProvider: GoRouter Redirects]
    C --> E[currentHouseholdProvider]
    E --> F[householdMembersProvider]
    E --> G[expensesStreamProvider]
    E --> N[householdNotificationsStreamProvider]
    G --> H[dashboardStatsProvider: Monthly Aggregations]
    H --> I[budgetStatusProvider: Household Limits]
    H --> J[categoryBudgetsStatusProvider]
    H --> K[myCategoryBudgetsStatusProvider]
    G --> L[settlementBalancesProvider: SettlementEngine]
    L --> M[suggestedTransfersProvider: Greedy Debt Minimizer]
```

### 3.1 Session State Machine (`SessionController`)
- **`SessionInitializing`**: App is booting, displaying the splash screen.
- **`SessionSignedOut`**: No Firebase user authenticated. Router locks navigation to `/welcome`, `/login`, `/signup`, or `/onboarding`.
- **`SessionNeedsHousehold`**: User signed in, but `user.householdId == null`. Router directs user to `/household/setup`.
- **`SessionReady`**: User signed in with an active flat. Full access to Home, Expenses, Budgets, and More.

---

## 4. Firestore Data Model & Schema

```
/users/{userId}
  ├── name: String
  ├── email: String
  ├── householdId: String?
  ├── photoUrl: String?           # Base64 data URI or HTTP/HTTPS URL
  ├── phoneNumber: String?        # Contact / WhatsApp number
  ├── upiId: String?              # Payment handle (UPI / EasyPaisa / JazzCash)
  ├── roomNotes: String?          # Room assignment / bio
  └── createdAt: Timestamp

/inviteCodes/{code} (e.g. "FLAT-7K29")
  ├── householdId: String
  └── createdAt: Timestamp

/households/{householdId}
  ├── name: String
  ├── ownerId: String
  ├── inviteCode: String
  ├── memberCount: int
  ├── monthlyBudgetPaisa: int
  ├── categoryBudgetsPaisa: Map<String, int>
  ├── memberCategoryBudgetsPaisa: Map<String, Map<String, int>>
  ├── customCategories: List<Map> [id, label, iconCodePoint, colorValue, subcategories]
  ├── categorySubcategories: Map<String, List<String>>
  ├── currency: String ("PKR")
  ├── createdAt: Timestamp
  │
  ├── /members/{userId}
  │     ├── name: String
  │     ├── email: String
  │     ├── role: String ("owner" | "member")
  │     ├── photoUrl: String?
  │     ├── phoneNumber: String?
  │     ├── upiId: String?
  │     ├── roomNotes: String?
  │     └── joinedAt: Timestamp
  │
  ├── /expenses/{expenseId}
  │     ├── title: String
  │     ├── amountPaisa: int
  │     ├── category: String (enum name or custom id)
  │     ├── customCategoryId: String?
  │     ├── subcategory: String?
  │     ├── paidByUserId: String
  │     ├── participantUserIds: List<String>
  │     ├── splitMode: String ("equal" | "custom" | "percentage")
  │     ├── customSplitPaisa: Map<String, int>?
  │     ├── date: Timestamp
  │     ├── createdByUserId: String
  │     └── createdAt: Timestamp
  │
  ├── /settlements/{settlementId}
  │     ├── fromUserId: String
  │     ├── toUserId: String
  │     ├── amountPaisa: int
  │     ├── settledAt: Timestamp
  │     └── recordedByUserId: String
  │
  └── /notifications/{notificationId}
        ├── eventType: String ("expense_created" | "budget_exceeded")
        ├── title: String
        ├── message: String
        ├── actorId: String
        ├── actorName: String
        ├── amountPaisa: int?
        ├── createdAt: Timestamp
        └── readByUserIds: List<String>
```

---

## 5. Domain Engines & Algorithms

### 5.1 Settlement Engine (`SettlementEngine.expenses`)
Computes the minimal transfer network between $N$ roommates:
1. **Net Balance Calculation**:
   $$\text{Balance}(u) = \sum \text{PaidBy}(u) - \sum \text{OwedBy}(u)$$
   $$\sum_{u \in \text{Members}} \text{Balance}(u) \equiv 0$$
2. **Greedy Debt Pairing**:
   - Members with $\text{Balance} > 0$ are Creditors.
   - Members with $\text{Balance} < 0$ are Debtors.
   - Match the largest debtor with the largest creditor:
     $$\text{TransferAmount} = \min(-\text{Debtor.balance}, \text{Creditor.balance})$$
   - Deduct transfer amount, repeat until all balances reach zero.
   - **Guarantee**: Produces at most $N - 1$ payments, completely avoiding circular or redundant repayments.

### 5.2 Integer Split Engine (`SplitCalculator.split`)
Distributes an expense of $A$ paisas across $M$ participants:
- Base share: $S = \lfloor A / M \rfloor$.
- Remainder: $R = A \pmod M$.
- First $R$ participants receive $S + 1$ paisas; remaining participants receive $S$ paisas.
- **Guarantee**: $\sum \text{Shares} \equiv A$ with zero drift and at most 1 paisa variance.

### 5.3 Icon Font Tree Shaking & Custom Category Engine
To eliminate Flutter Android release build failures caused by dynamic `IconData(codePoint)` invocations during tree shaking:
- Pre-registers a static const table `CustomCategory.knownIcons` containing 36 curated material icons.
- Looks up const `IconData` instances in $O(1)$ time, falling back safely to `Icons.category_rounded`.
- Works out-of-the-box with standard `--release` builds without requiring `--no-tree-shake-icons`.

### 5.4 Non-Blocking Startup & Lottie Splash Sequence
To eliminate startup lag and white/black flashes on app cold launch:
- `main()` calls `WidgetsFlutterBinding.ensureInitialized()` and `runApp(const ProviderScope(child: CoSpendApp()))` immediately without blocking on Firebase I/O.
- Firebase, FCM, and local notifications initialize concurrently in the background while the UI draws the splash screen on the very first frame.
- Android 12+ Splash API and `launch_background` are styled with a clean white canvas (`#FFFFFF`) with transparent icon, handing rendering seamlessly to Flutter.
- [`lib/splash_screen.dart`](file:///lib/splash_screen.dart) plays `assets/animations/logo_splash.json` (~2.5s) using an `AnimationController` on a white background with a smooth `FadeTransition` for the "CoSpend" title.
- Navigation away from splash is strictly driven by the animation completing (`_controller.forward().then(...)` triggering `splashAnimationCompletedProvider`), with zero arbitrary `Future.delayed` timers.

### 5.5 Budgets Hub Velocity & Limit Management Architecture
`CategoryBudgetScreen` orchestrates financial planning through three core sub-architectures:
1. **Spending Velocity Analysis (`_SpendingTrendsSheet`)**:
   - Calculates daily burn rate: $\text{DailyAvg} = \text{TotalSpent} / \text{CurrentDay}$.
   - Projects month-end spending: $\text{Projected} = \text{DailyAvg} \times \text{DaysInMonth}$.
   - Daily allowance for remaining cycle: $\text{Allowance} = (\text{Budget} - \text{Spent}) / \text{RemainingDays}$.
   - Renders interactive daily bar chart via `fl_chart: ^1.2.0` with touch tooltips and category velocity ranking.
2. **Bulk Limit Controls (`_ManageLimitsSheet`)**:
   - Instant percentage scaling (`+10%`, `+20%`, `+50%`, `-10%`, `-25%`).
   - Even target auto-distribution: divides total flat budget evenly across all categories.
   - Snaps limits to current monthly spend.
   - Splits limits equally across roommates.
3. **Health Indicator Engine**:
   - 🟢 **On Track** ($< 80\%$ budget consumed).
   - 🟡 **Near Limit** ($80\% - 99\%$ budget consumed).
   - 🔴 **Over Budget** ($\ge 100\%$ budget consumed).

---

## 6. Fintech Design System Architecture (`lib/core/theme/design_system.dart`)

### 6.1 Typography (`Lufga`)
All text across both Light and Dark themes uses the **Lufga** geometric font family (`CoSpendTypography.fontFamily = 'Lufga'`), packaged locally from `assets/fonts/lufga/` across all 18 standard weight/style variants (100 Thin to 900 Black).

### 6.2 Visual Tokens
The UI layer is decoupled from ad-hoc styling via strict tokens:
- **`CoSpendColors`**:
  - `prussianBlue`: `#0A2542` (Primary Brand & Typography)
  - `jadeGreen`: `#00BC57` (Accent & On-Track Indicator)
  - `canvas`: `#F7F8FA` (Slightly warm off-white surface)
  - `cardSurface`: `#FFFFFF` (Elevated card background)
  - `alertRed`: `#EF4444` (Exclusively for budget breaches)
- **`CoSpendRadii`**:
  - `card`: `16px`
  - `cardLarge`: `20px`
  - `input`: `16px`
  - `pill`: `999px`
- **`CoSpendShadows`**:
  - `softCard`: `BoxShadow(color: Color(0x0D0A2542), blurRadius: 18, offset: Offset(0, 4), spreadRadius: -2)`
  - `hero`: `BoxShadow(color: Color(0x500A2542), blurRadius: 32, offset: Offset(0, 12), spreadRadius: -8)`
  - `fabGlow`: `BoxShadow(color: Color(0x4400BC57), blurRadius: 24, offset: Offset(0, 8), spreadRadius: -4)`
- **Reusable Fintech Primitives**:
  - `CoSpendCard`: 16px rounded, soft-shadowed white container.
  - `BouncingButton`: Micro-interaction component with 0.97 scale tap feedback.
  - `TintedIcon`: 36px circular tinted icon container in Prussian Blue or Jade Green.
  - `SectionLabel`: 11px uppercase semibold label with 1.0 letter-spacing.
  - `CoSpendSegmentedControl`: Custom sliding pill control replacing stock Flutter widgets.

---

## 7. Error Handling & Resilience
- **`AppException` Hierarchy**: Typed, structured application errors (`AuthException`, `HouseholdException`, `NetworkException`, `ValidationException`).
- **`FirebaseErrorMapper`**: Maps low-level platform error codes (`invalid-credential`, `permission-denied`, `unavailable`) into clear, actionable user messages.
- **Dual Invite Lookup**: When joining a flat, queries the `inviteCodes` index; if absent, falls back to querying `households` by `inviteCode` and automatically self-heals the index.
- **Resilient Profile Persistence**: Uses Firestore `.set(userUpdates, SetOptions(merge: true))` to safely handle new or partial documents, and isolates data URIs from `FirebaseAuth.currentUser.updatePhotoURL()`.

