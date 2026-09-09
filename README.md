# CRM Companion Mobile App (Flutter)

A production-grade, cross-platform (iOS & Android) Flutter mobile application designed as the mobile companion to the Next.js CRM web application. Both applications share a single Supabase backend and Firebase Cloud Messaging (FCM).

---

## Architecture & Tech Stack

- **Flutter 3.x / Dart 3.x**
- **State Management:** Riverpod 2.x
- **Routing:** GoRouter with declarative route tree & auth guards
- **Backend:** Supabase (Auth, PostgreSQL, Realtime Subscriptions, Storage)
- **Push Notifications:** Firebase Cloud Messaging (`firebase_messaging` + `flutter_local_notifications`)
- **Design System:** Material 3 with Dynamic Light/Dark Theme Switcher

---

## Project Structure

```
lib/
├── app.dart                        # Root MaterialApp with theme & router
├── main.dart                       # Entry point & bootstrap
├── core/
│   ├── config/                     # Environment (.env) & Supabase configuration
│   ├── errors/                     # AppFailure model & error handlers
│   ├── router/                     # GoRouter routes & bottom navigation shell
│   ├── theme/                      # AppColors, ThemeData (Light/Dark), ThemeNotifier
│   └── utils/                      # Formatters (currency, dates) & form validators
├── data/
│   ├── models/                     # ContactModel, DealModel, TaskModel, ProfileModel, DeviceToken
│   ├── repositories/               # Supabase CRUD + Realtime Stream Repositories
│   └── services/                   # SupabaseService & NotificationService (FCM)
├── features/
│   ├── auth/                       # Login & Registration views with auth state controller
│   ├── dashboard/                  # KPI summary metrics, recent contacts, upcoming tasks
│   ├── contacts/                   # Contact list, search/filter, detail view, add/edit form
│   ├── deals/                      # Pipeline stages, value tracking, deal management
│   ├── tasks/                      # To-dos, follow-ups, date pickers, completion toggle
│   ├── notifications/              # Push notification status & center
│   └── settings/                   # User profile, theme mode toggle, backend connection
└── shared/
    ├── extensions/                 # BuildContext & String convenience extensions
    └── widgets/                    # Custom AppButton, AppTextField, EmptyState, ErrorView
```

---

## Quick Start Guide

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (>= 3.10.0)
- Xcode (for iOS development) & Android Studio (for Android)
- Supabase Project & Firebase Project

### 2. Environment Setup
Copy `.env.example` to `.env` and fill in your Supabase credentials:

```bash
cp .env.example .env
```

Edit `.env`:
```env
SUPABASE_URL=https://your-supabase-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
APP_ENV=development
```

### 3. Supabase Database Setup
Run the SQL queries in `supabase_schema.sql` inside your Supabase project's SQL editor to generate the required tables, Row Level Security (RLS) policies, and Realtime replication slots.

### 4. Push Notification (FCM) Setup

#### Android:
- Add your real `google-services.json` to `android/app/google-services.json`.

#### iOS:
- Add your real `GoogleService-Info.plist` to `ios/Runner/GoogleService-Info.plist` in Xcode.
- Enable **Push Notifications** and **Background Modes (Remote notifications, Background fetch)** in Apple Developer portal and Xcode Signing & Capabilities.
- Upload your APNs Auth Key (`.p8`) to Firebase Console under **Project Settings > Cloud Messaging > Apple app configuration**.

### 5. Run the Application

```bash
# Install dependencies
flutter pub get

# Run on connected iOS simulator or Android emulator
flutter run
```

---

## License
Proprietary — CRM Companion App.
