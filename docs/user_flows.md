# QuickFix — User Flows

This document describes the complete end-to-end flows for both user roles.
Each flow shows every screen, decision point, and database/notification event.

---

## Table of Contents

1. [Onboarding — Homeowner](#1-onboarding--homeowner)
2. [Onboarding — Artisan](#2-onboarding--artisan)
3. [Password Recovery](#3-password-recovery)
4. [Homeowner: Browse & Book an Artisan](#4-homeowner-browse--book-an-artisan)
5. [Homeowner: Post a Job & Manage Bids](#5-homeowner-post-a-job--manage-bids)
6. [Homeowner: Track Job Status & Mark Complete](#6-homeowner-track-job-status--mark-complete)
7. [Homeowner: Favourites](#7-homeowner-favourites)
8. [Homeowner: Leave a Review](#8-homeowner-leave-a-review)
9. [Artisan: Browse Jobs & Submit a Bid](#9-artisan-browse-jobs--submit-a-bid)
10. [Artisan: Respond to Accepted Bid & Advance Status](#10-artisan-respond-to-accepted-bid--advance-status)
11. [Artisan: Receive & Respond to a Direct Invitation](#11-artisan-receive--respond-to-a-direct-invitation)
12. [Notifications Inbox](#12-notifications-inbox)
13. [Profile Editing](#13-profile-editing)
14. [Language Switching](#14-language-switching)
15. [AI: QuickFix Assistant Chatbot](#15-ai-quickfix-assistant-chatbot)
16. [AI: Job Description Helper](#16-ai-job-description-helper)

---

## 1. Onboarding — Homeowner

```
App Launch
  └─> SplashScreen (2 s animated logo)
        └─> No saved session?
              └─> LoginScreen
                    ├─> "Don't have an account? Sign up"
                    │     └─> SignupScreen
                    │           ├─> Enter name, email, password, phone, district
                    │           ├─> Select role: Homeowner
                    │           └─> Tap "Create Account"
                    │                 ├─> [DB] INSERT INTO homeowners
                    │                 └─> Navigate to /home (HomeScreen — Homeowner)
                    └─> Enter email + password → Tap "Login"
                          ├─> [Auth] Supabase signInWithPassword
                          ├─> [DB] Load homeowner profile
                          └─> Navigate to /home (HomeScreen — Homeowner)
```

**Session restore:** If a valid Supabase session exists on app start,
`SplashScreen` loads the profile silently and navigates directly to `/home`.

---

## 2. Onboarding — Artisan

```
SignupScreen
  ├─> Select role: Artisan
  ├─> Enter email, password, phone
  └─> Tap "Create Account"
        ├─> [Auth] Supabase signUp
        └─> Navigate to /artisan-setup (ArtisanSetupScreen)
              ├─> Enter name, trade, location, about, skills, experience, price
              ├─> Upload profile photo (image_picker → Supabase Storage)
              └─> Tap "Complete Setup"
                    ├─> [DB] INSERT INTO artisans
                    └─> Navigate to /home (HomeScreen — Artisan)
```

---

## 3. Password Recovery

```
LoginScreen
  └─> "Forgot password?" link
        └─> Bottom sheet (ForgotPassword modal)
              ├─> Enter email address
              └─> Tap "Send Reset Link"
                    ├─> Button shows spinner (isSending = true)
                    ├─> [Auth] resetPasswordForEmail(email, redirectTo: custom scheme)
                    └─> Success: shows "Email sent — check your inbox" confirmation
                          └─> User taps link in email
                                └─> Deep link opens app (Android intent filter)
                                      └─> AuthChangeEvent.passwordRecovery fires
                                            └─> Navigate to /password-recovery
                                                  ├─> Enter new password (+ confirm)
                                                  └─> Tap "Update Password"
                                                        ├─> [Auth] updateUser(password)
                                                        └─> Navigate to /login
```

**Android deep link:** `com.quickfix.quickfix://login-callback`
Must be whitelisted in Supabase Dashboard → Authentication → Redirect URLs.

---

## 4. Homeowner: Browse & Book an Artisan

```
HomeScreen (Homeowner — tab 0: Home)
  ├─> Top search bar: type to filter artisans by name/trade
  ├─> Category chips: tap to filter grid by ServiceCategory
  ├─> "See All" button → switches to tab 1 (All Artisans)
  ├─> Featured artisan card → tap
  │     └─> ArtisanDetailScreen
  └─> Artisan card in grid → tap
        └─> ArtisanDetailScreen
              ├─> Sliver hero image + name, trade, rating, experience
              ├─> Reviews tab: list of past homeowner reviews
              ├─> Heart icon (top-right): toggle favourite
              │     ├─> [DB] INSERT INTO favorites  (add)
              │     └─> [DB] DELETE FROM favorites  (remove)
              └─> "Book Now" button
                    └─> BookingFormScreen
                          ├─> Enter title, description, date, time, address, note
                          └─> Tap "Confirm Booking"
                                ├─> [DB] INSERT INTO jobs  (status: booked)
                                ├─> [DB] INSERT INTO bookings
                                └─> Navigate back to HomeScreen
```

---

## 5. Homeowner: Post a Job & Manage Bids

```
HomeScreen (Homeowner) — "Post a Job" FAB
  └─> JobPostScreen
        ├─> Enter title, category, location, budget
        ├─> Description field
        │     └─> "✨ Write with AI" button (optional)
        │           └─> AI Description Sheet
        │                 ├─> Type rough notes (or pre-filled from description)
        │                 ├─> Tap "Generate"
        │                 │     ├─> [Groq API] llama-3.3-70b-versatile
        │                 │     └─> Result shown in purple-tinted preview box
        │                 ├─> "Regenerate" to get a new version
        │                 ├─> "Use This Description" → fills description field
        │                 └─> "Discard" → closes sheet, keeps original text
        ├─> Upload optional job photo
        │     └─> [Storage] Supabase Storage → job-photos bucket
        └─> Tap "Post Job"
              ├─> [DB] INSERT INTO jobs  (status: requested)
              └─> Navigate back to HomeScreen

HomeScreen (Homeowner — tab 1: My Jobs)
  └─> Job card shows status badge + bid count
        └─> Tap "View Bids" button
              └─> BidsManagementScreen
                    └─> List of bids (artisan name, trade, amount, note, rating)
                          └─> Tap "Accept" on a bid
                                ├─> [DB] UPDATE bids SET status = 'accepted'
                                ├─> [DB] UPDATE bids SET status = 'rejected'  (all others)
                                ├─> [DB] UPDATE jobs SET status = 'booked', assigned_artisan_id = artisan
                                ├─> [Notify] INSERT notification (type: bid_accepted) → artisan
                                ├─> [Notify] INSERT notification (type: bid_rejected) → other artisans
                                └─> Navigate back
                          └─> Tap "Reject" on a bid
                                ├─> [DB] UPDATE bids SET status = 'rejected'
                                └─> [Notify] INSERT notification (type: bid_rejected) → artisan
```

---

## 6. Homeowner: Track Job Status & Mark Complete

```
HomeScreen (Homeowner — tab 1: My Jobs)
  └─> Active job card
        ├─> "Track" button
        │     └─> JobStatusScreen
        │           ├─> Visual 6-step stepper (Requested → Quoted → Booked →
        │           │   On the Way → In Progress → Completed)
        │           ├─> Current step pulses with animation
        │           └─> "Mark Complete" button (visible to homeowner at any stage)
        │                 └─> Confirmation dialog
        │                       └─> Confirm
        │                             ├─> [DB] UPDATE jobs SET status = 'completed'
        │                             ├─> [Trigger] increment artisan completed_jobs
        │                             ├─> [Notify] INSERT notification (job_completed)
        │                             └─> Navigate back
        └─> "Mark Complete" button (on job card directly)
              └─> Same confirmation + DB update flow as above
```

---

## 7. Homeowner: Favourites

```
HomeScreen (Homeowner — tab 3: Favourites)
  └─> FavoritesScreen
        ├─> Loads artisan list via [DB] SELECT from artisans WHERE id IN (favorites)
        ├─> "N saved artisan(s)" count label
        ├─> Empty state if no favourites saved yet
        └─> Artisan card grid
              ├─> Filled heart = saved; tap heart → [DB] DELETE FROM favorites
              │     └─> Card removed from grid immediately (optimistic update)
              └─> Tap card → ArtisanDetailScreen
                    └─> Heart icon reflects live favourite state
```

**Optimistic update:** The heart icon toggles immediately in the UI.
If the DB call fails, the state reverts and a snackbar error appears.

---

## 8. Homeowner: Leave a Review

```
ArtisanDetailScreen
  └─> Reviews tab
        └─> "Leave a Review" button (shown only if not already reviewed)
              └─> RatingDialog (bottom sheet)
                    ├─> Tap 1–5 stars
                    ├─> Enter optional comment
                    └─> Tap "Submit"
                          ├─> [DB] INSERT INTO reviews
                          ├─> [Trigger] recalculate artisan rating + total_reviews
                          └─> Rating and review count refresh on ArtisanDetailScreen
```

---

## 9. Artisan: Browse Jobs & Submit a Bid

```
HomeScreen (Artisan — tab 1: Jobs)
  └─> JobListScreen
        ├─> Loads open jobs from Supabase (status: requested)
        ├─> Category filter chips
        └─> Job card (title, category, location, budget, bid count)
              └─> Tap job card → inline bid panel expands
                    ├─> Enter bid amount (RWF) and message note
                    └─> Tap "Submit Bid"
                          ├─> [DB] INSERT INTO bids  (status: pending)
                          ├─> [Notify] INSERT notification (type: new_bid) → homeowner
                          └─> Bid card shows "Pending" badge
```

---

## 10. Artisan: Respond to Accepted Bid & Advance Status

```
NotificationsScreen
  └─> Notification: "Your bid was accepted!" (type: bid_accepted)
        ├─> "Accept" button
        │     ├─> [DB] markNotificationRead
        │     └─> Snackbar: "Booking confirmed!"
        └─> "Decline" button
              └─> Confirmation dialog
                    └─> Confirm
                          ├─> [DB] UPDATE jobs SET status = 'requested'  (reopen)
                          ├─> [DB] UPDATE bids SET status = 'rejected'
                          ├─> [Notify] INSERT notification (booking_declined) → homeowner
                          └─> [DB] markNotificationRead

HomeScreen (Artisan — tab 2: My Bids)
  └─> Accepted bid card
        ├─> "Track Status" button → JobStatusScreen (read-only artisan view)
        └─> Status advance buttons:
              ├─> "I'm On My Way"   → [DB] UPDATE jobs SET status = 'on_the_way'
              ├─> "Work Started"    → [DB] UPDATE jobs SET status = 'in_progress'
              └─> "Mark Complete"   → Confirmation dialog
                                          ├─> [DB] UPDATE jobs SET status = 'completed'
                                          ├─> [Trigger] increment artisan completed_jobs
                                          └─> [Notify] INSERT notification (job_completed)
```

---

## 11. Artisan: Receive & Respond to a Direct Invitation

```
NotificationsScreen  OR  HomeScreen (Artisan — Invitations tab)
  └─> InvitationsScreen
        └─> Invitation card (job title, homeowner name, message)
              ├─> "Accept" button
              │     ├─> [DB] UPDATE invitations SET status = 'accepted'
              │     ├─> [Notify] INSERT notification (invitation_accepted) → homeowner
              │     └─> Card updates to "Accepted" badge
              └─> "Decline" button
                    ├─> [DB] UPDATE invitations SET status = 'declined'
                    ├─> [Notify] INSERT notification (invitation_declined) → homeowner
                    └─> Card updates to "Declined" badge
```

---

## 12. Notifications Inbox

```
HomeScreen (any role) — bell icon in AppBar shows unread count badge
  └─> NotificationsScreen  (route: /notifications)
        ├─> Loads all notifications for current user
        ├─> Unread shown with coloured border + dot indicator
        ├─> "Mark all read" button (shown only if unread > 0)
        ├─> Pull-to-refresh reloads the list
        └─> Tap notification → marks it read + runs type-specific action:
              │  new_bid          → no extra action
              │  bid_accepted     → shows Accept / Decline buttons inline
              │  bid_rejected     → no extra action
              │  booking_declined → no extra action
              │  job_invitation   → no extra action
              └─> job_completed   → no extra action
```

---

## 13. Profile Editing

### Homeowner
```
HomeScreen (Homeowner — tab 4: Profile)
  └─> "Edit Profile" button
        └─> HomeownerEditProfileScreen
              ├─> Pre-filled name, phone, location, district
              └─> Tap "Save Changes"
                    └─> [DB] UPDATE homeowners SET ...
```

### Artisan
```
HomeScreen (Artisan — tab 3: Profile)
  └─> "Edit Profile" button
        └─> ArtisanEditProfileScreen
              ├─> Pre-filled name, trade, about, skills, experience, price, availability
              ├─> Change profile photo (image_picker → Supabase Storage)
              └─> Tap "Save Changes"
                    └─> [DB] UPDATE artisans SET ...
```

---

## 14. Language Switching

```
HomeScreen AppBar — globe icon
  └─> LanguageSelector bottom sheet
        └─> Choose: English / Français / Kinyarwanda
              └─> LocaleProvider.locale.value = selected locale
                    └─> ValueListenableBuilder rebuilds entire MaterialApp
                          └─> All AppLocalizations strings update immediately
                                (no app restart required)
```

---

## 15. AI: QuickFix Assistant Chatbot

Accessible from the home screen as a floating button for both user types.

```
HomeScreen (any role)
  └─> "✨ robot" floating button
        └─> AssistantScreen  (route: /assistant)
              ├─> Welcome message pre-loaded
              ├─> Suggestion chips shown until first message is sent:
              │     "How much does plumbing cost in Kigali?"
              │     "How do I post a job?" etc.
              ├─> User types or taps a suggestion
              │     └─> [Groq API] assistantChat(history, userMessage)
              │           system prompt includes: app usage, categories,
              │           Kigali price ranges, language detection
              │
              ├─> Response type A — General answer
              │     └─> White chat bubble displayed on left
              │
              ├─> Response type B — Category recommendation
              │     The AI appends: CATEGORY: [Plumbing|Electrical|...]
              │     └─> App strips the tag from display text
              │           └─> Gradient "Post a [Category] Job" button appears
              │                 └─> Tap
              │                       └─> JobPostScreen with category pre-selected
              │                             └─> (continues job post flow — see flow 5)
              │
              ├─> Response type C — Cost estimate
              │     └─> Price range in RWF shown in chat bubble
              │
              ├─> Conversation history kept for multi-turn context
              ├─> Clear chat button (top-right) resets history
              └─> Animated 3-dot thinking indicator while waiting for API
```

**Language:** The assistant detects and replies in the same language the user writes in
(English, French, or Kinyarwanda).

---

## 16. AI: Job Description Helper

Embedded inside `JobPostScreen`; helps homeowners who struggle to describe their problem.

```
JobPostScreen
  └─> "✨ Write with AI" button (next to Description label)
        └─> _AiDescriptionSheet (bottom sheet)
              ├─> Notes text field
              │     Pre-filled with whatever the homeowner had already typed
              ├─> Tap "Generate"
              │     ├─> Validates: notes field must not be empty
              │     └─> [Groq API] improveJobDescription(category, title, roughNotes)
              │           model: llama-3.3-70b-versatile
              │           max_tokens: 220  |  temperature: 0.65
              │           prompt enforces: 2–4 sentences, specific location,
              │           urgency if implied, expected outcome, no greetings
              ├─> Result displayed in purple-tinted preview box
              ├─> "Regenerate" → calls API again with same notes
              ├─> "Use This Description"
              │     └─> Fills description controller in JobPostScreen
              │           └─> Sheet dismissed; homeowner continues posting
              └─> "Discard"
                    └─> Sheet dismissed; original description unchanged
```

**Error handling:** If the API call fails (network or key issue), a red error message
appears inside the sheet; the homeowner can retry or close and write manually.

---

## Summary: Notification Events Matrix

| Event | Sender | Recipient | Notification type |
|---|---|---|---|
| Artisan bids on a job | Artisan | Homeowner | `new_bid` |
| Homeowner accepts a bid | Homeowner | Artisan | `bid_accepted` |
| Homeowner rejects a bid | Homeowner | Artisan | `bid_rejected` |
| Artisan declines booking | Artisan | Homeowner | `booking_declined` |
| Homeowner invites artisan | Homeowner | Artisan | `job_invitation` |
| Artisan accepts invitation | Artisan | Homeowner | `invitation_accepted` |
| Artisan declines invitation | Artisan | Homeowner | `invitation_declined` |
| Job marked complete | Either | Both | `job_completed` |
