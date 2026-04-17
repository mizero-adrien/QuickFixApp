[![Open in Codespaces](https://classroom.github.com/assets/launch-codespace-2972f46106e565e64193e422d61a12cf1da4916b45550586e14ef0a7c637dd04.svg)](https://classroom.github.com/open-in-codespaces?assignment_repo_id=23237678)


# QuickFix 🔧
### Find. Book. Fix.

A two-sided mobile marketplace connecting homeowners and tenants in Kigali,
Rwanda with verified, rated home service artisans — built with Flutter & Dart.

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
| [Adrien MIZERO] | [223019090] | Flutter UI, Navigation, Forms |
| [Bernardine UWITUZE] | [Partner Reg Number] | Data Models, OOP, Dart Fundamentals |

---

## App Features

### For Homeowners
- Browse verified, rated artisans by category
- View full artisan profiles with skills, reviews, and pricing
- Post a job request with budget and description
- Book an artisan directly from their profile
- Track job status in real time

### For Artisans
- Set up a professional profile after signup
- Browse available job requests from homeowners
- Send bids with custom price and note
- Build reputation through ratings and reviews

---

## Tech Stack

| Technology | Purpose |
|---|---|
| Flutter 3.38.9 | Cross-platform mobile UI framework |
| Dart | Programming language |
| Material Design 3 | UI component system and theming |
| Flutter Navigator | Multi-screen named route navigation |
| Stateful Widgets | Local state management |

---

## Project Structure
lib/
├── models/
│   ├── artisan.dart        # Artisan, VerifiedArtisan, ServiceProvider, Rateable
│   ├── homeowner.dart      # Homeowner, UserSession, UserType
│   ├── job.dart            # Job, JobStatus, ServiceCategory
│   └── review.dart         # Review
├── screens/
│   ├── splash_screen.dart          # Animated splash screen
│   ├── login_screen.dart           # Login with email/password
│   ├── signup_screen.dart          # Signup with role selection
│   ├── artisan_setup_screen.dart   # Artisan profile setup
│   ├── home_screen.dart            # Homeowner home / Artisan dashboard
│   ├── artisan_detail_screen.dart  # Artisan profile detail
│   ├── booking_form_screen.dart    # Job booking form
│   ├── job_post_screen.dart        # Homeowner job posting form
│   └── job_list_screen.dart        # Artisan job listings
├── widgets/
│   ├── artisan_card.dart    # Reusable artisan card widget
│   ├── category_chip.dart   # Reusable category filter chip
│   └── review_card.dart     # Reusable review card widget
├── data/
│   └── dummy_data.dart      # Sample artisans, jobs, reviews
├── theme/
│   └── app_theme.dart       # Material Design 3 theme and colours
└── main.dart                # App entry point and named routes

---

## How to Run

### Prerequisites
- Flutter SDK 3.38.9 or higher
- Android SDK or iOS Simulator
- VS Code with Flutter and Dart extensions

### Steps

**1. Clone the repository**
```bash
git clone [https://github.com/Pelino-Courses/progressive-capstone-project-triad.git]
cd progressive-capstone-project-triad
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Run the app**
```bash
flutter run
```

**4. Verify environment**
```bash
flutter doctor
```

### Test Accounts

Since this version uses dummy data, use any credentials to log in:

| Role | How to access |
|---|---|
| Homeowner | Sign up → select Homeowner → fill form |
| Artisan | Sign up → select Artisan → complete profile setup |

---

## Flutter Doctor Output
Doctor summary (to see all details, run flutter doctor -v):
[√] Flutter (Channel stable, 3.38.9)
[√] Windows Version (Windows 11 Home)
[√] Android toolchain - develop for Android devices
[√] Chrome - develop for the web
[√] Visual Studio - develop Windows apps
[√] Connected device (3 available)
[√] Network resources

No issues found!

---

## Mini-Capstone Snapshot — Parts A–D

This submission adds the following to the progressive project:

### Part A — Dart Fundamentals
- Explicit typed variables, `final`, `const` throughout all model and screen files
- Null safety operators (`?`, `!`, `??`) used in `UserSession`, `Homeowner`, and screen arguments
- `List`, `Map`, and `Set` used in `dummy_data.dart`, `artisan_setup_screen.dart`, and `job_list_screen.dart`
- Control flow with `if/else`, `switch`, and ternary operators across models and screens

### Part B — OOP & Data Models
- 4 model classes: `Artisan`, `VerifiedArtisan`, `Homeowner`, `Job`, `Review`
- Inheritance: `VerifiedArtisan extends Artisan`
- Abstract class: `ServiceProvider` implemented by both `Artisan` and `Homeowner`
- Mixin: `Rateable` mixed into `Artisan` for shared rating behaviour
- `Future` and `async/await` used in `fetchArtisans()`, `fetchReviewsForArtisan()`, and all form submissions

### Part C — Flutter UI & Widgets
- Home screen displays real dummy data in a 2-column `GridView`
- Layout widgets used: `GridView`, `ListView`, `Column`, `Row`, `Stack`
- 3 custom reusable widgets: `ArtisanCard`, `CategoryChip`, `ReviewCard`
- Material Design 3 theme applied via `AppTheme` with full `ColorScheme`

### Part D — Navigation & Forms
- 7 named routes connected via `MaterialApp` routes map
- Data passed between screens: artisan object from Home → Detail → Booking Form
- 3 validated forms: Login, Signup, Booking Form, Job Post, Artisan Setup
- Form validation includes email regex, phone pattern, length checks, password match

---

## Design Mockups

Stitch mockups are in the `/design/` folder:

| File | Screen |
|---|---|
| `01_home_screen.png` | Homeowner home with artisan grid |
| `02_detail_screen.png` | Artisan profile detail |
| `03_form_screen.png` | Job booking request form |

See `DESIGN.md` for the full design system including colour palette,
typography, and component style rationale.

---

## Repository

- **GitHub:** [https://github.com/Pelino-Courses/progressive-capstone-project-triad.git]
- **Submission Tag:** `mini-capstone-part-a-d`

---

*University of Rwanda — BSc Information Technology*
*Mobile Application Development with Flutter & Dart*
*Mini-Capstone Parts A–D | 2026*