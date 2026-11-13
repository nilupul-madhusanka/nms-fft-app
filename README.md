# NMS Family Finance Tracker

A cross-platform Flutter app for managing daily income and expenses as a family. Every family member signs in with Google, and all transactions sync in real time via Cloud Firestore.

## Features

- **Google Sign-In** — secure, one-tap authentication for family members
- **Real-time sync** — transactions and categories update instantly across all devices via Firestore
- **Dashboard** — monthly summary cards (Income, Expense, Balance) with transactions grouped by date
- **Member filtering** — view family-wide data or filter by individual member
- **Add / Edit / Delete transactions** — income or expense, with category, amount, date, and optional note
- **Category management** — create custom income & expense categories with emoji icons; 13 sensible defaults seeded on first use
- **Reports & Charts**
  - Weekly and monthly views
  - Daily trend bar chart (income vs. expense)
  - Category breakdown pie chart with legend
  - Member breakdown with progress bars
- **Swipe-to-delete** transactions with confirmation dialog
- **Material 3** themed UI with a purple brand palette

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.47+ (Dart 3.13+) |
| Auth | Firebase Auth + Google Sign-In |
| Database | Cloud Firestore |
| State Management | Provider (`ChangeNotifier`) |
| Charts | fl_chart |
| Date Formatting | intl |
| ID Generation | uuid |

## Project Structure

```
lib/
├── main.dart                    # App entry point & AuthGate
├── models/
│   ├── category_model.dart      # CategoryModel (id, name, icon, type)
│   └── transaction_model.dart   # TransactionModel & TransactionType enum
├── providers/
│   └── app_provider.dart        # Central state: auth, data, filters, computed values
├── screens/
│   ├── add_transaction_screen.dart  # Add / edit transaction form
│   ├── categories_screen.dart       # Category list & add dialog
│   ├── home_screen.dart             # Dashboard with bottom nav (Home, Reports, Categories)
│   ├── login_screen.dart            # Google Sign-In screen
│   └── reports_screen.dart          # Weekly & monthly charts and breakdowns
├── services/
│   ├── auth_service.dart        # Google OAuth + Firebase Auth wrapper
│   └── firestore_service.dart   # Firestore CRUD for transactions, categories, members
├── utils/
│   ├── app_theme.dart           # Material 3 theme, brand colors, emoji icon list
│   └── helpers.dart             # Date utilities & currency formatter (Rs.)
└── widgets/
    ├── summary_card.dart        # Compact income/expense/balance card
    └── transaction_card.dart    # Dismissible, tappable transaction row
```

## Firestore Collections

| Collection | Purpose |
|---|---|
| `family_transactions` | All income & expense records (queried by date range) |
| `categories` | Shared income & expense categories |
| `members` | Family member profiles (synced on each login) |

## Getting Started

### Prerequisites

- Flutter 3.47 or later with Dart 3.13 or later
- A Firebase project with **Authentication** (Google provider) and **Cloud Firestore** enabled

### Setup

1. **Clone the repo**
   ```bash
   git clone https://github.com/nilupul-madhusanka/nms-fft-app.git
   cd nms-fft-app
   ```

2. **Firebase configuration**
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Enable **Google Sign-In** under Authentication → Sign-in method
   - Create a **Cloud Firestore** database
   - Add an Android app with package name `com.example.nms_fft_app`
   - Download `google-services.json` → place in `android/app/`
   - *(iOS)* Add an iOS app, download `GoogleService-Info.plist` → place in `ios/Runner/`

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Run**
   ```bash
   flutter run
   ```

### Android Notes

- Android requires **API 24** or later for the current Firebase SDK.
- For Google Sign-In, register the signing certificate's SHA-1 in Firebase Project settings. After the first Android build, run `./gradlew signingReport` from `android/` (`.\gradlew.bat signingReport` on Windows) to find the debug variant's SHA-1. Download a fresh `google-services.json` after registering it, then rebuild.

## Currency

The app uses **Rs.** (Sri Lankan Rupee) as the display currency. To change it, update the `currencyFormat` in `lib/utils/helpers.dart`.

## License

This project is for private family use.
