[![Open in Codespaces](https://classroom.github.com/assets/launch-codespace-2972f46106e565e64193e422d61a12cf1da4916b45550586e14ef0a7c637dd04.svg)](https://classroom.github.com/open-in-codespaces?assignment_repo_id=23237678)


# QuickFix
### Find. Book. Fix.

A two-sided mobile marketplace connecting homeowners and tenants in Kigali,
Rwanda with verified, rated home service artisans — built with Flutter, Dart,
and a live Supabase PostgreSQL backend.

---

## The Problem We Solve

Homeowners and tenants in Kigali cannot reliably find, verify, or pay
qualified home service artisans. Artisans have no digital platform to
showcase their skills, manage bookings, or receive secure payment.
The result is a trust-less system built entirely on word of mouth —
causing financial losses, long delays, and poor service quality on
both sides of the market.

**Evidence from field research (Gasabo & Kimironko, March 27, 2026):**
- A landlord made 4 phone calls before finding anyone to fix a burst pipe
- The same landlord lost 15,000 RWF to an artisan who never returned
- An electrician waits at a hardware shop daily with no guaranteed income
- Price for the same job varied between 10,000 RWF and 25,000 RWF

---

## Team Members

| Name | Registration Number | Primary Contributions |
|---|---|---|
| Adrien MIZERO | 223019090 | Flutter UI, Navigation, Forms, Supabase Integration |
| Bernardine UWITUZE | 223014064 | Data Models, OOP, Dart Fundamentals |

---

## App Features

### For Homeowners
- Browse verified, rated artisans by category with real-time search
- Filter artisans by district, minimum rating, maximum price, and availability
- View full artisan profiles with skills, reviews, and pricing
- Post a job request with budget, description, and photo
- **AI job description helper** — tap ✨ Write with AI to turn rough notes into a clear, professional description (powered by Groq)
- Book an artisan directly or accept a bid from the bids panel
- Track job status through a 6-step visual stepper in real time
- Save favourite artisans and manage them from a dedicated screen
- Receive push-style in-app notifications for new bids and booking updates
- Mark a job complete and rate the artisan via the built-in review flow
- **QuickFix Assistant** — floating chatbot button for Q&A, cost estimates in RWF, and category recommendations with a one-tap "Post a Job" shortcut

### For Artisans
- Set up a verified professional profile after signup
- Browse available job requests filtered by category
- Send bids with custom price and message; receive acceptance notifications
- Advance job status (On the Way, In Progress) from the dashboard
- Edit profile, manage invitations, and track earnings
- Receive in-app notifications when a homeowner accepts or declines a bid
- **QuickFix Assistant** — floating chatbot button for app help and pricing guidance

---

## Tech Stack

| Technology | Purpose |
|---|---|
| Flutter 3.x | Cross-platform mobile UI framework |
| Dart 3.x | Programming language |
| Supabase | Backend-as-a-Service (auth, PostgreSQL database, storage) |
| supabase_flutter ^2.9.0 | Supabase client SDK for Flutter |
| PostgreSQL | Relational database hosted on Supabase |
| Groq API (llama-3.3-70b-versatile) | AI: job description generation + chatbot |
| http ^1.2.0 | HTTP client for Groq API calls |
| Material Design 3 | UI component system and theming |
| flutter_localizations | Internationalisation (English, French, Kinyarwanda) |
| image_picker ^1.1.2 | Profile photo upload |
| Flutter Navigator 2 | Named route navigation |
| Stateful Widgets | Local state management |

---

## Database Schema

See [`docs/database_schema.md`](docs/database_schema.md) for full table definitions,
column types, constraints, and relationship diagram.

**Tables at a glance:**

| Table | Purpose |
|---|---|
| `artisans` | Artisan profiles, skills, rating, completed_jobs |
| `homeowners` | Homeowner profiles and contact info |
| `jobs` | Job postings from homeowners |
| `bids` | Artisan bids on jobs |
| `bookings` | Direct booking records (instant book flow) |
| `reviews` | Homeowner reviews of artisans (1–5 stars) |
| `notifications` | In-app notification inbox for both user types |
| `favorites` | Homeowner ↔ artisan saved relationships |
| `invitations` | Direct job invitations from homeowners to artisans |

---

## Project Structure

```
lib/
├── config/
│   ├── supabase_config.dart         # Supabase URL + anon key (git-ignored)
│   ├── supabase_config.example.dart # Template for new contributors
│   ├── groq_config.dart             # Groq API key (git-ignored)
│   └── groq_config.example.dart    # Template — copy and fill in your key
├── l10n/
│   └── app_localizations.dart       # EN / FR / RW string translations
├── models/
│   ├── artisan.dart        # Artisan, VerifiedArtisan, ServiceProvider, Rateable
│   ├── bid.dart            # Bid, BidStatus
│   ├── app_notification.dart # AppNotification
│   ├── homeowner.dart      # Homeowner, UserSession, UserType
│   ├── job.dart            # Job, JobStatus, ServiceCategory
│   └── review.dart         # Review
├── screens/
│   ├── splash_screen.dart              # Animated splash + session restore
│   ├── login_screen.dart               # Email/password login + forgot password
│   ├── signup_screen.dart              # Signup with role selection
│   ├── password_recovery_screen.dart   # Deep-link password reset
│   ├── artisan_setup_screen.dart       # Artisan profile setup after signup
│   ├── home_screen.dart                # Homeowner home / Artisan dashboard
│   ├── artisan_detail_screen.dart      # Artisan profile detail + reviews
│   ├── booking_form_screen.dart        # Direct booking form
│   ├── job_post_screen.dart            # Homeowner job posting form (+ AI helper)
│   ├── assistant_screen.dart           # QuickFix AI chatbot (multi-turn, Groq)
│   ├── job_list_screen.dart            # Artisan available jobs list
│   ├── job_status_screen.dart          # 6-step visual job status tracker
│   ├── bids_management_screen.dart     # Homeowner bids review panel
│   ├── invitations_screen.dart         # Artisan received invitations
│   ├── notifications_screen.dart       # In-app notification inbox
│   ├── favorites_screen.dart           # Homeowner saved artisans
│   ├── artisan_edit_profile_screen.dart
│   └── homeowner_edit_profile_screen.dart
├── services/
│   ├── supabase_service.dart  # All Supabase DB + auth calls
│   └── groq_service.dart      # Groq AI: job description helper + chatbot
├── theme/
│   └── app_theme.dart         # Material Design 3 theme and colours
├── widgets/
│   ├── artisan_card.dart       # Reusable artisan card (favorite toggle)
│   ├── category_chip.dart      # Reusable category filter chip
│   ├── language_selector.dart  # EN / FR / RW language switcher
│   ├── rating_dialog.dart      # Star rating + comment dialog
│   ├── review_card.dart        # Reusable review card widget
│   └── review_sheet.dart       # Post-completion artisan rating sheet
└── main.dart                   # App entry point, routes, deep-link listener
```

---

## How to Run

### Prerequisites
- Flutter SDK 3.x (stable channel)
- Android SDK (API 21+) or iOS Simulator
- VS Code with Flutter and Dart extensions
- A Supabase project (free tier is sufficient)

### Steps

**1. Clone the repository**
```bash
git clone https://github.com/Pelino-Courses/progressive-capstone-project-triad.git
cd progressive-capstone-project-triad
```

**2. Configure Supabase credentials**

Copy the example config and fill in your project values:
```bash
cp lib/config/supabase_config.example.dart lib/config/supabase_config.dart
```

Then edit `lib/config/supabase_config.dart`:
```dart
class SupabaseConfig {
  static const String url = 'https://YOUR_PROJECT_ID.supabase.co';
  static const String anonKey = 'YOUR_ANON_KEY';
}
```

Find these values in your Supabase Dashboard under **Project Settings → API**.

**3. Configure Groq API key** (required for AI features)

```bash
cp lib/config/groq_config.example.dart lib/config/groq_config.dart
```

Then edit `lib/config/groq_config.dart`:
```dart
class GroqConfig {
  static const String apiKey = 'YOUR_GROQ_API_KEY';
  static const String model = 'llama-3.3-70b-versatile';
}
```

Get a free key at [console.groq.com](https://console.groq.com) → API Keys.
Both config files are git-ignored — your keys will never be committed.

**4. Apply database migrations**

Run the SQL from [`docs/database_schema.md`](docs/database_schema.md) in the
Supabase Dashboard SQL editor to create all tables, indexes, and triggers.

**5. Configure authentication redirect URLs** (for password recovery on Android)

In Supabase Dashboard → Authentication → URL Configuration → Redirect URLs, add:
```
com.quickfix.quickfix://login-callback
```

**6. Install dependencies**
```bash
flutter pub get
```

**7. Run the app**
```bash
flutter run
```

**8. Verify your Flutter environment**
```bash
flutter doctor
```

### Test Accounts

Sign up through the app to create real accounts stored in Supabase Auth:

| Role | How to access |
|---|---|
| Homeowner | Sign up → select Homeowner → fill name, phone, district |
| Artisan | Sign up → select Artisan → complete profile setup (trade, skills, experience) |

---

## Flutter Doctor Output

```
Doctor summary (to see all details, run flutter doctor -v):
[√] Flutter (Channel stable, 3.x)
[√] Windows Version (Windows 11 Home)
[√] Android toolchain - develop for Android devices
[√] Chrome - develop for the web
[√] Visual Studio - develop Windows apps
[√] Connected device (3 available)
[√] Network resources

No issues found!
```

---

## Mini-Capstone Snapshot — Parts A–E

### Part A — Dart Fundamentals
- Explicit typed variables, `final`, `const` throughout all model and screen files
- Null safety operators (`?`, `!`, `??`) in `UserSession`, `Homeowner`, service calls
- `List`, `Map`, and `Set` used in models, artisan setup, and favorites tracking
- Control flow with `if/else`, `switch`, and ternary operators across models and screens
- `Future` and `async/await` for all Supabase DB and auth operations

### Part B — OOP & Data Models
- 5 model classes: `Artisan`, `VerifiedArtisan`, `Homeowner`, `Job`, `Bid`, `Review`, `AppNotification`
- Inheritance: `VerifiedArtisan extends Artisan`, `Homeowner implements ServiceProvider`
- Abstract class: `ServiceProvider` implemented by both `Artisan` and `Homeowner`
- Mixin: `Rateable` mixed into `Artisan` for shared rating behaviour
- Enums: `JobStatus`, `ServiceCategory`, `BidStatus`, `UserType`

### Part C — Flutter UI & Widgets
- Home screen displays live Supabase data in a 2-column `GridView`
- Layout widgets: `GridView`, `ListView`, `Column`, `Row`, `Stack`, `SliverAppBar`
- 5 custom reusable widgets: `ArtisanCard`, `CategoryChip`, `ReviewCard`, `RatingDialog`, `LanguageSelector`
- Material Design 3 theme applied via `AppTheme` with full `ColorScheme`
- Animated stepper in `JobStatusScreen` using `AnimationController` + `Tween`

### Part D — Navigation & Forms
- 16+ named routes connected via `MaterialApp` routes map (including `/assistant`)
- Data passed between screens via route arguments (e.g. category pre-fill from assistant → job post)
- Validated forms: Login, Signup, Booking, Job Post, Artisan Setup, Password Recovery
- Deep-link navigation for password recovery on Android (`com.quickfix.quickfix://login-callback`)

### Part E — Backend Integration (Supabase)
- Real authentication (email/password) with Supabase Auth; session persisted across app restarts
- Full CRUD operations on all 9 database tables via `supabase_flutter`
- PostgreSQL triggers for automatic rating recalculation and completed-jobs counting
- Row-level security (RLS) policies on all tables
- In-app notification system with unread badge count
- Image upload via Supabase Storage + `image_picker`
- Internationalisation in English, French, and Kinyarwanda

### AI Integration (Groq API)
- `GroqService.improveJobDescription()` — converts homeowner rough notes into a professional job description using `llama-3.3-70b-versatile`; accessible via ✨ Write with AI in the job post form
- `GroqService.assistantChat()` — multi-turn conversation with a system prompt embedding QuickFix context: app usage, service categories, and typical Kigali price ranges in RWF
- `AssistantScreen` — full chat UI with animated thinking indicator, suggestion chips, and conversation history
- Category detection: AI appends `CATEGORY: [X]` when recognising a home problem; the app strips it from the bubble text and renders a gradient "Post a [Category] Job" button that navigates to `/post-job` with the category pre-selected
- Available as a floating button on both homeowner (above Post a Job) and artisan home screens
- Responds in the same language the user writes in (English, French, or Kinyarwanda)

---

## Documentation

| File | Contents |
|---|---|
| [`docs/database_schema.md`](docs/database_schema.md) | All tables, columns, types, constraints, and relationships |
| [`docs/user_flows.md`](docs/user_flows.md) | Complete end-to-end user flows for both roles |

---

## Repository

- **GitHub:** https://github.com/Pelino-Courses/progressive-capstone-project-triad
- **Submission Tag:** `mini-capstone-final`

---

*University of Rwanda — BSc Information Technology*
*Mobile Application Development with Flutter & Dart*
*Progressive Capstone Project | 2026*
