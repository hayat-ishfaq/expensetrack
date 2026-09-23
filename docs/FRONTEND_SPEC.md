# FlatSplit — Frontend Specification Document

**Version**: 1.2.0  
**Design System**: Modern Emerald Glassmorphism  
**Target Density**: Mobile (Android & iOS)  

---

## 1. Visual Design System & Tokens

### 1.1 Color Palette
The interface uses a curated, high-contrast palette tailored for financial clarity and premium visual feel.

| Token | Light Theme | Dark Theme | Purpose |
| :--- | :--- | :--- | :--- |
| **Primary** | `#059669` (Emerald 600) | `#10B981` (Emerald 500) | Primary branding, buttons, active indicators |
| **Primary Container** | `#D1FAE5` (Emerald 100) | `#064E3B` (Emerald 900) | Banner accents, active cards |
| **Background / Canvas** | `#F8FAFC` (Slate 50) | `#0F172A` (Slate 900) | App surface canvas |
| **Surface (Cards)** | `#FFFFFF` (White) | `#1E293B` (Slate 800) | Floating cards, tiles, lists |
| **Surface High** | `#F1F5F9` (Slate 100) | `#334155` (Slate 700) | Input fields, chip backgrounds |
| **Text Primary** | `#0F172A` (Slate 900) | `#F8FAFC` (Slate 50) | Primary titles, monetary figures |
| **Text Secondary** | `#64748B` (Slate 500) | `#94A3B8` (Slate 400) | Subtitles, helper text, timestamps |
| **Success / Creditor** | `#10B981` | `#34D399` | Positive balances ("You are owed"), on track |
| **Warning** | `#F59E0B` (Amber 500) | `#FBBF24` (Amber 400) | Approaching budget limit ($> 80\%$) |
| **Danger / Debtor** | `#EF4444` (Red 500) | `#F87171` (Red 400) | Exceeded budget alerts, money owed ("You owe") |

### 1.2 Typography
- **Primary Font**: `GoogleFonts.outfit` for prominent headings and currency values.
- **Secondary Font**: `GoogleFonts.inter` for dense list items, form labels, and body text.
- **Figures / Numbers**: Tabular numerals enabled for aligned financial lists (`fontFeatures: [FontFeature.tabularFigures()]`).

---

## 2. Core Design Components

### 2.1 Metric & Financial Summary Cards (`FinancialSummaryCards`)
- 4 grid cards displaying: **Total Spent**, **Your Share**, **You Paid**, and **Net Balance**.
- Elevated with subtle 1px border borders (`alpha: 0.1`) and soft shadows (`blurRadius: 10, offset: (0, 4)`).
- Distinct color accents: Emerald for positive balances, Coral red for debts.

### 2.2 Budget Progress Card (`BudgetProgressCard`)
- Multi-state card displaying:
  - Header: Status tag (`On track`, `Approaching limit`, `Budget exceeded`).
  - Dual action button: `tune` (Adjust Budgets) for Owner; `visibility` (View Limits) for Members.
  - Linear smooth progress bar with dynamic color transitions (Green $\to$ Amber $\to$ Red).
  - Expandable member quotas drawer ("Show my quotas").

### 2.3 LoadingButton (`LoadingButton`)
- Full-width tactile action button supporting asynchronous loading spinner without layout shifts.
- Disabled state styling with reduced opacity and ripple suppression.

### 2.4 Category Icon & Color Engine
- 36 pre-indexed Material icons (Food, Cart, Bus, Bolt, Wifi, Rent, Gym, Gift, etc.).
- 12 curated vibrant pastel background colors for categories.
- Zero non-constant `IconData` invocations, ensuring smooth release compilation.

---

## 3. Screen-by-Screen Specifications

### 3.1 Authentication & Onboarding
- **OnboardingScreen**: 3-step carousel showcasing:
  1. *Track Shared Expenses with Ease*
  2. *Smart Category Budgets & Quotas*
  3. *One-Tap Debt Settlement*
- **Login & SignUp**: Clean vertical form with instant regex validation, password visibility toggles, and Google/Email options.
- **HouseholdSetupScreen**: Dual entry options:
  - *Create a Flat*: Asks for flat name, generates owner credentials.
  - *Join a Flat*: Input field accepting raw codes (`7K29`) or full WhatsApp pasted text. Automatically navigates to Home on success.

### 3.2 HomeScreen (Dashboard)
- **Top Greeting Bar**: Contextual greeting (`Good morning / afternoon / evening, [User] 👋`) with Flat name badge and quick `Invite (FLAT-XXXX)` action chip.
- **Exceeded Budget Alert Banner**: Prominent warning banner when personal or flat category budget is breached.
- **4 Financial Summary Cards**: Real-time spending calculations.
- **Budget Progress Card**: Real-time progress bar.
- **Daily Spending Trend**: Visual bar breakdown for the active month.
- **Recent Expenses Feed**: Last 5 transactions with category avatars and payer attribution.

### 3.3 ExpensesScreen (List)
- **Month Picker**: Month-by-month filter.
- **Category Filter Chips**: Horizontal scrollable chips for all standard and custom categories.
- **Expense List**: Slidable / clickable expense cards showing title, payer avatar, subcategory chip, date, and share amounts.

### 3.4 AddExpenseScreen
- **Monetary Keypad**: Large input field formatted in Rupees.
- **Category Picker**: Grid of standard categories plus "+ Custom" button launching `CreateCategorySheet`.
- **Sub-Category Filter Chips**: Dynamic tag chips based on selected category, plus inline `+ Sub` add button.
- **Payer Selector**: Horizontal list of roommates.
- **Participant Multi-Select**: Checkboxes to include/exclude specific roommates.
- **Split Mode Switcher**: Tab bar switching between *Equal*, *Unequal (Amounts)*, and *Percentage*.

### 3.5 CategoryBudgetScreen
- **Role-Aware Display**:
  - *Owner View*: Full editing capabilities, "+ Add Custom Category", "Clear All", quick increment chips (`+1,000`, `+5,000`, `+10,000`), "Divide Equally", and floating "Save Budgets" bottom sheet.
  - *Member View*: Prominent lock banner (`"View-Only: Only the flat owner can set or adjust budgets"`). All input fields are disabled (`enabled: false`), increment chips and save buttons are hidden.
- **Member Division Accordion**: Expandable panel under each category allowing the owner to divide limits equally or enter custom member quotas.

### 3.6 SettleUpScreen
- **Net Balances List**: Visual cards showing each member's credit or debit standing.
- **Suggested Debt Transfers**: Smart, minimized payments (e.g. `Hamza pays Bilal Rs. 2,400`).
- **Mark as Settled**: One-tap recording that persists the settlement and zeroes out the debt.

### 3.7 MoreScreen
- **User Profile**: Name, email, and joined flat.
- **Flat Management**:
  - Category Budgets tile (shows target and count for Owner; "View limits" for Member).
  - Join another flat.
  - Share invite sheet (`InviteMembersSheet`).
  - Theme mode selector (Light / Dark / System).
  - Leave flat action with confirmation dialog.
  - Sign out.

---

## 4. Micro-Interactions & Transitions
1. **Button Presses**: 96% scale press animation on primary cards.
2. **Page Navigation**: Clean Material fade/slide transitions via GoRouter.
3. **Dynamic Form Validations**: Error text appears with animated fade-in without shifting layout heights.
4. **Snackbar Feedback**: Non-intrusive floating toasts with semantic icons (check circle for success, exclamation circle for error).
