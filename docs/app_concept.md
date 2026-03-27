# App Concept Document 
App Name: QuickFix
**Task:** 2 — App Concept Development (35% weight)
**Team:** 2 Members
**Date:** March 27, 2026

---

## Cover Summary

 **App Name** QuickFix 
 **Tagline** Find. Book. Fix. 
 **Platform** Android & iOS — built with Flutter / Dart 
 **Target Market** | Kigali, Rwanda (Gasabo, Kicukiro, Nyarugenge districts) 
 **Assessment Weight**  35% 
 **MVP Features**  5 
 **Constraints Addressed**  4 
 **Document Date**  March 27, 2026 

---

## 1. App Overview

**QuickFix:  is a two-sided mobile marketplace that connects homeowners and tenants in Kigali with verified, rated home service artisans — plumbers, electricians, painters, carpenters, and cleaners. Users can search, book, pay securely via Mobile Money, and track jobs in real time. Artisans gain a digital presence, steady bookings, and reliable payment — all through a Flutter app built for Rwanda's real-world constraints.


## 2. Problem Statement

> **Homeowners and tenants in Kigali cannot reliably find, verify, or pay qualified home service artisans. Artisans have no digital platform to showcase their skills, manage bookings, or receive secure payment. The result is a trust-less system built entirely on word of mouth  causing financial losses, long delays, and consistently poor service quality on both sides of the market.**

### Evidence from Field Research

Our two-member team conducted independent field research on March 27, 2026 in Gasabo and Kimironko . The problem surfaced immediately and consistently across both sessions:

- A landlord in Gasabo made **4 phone calls** before finding anyone to fix a burst pipe — on day 2 of the emergency
- The same landlord **lost 15,000 RWF** to an artisan who took cash upfront and never returned
- An electrician in Kimironko **waits at a hardware shop daily** with no guaranteed income: *"Some days I go home with nothing"*
- Price for the same job varied between **10,000 RWF and 25,000 RWF** depending on who you asked
- No interviewee had ever used a digital tool to find or offer home services

---

## 3. Target Users

### User Type 1 — Homeowner / Tenant (Service Seeker)

 **Age** : 22–55 
 **Location**  Kigali — Gasabo, Kicukiro, Nyarugenge 
**Tech literacy**  Moderate — uses WhatsApp, MoMo, basic Android apps 
**Core pain**  Cannot find qualified artisans quickly or safely 
**Financial risk** | Loses money paying cash upfront with no guarantee 
**Goal** | Book a trusted professional fast, pay securely, get the job done 

### User Type 2 — Artisan (Service Provider)

 **Age**  20–50 
**Skills**  Plumbing, electrical, painting, carpentry, cleaning, masonry 
**Tech literacy**  Basic — has a smartphone but no digital presence 
**Core pain** Inconsistent work, no platform, payment disputes common 
**Income problem**  Works only when someone physically finds them  
**Goal**  Receive steady bookings, build a reputation, get paid reliably |

---

## 4. Core Value Proposition


| **Homeowners** | Find a verified, rated artisan near you in minutes — not days |
| **Artisans** | Build a digital profile, receive job requests, get paid securely through MoMo |
| **Both** | A trust layer that does not exist anywhere in Rwanda today |

---

## 5. Key Use Cases

1. Find a plumber urgently | Homeowner | Pipe burst — search "plumber", see nearby available artisans, book instantly |
2. Browse and compare artisans | Homeowner | Read profiles, check ratings, compare quotes before deciding |
3. Post a job request | Homeowner | Describe job, upload photo, receive quotes from multiple artisans |
4. Build a professional profile | Artisan | Upload skills, photo, service area, set availability status |
5. Accept a booking | Artisan | Receive push notification, send quote, confirm booking |
6. Receive MoMo payment | Artisan | Job marked complete by homeowner, MoMo payment released automatically |

---

## 6. MVP Features — Problem-Solution Fit

Each feature traces directly to a friction point discovered in field research.

---

### Feature 1 — Artisan Profile

**Friction solved:** No way to verify who you are hiring. No qualifications, no photo, no track record. Artisans are hired on pure word of mouth with zero accountability.

**Why it works:** Each artisan has a structured, verified profile showing their name, photo, skills, years of experience, star rating, and number of completed jobs. This replaces guesswork with trustworthy information visible before any commitment is made. Our interviewee described wanting something like TripAdvisor — this delivers exactly that for artisans.

**Flutter implementation:**
- `ProfileScreen` widget
- `CircleAvatar` for photo display
- `RatingBarIndicator` for star ratings
- `Chip` widgets for skill tags
- `ListView` for review scrolling

---

### Feature 2 — Job Request & Quoting

**Friction solved:** Verbal price negotiation causes constant disputes. There is no way to compare multiple artisans before committing to one.

**Why it works:** The homeowner posts a job with a category, description, and optional photo. Nearby artisans receive a notification and each sends a price quote. The homeowner reviews all quotes and selects the best offer — full pricing transparency before any money changes hands.

**Flutter implementation:**
- `JobPostForm` with `TextField`, `DropdownButton`, `ImagePicker`
- `QuoteCard` widget for each artisan response
- `ListView` of received quotes sorted by price

---

### Feature 3 — MoMo Escrow Payment

**Friction solved:** Homeowners lose cash upfront (15,000 RWF lost in our field research). Artisans chase clients for weeks to receive payment after completing a job.

**Why it works:** The homeowner pays via MTN Mobile Money when confirming a booking. The money is held in escrow and released to the artisan only after the homeowner marks the job as complete. Both sides are protected simultaneously — the homeowner cannot lose money, and the artisan is guaranteed payment on completion.

**Flutter implementation:**
- `PaymentScreen` with MTN MoMo API integration
- `ElevatedButton` triggers payment flow
- Escrow state managed with `Provider`
- Job completion trigger releases payment

---

### Feature 4 — Job Status Tracking

**Friction solved:** Artisans disappear after initial contact. No accountability once a booking is confirmed. No way to know if they are actually coming.

**Why it works:** Both the homeowner and artisan see a shared, live job status board that updates in real time across six stages: Requested → Quoted → Booked → On the Way → In Progress → Completed. Neither party can disappear. Our research interviewee said: *"If I can see on a map that he is coming, I know he is coming."*

**Flutter implementation:**
- `Stepper` widget or custom `Row` of `Icon` and `Text` nodes
- Real-time updates via Firebase Firestore listeners
- Push notification sent on each status change

---

### Feature 5 — Ratings & Reviews

**Friction solved:** Zero quality signal exists for artisans in Rwanda. The only quality filter is a neighbour saying "I think he is okay" — completely unreliable.

**Why it works:** After job completion, the homeowner rates the artisan 1–5 stars and writes a short review. The artisan's average rating appears prominently on their profile. Good artisans grow their client base organically. Poor artisans lose bookings naturally over time without manual enforcement.

**Flutter implementation:**
- `RatingDialog` with `GestureDetector` star tap
- `TextField` for written review text
- Rating stored in Firestore and averaged on profile load
- Reviews displayed sorted by most recent

---

## 7. Problem–Solution Fit Analysis

| Friction Point (from field research) | QuickFix Feature that solves it |
|--------------------------------------|--------------------------------|
| Cannot find qualified artisans quickly | Artisan profiles + search by location and skill |
| No way to verify artisan quality | Verified profiles + ratings and reviews system |
| Cash lost paying upfront | MoMo escrow — released only on job completion |
| Long wait times even in emergencies | Real-time availability display + instant booking |
| Artisans have no digital presence | Artisan profile + push notifications for job requests |
| Pricing disputes before work starts | Quote system — transparent pricing before booking |
| Artisans not paid reliably | MoMo escrow releases automatically on completion |
| No advance booking system exists | Job request flow with confirmed booking state |

---

## 8. Constraint Integration Plan

The following four constraints were identified from field research and the progressive project guide. Each is addressed directly in the QuickFix app design.

---

### Constraint 1 — Mobile Money (MoMo) as Primary Payment Rail

**Challenge:** Most Kigali users do not use credit or debit cards. Cash transactions are risky, untrackable, and the root cause of financial loss for both sides of the market.

**Solution:** QuickFix integrates MTN Mobile Money and Airtel Money as the only payment methods in the app. No card option is needed for the MVP. All transactions become digital, fully traceable, and tied to a specific job — directly solving the payment accountability gap identified in both field interviews.

---

### Constraint 2 — Low Smartphone Literacy Among Artisans

**Challenge:** Field research confirmed artisans have smartphones but limited experience with complex interfaces. Onboarding must be extremely simple or artisans will abandon the app.

**Solution:** The artisan-facing UI uses large touch targets (minimum 48×48dp per Flutter Material Design guidelines), icon-first navigation, minimal text labels, and a simple 3-step onboarding flow: photo → skills → location. The artisan dashboard has one dominant action: respond to incoming job requests. A Kinyarwanda language toggle is planned for Phase 2.

---

### Constraint 3 — Inconsistent Internet Connectivity

**Challenge:** Parts of Kigali operate on weak 3G signals. Heavy data usage causes app failures and user drop-off — especially for artisans working across peri-urban areas of the city.

**Solution:** Profile images are compressed to under 100KB on upload. Job listings and artisan profiles are cached locally using `shared_preferences`. The app displays cached data with a "last updated" timestamp when offline. Critical actions such as booking and payment fail gracefully with clear retry prompts rather than silent errors.

---

### Constraint 4 — Trust as the Core Barrier

**Challenge:** Both interviewees cited trust — not price or availability — as the primary reason the current system fails. Users will not pay digitally or book in advance without believing the artisan is reliable.

**Solution:** Trust is embedded in every layer of QuickFix. Verified artisan profiles establish credibility before any contact. MoMo escrow means neither party is financially exposed. The star rating system creates accountability after every completed job. Job tracking gives real-time visibility so artisans cannot disappear. Trust is not an optional feature — it is the product itself.

---

## 9. Innovation vs. Existing Methods

| Method | Current Limitation | QuickFix Advantage |
|--------|-------------------|--------------------|
| Word of mouth | Slow, unreliable, no quality signal, no accountability | Instant search with verified profiles and star ratings |
| Waiting at hardware shops | No advance booking, artisan may not be available that day | Digital availability status and confirmed advance booking |
| WhatsApp groups | No vetting, no payment system, no tracking, no reviews | Full end-to-end managed process with escrow |
| Jumia / existing apps | Do not cover home services in Rwanda at all | Built specifically for this underserved local market |
| Cash transactions | Untrackable — artisans ghost after upfront payment | MoMo escrow released only on verified job completion |

QuickFix is the first home services marketplace built specifically for Rwanda's constraints — MoMo payment, low-data environments, and a market where trust is the primary barrier to commerce.

---

## 10. Technical Feasibility & Stack

All technologies below are within the Flutter/Dart skill scope of this course. Firebase provides a fully managed backend requiring no server-side code. Provider is the recommended state management approach for beginner-to-intermediate Flutter projects.

| Layer | Technology | Justification |
|-------|-----------|---------------|
| **Frontend** | Flutter (Dart) | Course requirement — all screens use Material Design 3 widgets |
| **Backend & Auth** | Firebase Auth + Cloud Firestore | Managed backend, real-time database, no server code needed |
| **File Storage** | Firebase Storage | Artisan profile photos and job description images |
| **Payments** | MTN MoMo API + Airtel Money API | Dominant payment rails in Rwanda — simulated for MVP demo |
| **State Management** | Provider package | Lightweight, appropriate for course skill level |
| **Maps & Location** | Google Maps Flutter + Geolocator | Proximity search and live artisan location tracking |
| **Image Handling** | image_picker + cached_network_image | Standard Flutter community packages |
| **Offline Support** | shared_preferences | Local caching for low-connectivity environments |

---

## 11. User Flow Diagrams

### Homeowner Flow

```
Open app
  └── Sign up / Login
        └── Select role: Homeowner
              └── Browse home screen
                    ├── Search by service category
                    └── Browse artisan listings
                          └── View artisan profile
                                └── Post job request
                                      └── Receive quotes from artisans
                                            └── Select best quote
                                                  └── Pay via MoMo (escrow)
                                                        └── Track job status in real time
                                                              └── Mark job complete
                                                                    └── MoMo payment released to artisan
                                                                          └── Rate and review artisan
```

### Artisan Flow

```
Open app
  └── Sign up / Login
        └── Select role: Artisan
              └── Build profile (photo, skills, service area, availability)
                    └── Set status: Available
                          └── Receive push notification — new job request
                                └── View job details and uploaded photo
                                      └── Send price quote
                                            └── Homeowner accepts quote
                                                  └── Confirm booking
                                                        └── Travel to job location
                                                              └── Complete job
                                                                    └── Homeowner marks job complete
                                                                          └── Receive MoMo payment
                                                                                └── Rating posted on profile
```

---

## 12. Wireframes

Initial wireframes are available in the `/wireframes` folder of this repository. All screens were designed using Flutter-style Material Design 3 principles with a dark theme consistent with the QuickFix brand identity.

| Screen | File | Description |
|--------|------|-------------|
| Welcome / Splash | `screen1_welcome.png` | App branding, Get Started and Sign In buttons |
| Home Screen | `screen2_home.png` | Location header, hero banner, search bar, category filters, artisan cards with ratings |
| Artisan Profile | `screen3_profile.png` | Verified badge, 3-stat row, skills, reviews with star ratings, book button |
| MoMo Payment | `screen4_payment.png` | Order summary, MTN/Airtel method selector, escrow security notice, pay button |
| Job Tracking | `screen5_tracking.png` | Artisan mini card, map placeholder, 6-step live status progress tracker |

---

## Academic Integrity Statement

All research in this document is original and was conducted by QuickFix team members in Kigali, Rwanda. All app concepts, feature rationale, constraint analysis, and user flows are team-developed based on real field observations and interviews. Any external inspiration has been adapted and cited appropriately.

**AI tools used:**  Claude (Anthropic) was used to assist with document formatting, structure, and wording refinement. 

