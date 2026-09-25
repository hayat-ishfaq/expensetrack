# CoSpend — Frontend Specification Document

**Version**: 2.0.0  
**Design Philosophy**: Ultra-clean Premium Fintech (inspired by Revolut, Monarch Money, and Apple Wallet)  
**Target Platform**: Android (API 21+) & iOS (iOS 13+)  
**Last Updated**: September 2026

---

## 1. Visual Design System & Tokens

Defined centrally in `lib/core/theme/design_system.dart` and implemented via `lib/core/theme/app_theme.dart`.

### 1.1 Curated Color Palette
Strict 5-hue financial palette guaranteeing visual harmony:

| Token | Hex | HSL | Role / Purpose |
| :--- | :--- | :--- | :--- |
| **Prussian Blue** | `#0A2542` | `211°, 74%, 15%` | Primary headers, hero amounts, active filter pills, avatar accent rings, deep gradient hero cards |
| **Jade Green** | `#00BC57` | `148°, 100%, 37%` | Brand accent, primary CTAs, active tab indicators, progress bar "on-track" fill, avatar gradient ring |
| **Pure White** | `#FFFFFF` | `0°, 0%, 100%` | Card surfaces, modal sheets, dialog backgrounds, button text on dark surfaces |
| **Canvas Background** | `#F5F7FA` | `220°, 20%, 98%` | Slightly cooler off-white page background providing high-contrast elevation for white cards |
| **Alert Red** | `#EF4444` | `0°, 84%, 60%` | Strictly reserved for budget-exceeded alerts and destructive action confirmations |

#### Extended Tokens
| Token | Hex | Role |
| :--- | :--- | :--- |
| `textSecondary` | `#2D4A6A` | Secondary prose text |
| `darkCanvas` | `#050F1C` | Deep true-dark page background |
| `darkCard` | `#0B1F38` | Dark mode card surface |
| `darkCardElevated` | `#102A4C` | Elevated dark card (modals, popovers) |
| `darkTextMuted` | `#8BA4C0` | Softer dark mode secondary text |
| `glassWhite` | `rgba(255,255,255,10%)` | Glassmorphism card overlays on gradient heroes |
| `glassBorderWhite` | `rgba(255,255,255,20%)` | Glassmorphism border on gradient heroes |

#### Hero Gradient
3-stop Prussian Blue gradient (`#0A2542 → #0E3060 → #163E78`) used on:
- Hero Budget Progress Card
- Settle Up summary card
- "Owner" role pill badge gradient

### 1.2 Geometry & Corner Radii
- **Cards, Containers & Text Inputs**: `16px` rounded corners (`CoSpendRadii.card = 16.0`). *(Upgraded from 12px)*
- **Hero Cards**: `20px` rounded corners (`CoSpendRadii.cardLarge = 20.0`) for visually prominent cards.
- **Small containers**: `8px` (`CoSpendRadii.xs = 8.0`) for icon boxes, mini chips.
- **Buttons, Chips, Badges & Search Bars**: Full stadium pills (`CoSpendRadii.pill = 999.0`).
- **No ad-hoc border radii**: Every interactive element strictly maps to `8px`, `16px`, `20px`, or `999px`.

### 1.3 Spacing System (4pt Grid)
```dart
abstract final class CoSpendSpacing {
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double base = 16.0;
  static const double lg   = 20.0;
  static const double xl   = 24.0;
  static const double xxl  = 32.0;
}
```

### 1.4 Depth & Elevation (Premium Fintech Shadows)
Replaces harsh Material shadows with soft Prussian-Blue-tinted depth with spread-radius:
```dart
// Standard card shadow
BoxShadow(color: Color(0x0D0A2542), blurRadius: 18, offset: Offset(0, 4), spreadRadius: -2)

// Hero banner shadow (deep, punchy)
BoxShadow(color: Color(0x500A2542), blurRadius: 32, offset: Offset(0, 12), spreadRadius: -8)

// Floating FAB green glow
BoxShadow(color: Color(0x4400BC57), blurRadius: 24, offset: Offset(0, 8), spreadRadius: -4)

// Navigation bar top shadow
BoxShadow(color: Color(0x140A2542), blurRadius: 24, offset: Offset(0, -4))
```

### 1.5 Typography & Hierarchy
- **Page AppBar Titles**: 20px, `FontWeight.w800`, letterSpacing `-0.5` (e.g., "Expenses", "More").
- **Primary Headings & Hero Amounts**: High contrast Prussian Blue, 22–30px, `w800`, letterSpacing `-0.6` to `-0.8`.
- **Section Labels**: 11px, `w700`, uppercase, letterSpacing `1.0` (e.g., `RECENT TRANSACTIONS`). *(Upgraded from 0.8)*
- **Captions & Metadata**: Slate gray (`#64748B`), 11–13px regular.
- **Numbers & Monetary Figures**: Bold tabular figures with explicit currency prefix (`Rs. X,XXX`).

### 1.6 Border Strategy
- Light mode: `0.8px` border, `#EAEff6` (soft blue-white).
- Dark mode: `0.8px` border, `#1A3455` (subtle deep navy).
- Warning state: `0.8px` border, `alertRed` at 30% opacity.

---

## 2. Core Reusable Fintech Components

### 2.1 `CoSpendCard`
- White card container with `16px` corner radius, `Color(0x0D0A2542)` soft shadow (spread: -2), and optional `0.8px` subtle border.
- Supports optional `onTap` with `BouncingButton` micro-interaction.

### 2.2 `BouncingButton`
- Wrapper for clickable surfaces providing tactile `0.97` scale-down physics on tap.
- 90ms press, 160ms spring release — matches Apple's UIKit spring feel.

### 2.3 `TintedIcon`
- 40px circular tinted icon container in Prussian Blue (`0.10` alpha) or Jade Green (`0.10` alpha).
- 34px variant used on `_MetricCard` for visual hierarchy.

### 2.4 `CoSpendSegmentedControl`
- Custom sliding pill control replacing Flutter's default blocky `SegmentedButton`.
- `0.8px` outer border, smooth 200ms thumb animation.

### 2.5 `SectionLabel`
- Standardized uppercase header: `11px`, `w700`, letterSpacing `1.0`.

### 2.6 `HeroBudgetCard`
- **New**: 3-stop Prussian Blue gradient hero (`#0A2542 → #0E3060 → #163E78`).
- **New**: 20px cardLarge radius.
- **New**: Glassmorphism icon container with white glass border.
- **New**: Animated gradient progress bar (green → amber → red) with glowing drop shadow.
- **New**: Apple Wallet-style percentage pill badge replacing plain percentage text.

### 2.7 `CoSpendColors.heroGradient`
3-stop gradient constant usable across all gradient hero surfaces.

---

## 3. Screen-by-Screen Specifications

### 3.1 HomeScreen (Dashboard)
- **Top Bar**:
  - Full user name with dynamic time greeting (`Good afternoon, Bilal 👋`).
  - User avatar with **jade-green → prussian-blue gradient ring** (double-container technique). *(Upgraded)*
  - Interactive pill month selector with **green dot indicator + neutral text**. *(Upgraded)*
  - Notification bell with unread badge opening `NotificationsSheet`.
- **4-Card Financial Metric Grid** (`FinancialSummaryCards`):
  - 2x2 grid with 10px gutter, 34px icon circles, `0.8px` borders.
  - Amount: 17px, `w800`, letterSpacing `-0.5`.
  - Label: 10px, `w700`, letterSpacing `0.8`.
- **Hero Budget Progress Card** (`BudgetProgressCard`):
  - 3-stop Prussian Blue gradient with glassmorphism icon ring.
  - Bold white 30px spending figure.
  - 6px animated gradient progress bar with color-matching glow.
  - Apple Wallet-style percentage pill badge (background + border at 18%/30% opacity).
- **Exceeded Alert Banner**: Soft red-tinted background, left accent stripe, concise overspend explanation.
- **Recent Transactions Feed**: `CoSpendCard` rows with `TintedIcon` category badge.
- **FAB**: Solid Jade Green stadium pill (`+ Add Expense`) with strong green glow shadow.

### 3.2 ExpensesScreen (Feed & Filter)
- **AppBar**: 20px `w800` title, letterSpacing `-0.4`.
- **Pill Search Bar**: Stadium-shaped text input with subtle shadow.
- **Segmented Filter Chips**: Active: Solid Prussian Blue pill. Inactive: transparent with 1px border.
- **Transaction Cards**: 16px rounded cards grouped under date section headers.
- **FAB**: Matches Home screen.

### 3.3 SettleUpScreen (Balances & Transfers) *(Major redesign)*
- **Summary Hero Card**: Full 3-stop gradient (`20px` radius) with glassmorphism icon container.
  - 28px `w800` total amount, tabular figures.
  - "Across all flatmates" caption at 60% white opacity.
- **Balance Tiles**: `CoSpendCard` rows with:
  - Circular monogram avatar (Prussian Blue tint).
  - Name + description column.
  - Color-coded pill badge (`jadeGreenTint` for credit, `alertRedTint` for debit).
- **Transfer Tiles**: `CoSpendCard` rows with rounded arrow icon box, bold rich-text `fromName pays toName`.
- **All Settled State**: Premium celebration layout — large circle icon + headline + body. *(Upgraded from generic EmptyState)*
- **Skeleton**: Radii-matched skeleton boxes (`radius: 16`).

### 3.4 CategoryBudgetScreen (Budgets Tab)
- **Summary Hero**: 3-stop Prussian Blue gradient card.
- **Category Cards**: Subtle `CONFIGURED` or `EXCEEDED` pill badge.
- **No Disabled Input Chrome**: Clean read-only statement text for roommates.
- **Owner Edit Flow**: Modal bottom sheet with quick adjustment pills.

### 3.5 MoreScreen (Settings & Profile)
- **Profile Card**: `CoSpendCard` with **jade-green → prussian-blue gradient ring** on avatar. *(Upgraded)*
  - "Owner" role badge with gradient fill (not flat blue). *(Upgraded)*
  - Chevron trailing instead of edit icon.
- **Standardized Settings Rows**: `TintedIcon` leading widgets, chevron trailing icons, inset dividers.
- **Appearance Selector**: Jade Green active ring/dot radio indicators.
- **App Version**: Styled pill badge (surfaceMuted background + 0.8px border). *(Upgraded from plain text)*
- **Danger Actions**: Alert Red tinted icons for Leave Flat and Sign Out.

### 3.6 AppShellScreen (Navigation)
- **Top border separator**: `0.8px` `borderLight` line above nav bar.
- **Nav bar shadow**: Soft upward Prussian Blue shadow.
- **Haptic feedback**: `HapticFeedback.selectionClick()` on tab selection.
- **Icons**: Upgraded to `donut_large` (Budgets) and `grid_view` (More) for sharper visual language.
- **Height**: `64px` nav bar height.
- **Label**: `11px`, `w800` selected, `w500` unselected, letterSpacing `0.1` active.

### 3.7 NotificationsSheet
- Modal bottom sheet with top drag handle pill, circular Jade Green bell icon.
- Clean transaction activity cards with relative timestamps (`"2m ago"`).

---

## 4. Micro-Interactions & Physics

1. **Tap Feedback**: `BouncingButton` reduces scale to `0.97` on tap down (90ms) and springs back (160ms) — Apple UIKit feel.
2. **Progress Animation**: All linear indicators animate over `700ms` using `Curves.easeOutCubic`.
3. **Pill Transitions**: Filter chips and segmented controls transition over `200ms`.
4. **Haptic Tab Switch**: `HapticFeedback.selectionClick()` fires on every bottom nav tab change.
5. **Gradient Progress Glow**: Progress bar fill has a `blurRadius: 6` glow at 55% progress color opacity.

---

## 5. Dark Mode

| Surface | Light | Dark |
| :--- | :--- | :--- |
| Canvas | `#F5F7FA` | `#050F1C` |
| Card | `#FFFFFF` | `#0B1F38` |
| Elevated Card | — | `#102A4C` |
| Border | `#EAEff6` | `#1A3455` |
| Text Primary | `#0A2542` | `#FFFFFF` |
| Text Muted | `#64748B` | `#8BA4C0` |
| Nav Bar Bg | `#FFFFFF` | `#071A2E` |
