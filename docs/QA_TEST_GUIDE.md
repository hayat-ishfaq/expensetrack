# CoSpend — Complete App Overview & QA Test Guide

> **Document Version:** 1.0  
> **Target Release:** v1.5.4 (Build 10, Release Build)  
> **Platform:** Android (APK)  
> **APK File:** [`build/app/outputs/flutter-apk/app-release.apk`](file:///C:/Users/M.Hayat/OneDrive/Desktop/expense_track/expensetrack/build/app/outputs/flutter-apk/app-release.apk)  

---

## 1. Executive Summary & App Concept

**CoSpend** is a mobile expense management application designed for roommates, couples, and shared households. It eliminates the friction of group living by offering:
- **Instant Household Sync:** Roommates join a shared household via a unique 6-character invite code.
- **Fair Expense Splitting:** Flexible splitting models (equal split, custom amounts, shares) with optional photo receipt attachments.
- **Smart Debt Settlement:** Automatic simplification of group balances showing exactly "Who owes Whom" with one-tap settle-up.
- **Budgets Hub & Velocity Tracking:** Monthly budget caps per category, member quota tracking, daily spending velocity charts, and bulk budget adjustment tools.
- **Native Experience:** Dark and Light mode support, custom Lufga typography, animated Lottie launch screen, and offline-resilient architecture.

---

## 2. Tech Stack & Environment

| Layer | Technologies |
|---|---|
| **Framework** | Flutter (Dart SDK ^3.4.0) |
| **State Management** | Flutter Riverpod 3.x (`NotifierProvider`, `AsyncNotifierProvider`) |
| **Navigation & Routing** | GoRouter 18.x with session-driven reactive redirects |
| **Backend & Database** | Firebase Authentication, Cloud Firestore, Firebase Storage |
| **Charts & Visualizations**| `fl_chart: ^1.2.0` |
| **Animations** | `lottie: ^3.6.1`, `concentric_transition: ^1.0.3` |
| **Font Family** | Lufga (weights 100 to 900) |
| **Primary Theme Colors**| Prussian Blue (`#0A2542`), Jade Green (`#00BC57`), Dark Canvas (`#050F1C`) |

---

## 3. High-Level User Journeys

```
                    ┌─────────────────────────┐
                    │  App Launch & Lottie    │
                    │      Splash Screen      │
                    └────────────┬────────────┘
                                 │
                   ┌─────────────┴─────────────┐
         [Logged In]                           [Logged Out]
                   │                                   │
                   ▼                                   ▼
        ┌──────────────────────┐           ┌──────────────────────┐
        │ Has Household Setup? │           │  Onboarding Carousel │
        └──────────┬───────────┘           └───────────┬──────────┘
                   │                                   │
         ┌─────────┴─────────┐                         ▼
       [Yes]                [No]           ┌──────────────────────┐
         │                   │             │   Sign Up / Login    │
         │                   ▼             └───────────┬──────────┘
         │          ┌───────────────────┐              │
         │          │ Create / Join Flat│◄─────────────┘
         │          └────────┬──────────┘
         ▼                   ▼
    ┌──────────────────────────────────────────────┐
    │          Main App Shell (Bottom Bar)         │
    │  [Home]  •  [Expenses]  •  [Budgets] • [More] │
    └──────────────────────────────────────────────┘
```

---

## 4. Key Modules & Functional Architecture

### A. Authentication & Onboarding
- **Onboarding Carousel:** 3 full-screen pages with concentric transitions illustrating group tracking, fair splitting, and easy settlement.
- **Sign Up / Login:** Email/password authentication, validation for empty inputs, email formatting, and minimum 6-character password rule.
- **Session Persistence:** Once signed in, closing and reopening the app bypasses auth directly into the dashboard.

### B. Household Management
- **Create Household:** Enter a flat name (e.g., "Apartment 4B"); generates a distinct 6-character uppercase code (e.g., `K9X2P4`).
- **Join Household:** Enter an existing 6-character invite code; instantly loads all historical shared expenses.
- **Roles:** The creator is marked as `Owner` with administrative rights (managing category budget limits); other roommates are `Members`.

### C. Home Dashboard
- **Total Spent Card:** Aggregated monthly household spend with cycle dates.
- **Individual Balance Cards:** Clear indicator showing your net balance (**"You are owed Rs. X"** in green or **"You owe Rs. Y"** in red/amber).
- **Recent Expenses Feed:** Chronological list of expenses with category icon, payer name, and split details.

### D. Expenses & Splitting
- **Add Expense Modal:**
  - Amount in Rupees (auto-converts to Paisa for integer precision).
  - Title & description.
  - Category tag (Food, Rent, Utilities, Groceries, Entertainment, etc., plus custom category creation).
  - Payer selection (who paid the bill).
  - Participants selection (who shares this expense).
  - Receipt image picker (take camera photo or pick from gallery).
- **Expense Details & Deletion:** View receipt image full-screen, view individual breakdown, or delete if authorized.

### E. Budgets Hub (`Budgets` Tab)
- **Spend Donut & Status Pill:** Real-time percentage spent vs. total budget with health indicators (🟢 On Track `<80%`, 🟡 Near Limit `80-99%`, 🔴 Over Budget `100%+`).
- **Spending Trends Sheet:**
  - Velocity metrics: Daily Average, Projected Spend, Peak Spending Day, Daily Allowance.
  - Interactive bar chart showing daily spending cadence with touch tooltips.
  - Category velocity breakdown ranking spending by category with visual progress bars.
- **Manage Limits Sheet (Admin):**
  - Quick percentage adjustment chips (`+10%`, `+20%`, `+50%`, `-10%`, `-25%`).
  - Auto-distribute total target budget across all categories.
  - Snap limits to match current month's actual spending.
  - Split active limits equally across all flatmates.
  - Reset / Clear all limits.
- **Budgeting Health Guide `(i)`:** Informative modal explaining the threshold percentages, member quota allocations, and the 1st-of-month auto-reset cycle.
- **Member Quota Breakdown:** Expandable per-category cards showing each roommate's personal limit and their spend against that limit.

### F. Settlements
- **Debt Matrix Simplification:** Converts complex multi-person debts into minimal pairwise payments (e.g., instead of 5 cross-payments, resolves to 2 direct settlements).
- **Settle Up Flow:** Record cash/bank transfer payment between two roommates to clear balance.

### G. Settings & Appearance
- **Dark Mode / Light Mode:** Instant theme toggle preserving custom Prussian Blue and Jade Green accents.
- **Household Info & Invite Code Copy:** One-tap clipboard copy and native share of the household invite code.
- **Profile Management:** Edit display name and avatar.

---

## 5. Detailed QA Test Cases & Acceptance Matrix

### Module 1: App Launch & Splash Experience
| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---|---|---|---|---|
| **TC-01.1** | Cold Launch Screen | Launch app from home screen icon | Plain white native window appears momentarily with **no** frozen/static logo. | [ ] |
| **TC-01.2** | Animated Lottie Logo | Observe screen immediately after launch | Smooth 2.5s Lottie logo animation plays on pure white background. | [ ] |
| **TC-01.3** | App Title Display | Observe text below logo during animation | **"CoSpend"** title fades in smoothly under the logo in bold Lufga font. | [ ] |
| **TC-01.4** | Post-Animation Routing | Wait for animation to finish | When animation reaches 100%, navigates seamlessly to Onboarding/Login (if logged out) or Home (if logged in). No manual tap required. | [ ] |

---

### Module 2: Authentication & Onboarding
| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---|---|---|---|---|
| **TC-02.1** | Onboarding Carousel | Swipe through onboarding slides | 3 concentric slides transition smoothly with correct titles and descriptions. | [ ] |
| **TC-02.2** | Skip Onboarding | Tap "Skip" or complete slides | Navigates directly to Sign In / Sign Up screen. | [ ] |
| **TC-02.3** | Sign Up Validation | Leave fields blank and tap "Create Account" | Input error messages displayed below empty fields. | [ ] |
| **TC-02.4** | Sign Up Success | Enter valid Name, Email, Password | Account is created in Firebase; user transitions to Household Setup screen. | [ ] |
| **TC-02.5** | Session Persistence | Log in, close app completely, relaunch | App bypasses login and opens directly on the dashboard after splash. | [ ] |
| **TC-02.6** | Logout Flow | Go to More tab ➔ Tap "Logout" | Returns to Login screen; subsequent launch starts at Onboarding/Login. | [ ] |
| **TC-02.7** | Forgot Password Validation | Go to Login ➔ Tap "Forgot password?" ➔ Leave empty or enter invalid email format | Input validation error appears ("Email is required." or "Enter a valid email address."). | [ ] |
| **TC-02.8** | Reset Link Dispatch & Inbox Screen | Enter valid email ➔ Tap "Send reset link" | Seamlessly transitions to "Check your inbox" screen showing the recipient email badge and "Open email app" button. | [ ] |
| **TC-02.9** | Resend Cooldown Timer | On "Check your inbox" screen, observe resend button | Displays a 30-second cooldown countdown (`Resend link in 30s`). Disabled until timer elapses. | [ ] |
| **TC-02.10** | In-App Password Reset (Settings) | While signed in, navigate to More tab ➔ Tap "Reset password" | Confirmation dialog appears; on confirm, triggers reset email to active account with feedback snackbar. | [ ] |

---

### Module 3: Household Setup
| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---|---|---|---|---|
| **TC-03.1** | Create Flat | Enter flat name (e.g. "Green Villa") and submit | Household created; 6-character uppercase code displayed; user is marked as Owner. | [ ] |
| **TC-03.2** | Copy Invite Code | Tap Copy icon next to the invite code | Code copied to clipboard with confirmation toast/snackbar. | [ ] |
| **TC-03.3** | Join Flat (Valid) | Enter valid code on a 2nd device/account | User joins household immediately; sees shared data. | [ ] |
| **TC-03.4** | Join Flat (Invalid)| Enter incorrect 6-character code | Meaningful error message ("Household not found" or "Invalid code"). | [ ] |

---

### Module 4: Expenses & Splitting
| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---|---|---|---|---|
| **TC-04.1** | Add Expense (Equal)| Tap `+` ➔ Enter Rs. 3,000 for "Groceries" ➔ Select 3 members | Expense saved; each member's share is calculated as Rs. 1,000. | [ ] |
| **TC-04.2** | Category Selection | Select default category vs create new custom category | Custom category appears with selected icon and color. | [ ] |
| **TC-04.3** | Attach Receipt | Pick photo from camera/gallery | Image thumbnail previews; uploads successfully to Storage upon saving. | [ ] |
| **TC-04.4** | View Receipt | Tap on saved expense in Expenses tab | Full detail view opens with high-res receipt image viewable. | [ ] |
| **TC-04.5** | Delete Expense | Tap Delete on an expense you created | Confirmation dialog appears; on confirm, balances recalculate automatically. | [ ] |

---

### Module 5: Budgets Hub (New Options)
| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---|---|---|---|---|
| **TC-05.1** | Open Spending Trends | In Budgets tab, tap **"Spending Trends"** button | Bottom sheet opens displaying Daily Average, Projected Spend, Peak Day, Daily Allowance, and Bar Chart. | [ ] |
| **TC-05.2** | Spending Chart Tooltips | Tap on individual bars on the daily chart | Tooltip displays "Day X: Rs. Amount" with dark navy background and crisp text. | [ ] |
| **TC-05.3** | Category Velocity List| Scroll Spending Trends sheet downwards | All categories ranked by spending share with percentage and progress bar. | [ ] |
| **TC-05.4** | Open Manage Limits | In Budgets tab, tap **"Manage Limits"** button | Bottom sheet opens with quick chips, auto-distribute field, and action tiles. | [ ] |
| **TC-05.5** | Percentage Scaling | Tap `+10%` or `-10%` chips | All active category limits scale up/down by 10% in real time. | [ ] |
| **TC-05.6** | Auto-Distribute Total| Type Rs. 60,000 and tap "Distribute Evenly" | 60,000 is distributed evenly across all categories. | [ ] |
| **TC-05.7** | Match Current Spend | Tap "Match Current Spending" tile | Sets every category limit to match what has currently been spent this month. | [ ] |
| **TC-05.8** | Save Limits | Tap "Save Limits" button | Limits persist to Firestore; confirmation snackbar appears; summary card updates. | [ ] |
| **TC-05.9** | Budget Guide `(i)` | Tap `(i)` info icon next to Manage Limits | Guide sheet opens explaining Health Status (🟢/🟡/🔴), category caps, and monthly reset. | [ ] |
| **TC-05.10**| See All Quotas | Tap "See All →" next to Categories header | Toggles expanding and collapsing all roommate member quotas at once. | [ ] |

---

### Module 6: Settlements & Balances
| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---|---|---|---|---|
| **TC-06.1** | Net Balance Accuracy | Tester A pays Rs. 2,000 split with Tester B | Tester A shows "+Rs. 1,000", Tester B shows "-Rs. 1,000". | [ ] |
| **TC-06.2** | Settle Up Flow | Tester B taps "Settle Up" ➔ Selects Tester A ➔ Records payment | Balances reset to Rs. 0; settlement record logged in activity history. | [ ] |

---

### Module 7: Theme & UI Polish
| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---|---|---|---|---|
| **TC-07.1** | Dark Mode Toggle | Go to More ➔ Toggle Dark Theme | Instant switch to deep navy background (`#050F1C`); all text, cards, and charts remain readable. | [ ] |
| **TC-07.2** | Light Mode Toggle | Toggle back to Light Theme | Clean white & light grey surfaces; crisp Prussian Blue headings. | [ ] |
| **TC-07.3** | Font Consistency | Inspect labels across screens | Custom **Lufga** font is applied consistently (no fallback serif/default Roboto). | [ ] |

---

### Module 8: Error Handling & Resilience
| Test ID | Test Scenario | Steps | Expected Result | Pass/Fail |
|---|---|---|---|---|
| **TC-08.1** | Offline Detection | Enable Airplane Mode ➔ Attempt to save expense or sign in | Surfaces friendly banner: *"You're offline. This action will be available when you're connected."* | [ ] |
| **TC-08.2** | Wrong Password / Bad Credentials | Enter wrong password on Login screen | Displays `"Incorrect email or password."` without crashing or showing raw Firebase exception codes. | [ ] |
| **TC-08.3** | Unregistered Reset Email | In Forgot Password, enter unregistered address | Surfaces `"No account found with this email address."` gracefully. | [ ] |
| **TC-08.4** | Rate Limiting Protection | Attempt rapid repeated requests | 30s cooldown prevents form abuse; Firebase `too-many-requests` surfaces *"Too many attempts. Take a short break and try again."* | [ ] |
| **TC-08.5** | Invalid Invite Code | Enter incorrect flat code in Join Flat | Displays validation error *"No flat found with that invite code."* | [ ] |
| **TC-08.6** | Global Screen Error Fallback | Trigger an unexpected display fault | CoSpend styled error fallback screen appears with recovery guidance instead of a blank screen. | [ ] |

---

## 6. How to Report a Defect (Bug Template)

When reporting issues, please format your report using the template below:

```markdown
### [BUG] Short summary of the issue

- **Module:** (e.g., Budgets Hub / Manage Limits)
- **Severity:** (Critical / Major / Minor / Cosmetic)
- **Device & OS:** (e.g., Samsung Galaxy S23, Android 14)
- **Test Case ID:** (e.g., TC-05.5)

**Steps to Reproduce:**
1. Navigate to 'Budgets' tab.
2. Tap on 'Manage Limits'.
3. Tap '+20%' chip.
4. Tap 'Save Limits'.

**Expected Result:**
Category limits scale up by 20% and save to Firestore.

**Actual Result:**
Describe what actually happened (e.g., app froze, incorrect amount, etc.).

**Screenshots / Screen Recording:**
Attach media file or link.
```
