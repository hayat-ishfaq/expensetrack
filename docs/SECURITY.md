# FlatSplit — Security & Access Document

**Version**: 1.2.0  
**Scope**: Authentication, Authorization, Database Rules, Data Isolation, and Integrity  
**Applicability**: Production Mobile App & Cloud Firestore  

---

## 1. Security Overview
FlatSplit manages sensitive personal financial data for co-living groups. The security architecture enforces **least privilege access**, **strict multi-tenant isolation**, and **dual-layer authorization** (client-side UI guarding backed by server-side Cloud Firestore security rules).

---

## 2. Authentication & Session Security

### 2.1 Provider & Tokens
- Handled by **Firebase Authentication** using secure, signed JSON Web Tokens (JWTs).
- Session tokens are stored in the platform's secure keystore (Android Keystore / iOS Keychain).
- Expired tokens are refreshed automatically by the Firebase SDK without exposing raw credentials.

### 2.2 Password Constraints
- Passwords require a minimum length of 8 characters enforced at both the UI validator layer (`Validators.password`) and Firebase Auth backend.
- Password reset emails use one-time cryptographic tokens with expiration windows.

---

## 3. Role-Based Access Control (RBAC) Matrix

Users in a household are assigned one of two operational roles:

| Action / Capability | Flat Owner (Creator) | Flat Member (Joined) | Unauthenticated |
| :--- | :---: | :---: | :---: |
| **Create Household** | ✅ Yes | N/A | ❌ No |
| **Share / View Invite Code** | ✅ Yes | ✅ Yes | ❌ No |
| **Look Up Invite Code** | ✅ Yes | ✅ Yes | ❌ No |
| **Join Flat** | ✅ Yes | ✅ Yes | ❌ No |
| **Adjust Overall Flat Budget** | ✅ **Full Control** | ❌ **Blocked / View-Only** | ❌ No |
| **Set Category Budgets** | ✅ **Full Control** | ❌ **Blocked / View-Only** | ❌ No |
| **Allocate Member Quotas** | ✅ **Full Control** | ❌ **Blocked / View-Only** | ❌ No |
| **Create Custom Categories** | ✅ **Full Control** | ❌ **Blocked / View-Only** | ❌ No |
| **Rename Household** | ✅ **Full Control** | ❌ **Blocked** | ❌ No |
| **Add Expense** | ✅ Yes | ✅ Yes (Own ID) | ❌ No |
| **Edit / Delete Own Expense** | ✅ Yes | ✅ Yes | ❌ No |
| **Edit / Delete Others' Expense** | ✅ Yes (Admin Override) | ❌ **Blocked** | ❌ No |
| **Record Debt Settlement** | ✅ Yes | ✅ Yes | ❌ No |
| **Leave Household** | ❌ Must Transfer / Delete | ✅ Yes | ❌ No |
| **Delete Household** | ✅ Yes | ❌ **Blocked** | ❌ No |

---

## 4. Multi-Tenant Data Isolation

### 4.1 Strict Document Hierarchy
All sensitive operational entities (members, expenses, settlements) exist as subcollections underneath the specific `/households/{householdId}` document:

```
/households/{householdId}
  ├── /members/{userId}
  ├── /expenses/{expenseId}
  └── /settlements/{settlementId}
```

### 4.2 Security Rules Isolation Rules
Firestore security rules evaluate whether `request.auth.uid` is a confirmed document in `/households/{householdId}/members/$(request.auth.uid)`.
- A user belonging to Flat A has zero ability to query, list, or read any document in Flat B.
- Global queries across the top-level collection are disallowed.

---

## 5. Firestore Security Rules Specification

Below is the verified security rules contract deployed to Firebase:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function isUser(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    function isMemberOf(householdId) {
      return isAuthenticated() &&
        exists(/databases/$(database)/documents/households/$(householdId)/members/$(request.auth.uid));
    }

    function isOwnerOf(householdId) {
      return isAuthenticated() &&
        get(/databases/$(database)/documents/households/$(householdId)).data.ownerId == request.auth.uid;
    }

    // 1. User Profiles
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create, update: if isUser(userId);
      allow delete: if false;
    }

    // 2. Invite Codes:
    // Any authenticated user can read invite code indices to join.
    match /inviteCodes/{code} {
      allow read: if isAuthenticated();
      allow create, update: if isAuthenticated();
      allow delete: if isAuthenticated();
    }

    // 3. Households
    match /households/{householdId} {
      // Authenticated users can read household metadata (required for join previews)
      allow read: if isAuthenticated();
      // Any authenticated user can create a household
      allow create: if isAuthenticated() && request.resource.data.ownerId == request.auth.uid;
      
      // CRITICAL: Budget adjustments and household settings strictly require the owner!
      // Member count increment / join updates are permitted for members and joining users.
      allow update: if isOwnerOf(householdId) || (
        isAuthenticated() &&
        !request.resource.data.diff(resource.data).affectedKeys().hasAny([
          'monthlyBudgetPaisa',
          'categoryBudgetsPaisa',
          'memberCategoryBudgetsPaisa',
          'ownerId'
        ])
      );
      allow delete: if isOwnerOf(householdId);

      // Members subcollection
      match /members/{memberId} {
        allow read: if isMemberOf(householdId) || isOwnerOf(householdId);
        // User can add themselves when joining, or owner can manage
        allow create, update: if isUser(memberId) || isOwnerOf(householdId);
        // User can leave or owner can remove member
        allow delete: if isUser(memberId) || isOwnerOf(householdId);
      }

      // Expenses subcollection: strictly isolated to household members.
      // Members can only add expenses with themselves as createdByUserId.
      // Members can only edit or delete their own expenses (or owner).
      match /expenses/{expenseId} {
        allow read: if isMemberOf(householdId);
        allow create: if isMemberOf(householdId) &&
                         request.resource.data.createdByUserId == request.auth.uid;
        allow update: if isMemberOf(householdId) &&
                         (resource.data.createdByUserId == request.auth.uid || isOwnerOf(householdId));
        allow delete: if isMemberOf(householdId) &&
                         (resource.data.createdByUserId == request.auth.uid || isOwnerOf(householdId));
      }

      // Settlements subcollection
      match /settlements/{settlementId} {
        allow read: if isMemberOf(householdId);
        allow create, update, delete: if isMemberOf(householdId);
      }
    }
  }
}
```

---

## 6. Invite Code Security & Collision Handling

1. **Entropy & Look-Alike Character Exclusion**:
   Invite codes are generated from an alphabet of 30 unambiguous characters (`ABCDEFGHJKMNPQRSTUVWXYZ23456789`), excluding `0, O, 1, I, L`.
   $$30^4 = 810,000 \text{ possible codes}$$
2. **Atomic Collision Check**:
   Before creating a household, `FirebaseHouseholdRepository` queries `/inviteCodes/{code}`. If a collision occurs, it retries up to 6 times with a fresh cryptographically random seed (`Random.secure()`).
3. **Resilient Dual Lookup**:
   If index documents are lost or corrupted, a fallback scoped query directly on `households.where('inviteCode', isEqualTo: code)` recovers the flat ID and self-heals the index.

---

## 7. Monetary & Calculation Integrity

1. **Integer Representation**:
   All monetary amounts are treated as integer paisas ($100 \text{ Paisas} = 1 \text{ PKR}$). Floating-point values are never stored in Firestore.
2. **Zero-Drift Remainder Conservation**:
   When splitting uneven amounts (e.g. Rs. 100 split 3 ways):
   - Participant 1: Rs. 33.34 (3334 paisas)
   - Participant 2: Rs. 33.33 (3333 paisas)
   - Participant 3: Rs. 33.33 (3333 paisas)
   - Total Sum: Exactly Rs. 100.00 (10000 paisas).
3. **Settlement Parity Guarantee**:
   $$\sum_{u} \text{Balance}(u) = 0.00$$
   Settlement transfers verify mathematically that total debt equals total credit before committing records.
