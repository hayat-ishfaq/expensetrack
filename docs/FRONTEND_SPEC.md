# CoSpend — Frontend Specification Document

**Version**: 1.5.0  
**Design Philosophy**: Premium Fintech & Modern Banking (inspired by Revolut, Wise, and Monarch Money)  
**Target Platform**: Android (API 21+) & iOS (iOS 13+)  

---

## 1. Visual Design System & Tokens

Defined centrally in `lib/core/theme/design_system.dart` and implemented via `lib/core/theme/app_theme.dart`.

### 1.1 Curated Color Palette
Strict 5-hue financial palette guaranteeing visual harmony:

| Token | Hex | HSL | Role / Purpose |
| :--- | :--- | :--- | :--- |
| **Prussian Blue** | `#0A2542` | `211°, 74%, 15%` | Primary headers, hero amounts, active filter pills, avatar accent rings, deep gradient hero cards |
| **Jade Green** | `#00BC57` | `148°, 100%, 37%` | Brand accent, primary CTAs, active tab indicators, progress bar "on-track" fill |
| **Pure White** | `#FFFFFF` | `0°, 0%, 100%` | Card surfaces, modal sheets, dialog backgrounds, button text on dark surfaces |
| **Canvas Background** | `#F7F8FA` | `220°, 20%, 98%` | Warm off-white page background providing high-contrast elevation for white cards |
| **Alert Red** | `#EF4444` | `0°, 84%, 60%` | Strictly reserved for budget-exceeded alerts and destructive action confirmations |

### 1.2 Geometry & Corner Radii
- **Cards, Containers & Text Inputs**: Strict `12px` rounded corners (`CoSpendRadii.card = 12.0`).
- **Buttons, Chips, Badges & Search Bars**: Full stadium pills (`CoSpendRadii.pill = 999.0`).
- **No ad-hoc border radii**: Every interactive element strictly maps to `12px` or `999px`.

### 1.3 Depth & Elevation (Fintech Shadows)
- Replaces harsh Material shadows and thick black borders with subtle Prussian-Blue-tinted depth:
  ```dart
  BoxShadow(
    color: Color(0x0C0A2542), // 5% opacity Prussian Blue
    blurRadius: 14,
    offset: Offset(0, 4),
  )
  ```

### 1.4 Typography & Hierarchy
- **Primary Headings & Hero Amounts**: High contrast Prussian Blue (`#0A2542`), 20–36px bold.
- **Section Labels**: 11–12px, semibold, uppercase, letter-spacing `0.8` (e.g. `RECENT TRANSACTIONS`, `CATEGORY BREAKDOWN`).
- **Captions & Metadata**: Slate gray (`#64748B`), 12–13px regular.
- **Numbers & Monetary Figures**: Bold tabular figures with explicit currency prefix (`Rs. X,XXX`).

---

## 2. Core Reusable Fintech Components

### 2.1 `CoSpendCard`
- White card container with `12px` corner radius, `Color(0x0C0A2542)` soft shadow, and optional 1px subtle border.

### 2.2 `BouncingButton`
- Wrapper for clickable surfaces providing tactile `0.97` scale-down physics on tap with swift recovery.

### 2.3 `TintedIcon`
- 36px circular tinted icon container in Prussian Blue (`0x140A2542`) or Jade Green (`0x1400BC57`), delivering consistent visual weight without random rainbow chips.

### 2.4 `CoSpendSegmentedControl`
- Custom sliding pill control replacing Flutter's default blocky `SegmentedButton`. Supports smooth thumb animation across split options.

### 2.5 `SectionLabel`
- Standardized uppercase header widget enforcing typography guidelines across all screens.

---

## 3. Screen-by-Screen Specifications

### 3.1 HomeScreen (Dashboard)
- **Top Bar**:
  - Full user name with dynamic time greeting (`Good afternoon, Bilal 👋`).
  - User avatar with thin Prussian Blue accent border.
  - Interactive pill month selector dropdown (`March 2026 ▾`).
  - Notification bell with unread badge opening `NotificationsSheet`.
- **4-Card Financial Metric Grid** (`FinancialCard`):
  - 2x2 grid displaying:
    1. *Total Allocated Budget* (Prussian Blue tinted icon, household target)
    2. *Total Spendings* (Jade Green tinted icon, total flat spend)
    3. *Your Total Allocated Share* (Prussian Blue tinted icon, personal quota)
    4. *Total Spending by You* (Jade Green tinted icon, personal out-of-pocket)
  - Top-left 36px circular icon, bold hero amount, 11px uppercase label, and helper subtitle.
- **Hero Budget Progress Card** (`BudgetProgressCard`):
  - Deep Prussian Blue gradient (`#0A2542` $\to$ `#133863`).
  - Bold white spending figures with Jade Green progress bar.
  - Single-hue status rows: Jade Green for $<80\%$, Amber for $80-99\%$, Alert Red for $\ge 100\%$.
- **Exceeded Alert Banner**:
  - Soft `#FFF5F5` background, solid red left accent stripe, concise overspend explanation.
- **Recent Transactions Feed**:
  - Clean `CoSpendCard` rows with `TintedIcon` category badge, roommate attribution, and bold amount.
- **Floating Action Button (FAB)**:
  - Solid Jade Green stadium pill (`+ Add Expense`) with soft floating drop shadow.

### 3.2 ExpensesScreen (Feed & Filter)
- **Pill Search Bar**: Stadium-shaped text input with subtle shadow and magnifying glass icon.
- **Segmented Filter Chips**:
  - Active: Solid Prussian Blue pill with white text.
  - Inactive: Crisp white pill with thin 1px border.
- **Transaction Cards**: 12px rounded cards grouped under date section headers.

### 3.3 AddExpenseScreen (Expense Logging)
- **Minimalist Hero Amount Input**: Clean card with "Rs." prefix in Prussian Blue and 36px bold amount input.
- **Metadata Selector Chips**: 12px rounded dropdown chips for Category and Date.
- **Sub-category Pills**: Horizontal scrollable list with Jade Green active fill.
- **"Paid by" Selector**: Roommate avatar with outlined "Change" pill.
- **Sliding Split Mode Switcher**: `CoSpendSegmentedControl` supporting *Equally*, *Unequally*, and *Percentage*.
- **Roommate Checklist**: Circular Jade Green check toggles replacing square checkboxes.
- **Save CTA**: Solid stadium Jade Green button with `BouncingButton` micro-interaction.

### 3.4 CategoryBudgetScreen (Budgets Tab)
- **Summary Hero**: Deep Prussian Blue gradient card displaying total flat target vs. actual total spent.
- **Category Cards**:
  - Subtle `CONFIGURED` or `EXCEEDED` pill badge instead of full card colored borders.
  - **No Disabled Input Chrome**: When viewed by roommates, fields render clean, bold statement-style text (`Rs. 15,000 / month` or `'Not set'`).
- **Owner Edit Flow**: Modal bottom sheet with quick adjustment pills (`+1k`, `+5k`, `+10k`) and a stadium save button.

### 3.5 MoreScreen (Settings & Profile)
- **Profile Card**: Clean `CoSpendCard` with accent-bordered user avatar, flatmate name, role tag pill (`FLAT OWNER` / `ROOMMATE`), and contact details.
- **Standardized Settings Rows**: 52px items with `TintedIcon` leading widgets, chevron trailing icons, and inset 1px dividers.
- **Appearance Selector**: Custom Jade Green active ring/dot radio indicators for Theme Mode (System, Light, Dark).
- **Danger Actions**: Leave Flat and Sign Out rows styled with Alert Red tinted icons.

### 3.6 NotificationsSheet
- Modal bottom sheet with top drag handle pill, circular Jade Green bell icon, and clean transaction activity cards with relative timestamps (`"2m ago"`).

---

## 4. Micro-Interactions & Physics
1. **Tap Feedback**: `BouncingButton` reduces scale to `0.97` on tap down and springs back smoothly on release.
2. **Progress Animation**: All linear and circular progress indicators animate over `600ms` using `Curves.easeOutCubic`.
3. **Pill Transitions**: Filter chips and segmented controls transition background colors over `200ms`.
