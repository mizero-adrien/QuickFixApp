# QuickFix — Database Schema

All tables live in the **public** schema of a Supabase PostgreSQL project.
Row-Level Security (RLS) is enabled on every table.

---

## Entity Relationship Overview

```
homeowners ──< jobs ──< bids >── artisans
                  │                  │
                  │              reviews
                  │                  │
              notifications ────────┘
                  │
             favorites (homeowners >──< artisans)
             invitations (homeowners ──> artisans)
             bookings (homeowners + artisans + jobs)
```

---

## Tables

### `homeowners`

Stores the profile for every user who signs up as a homeowner.
The `id` is the same UUID issued by Supabase Auth.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | PK, references `auth.users(id)` | Auth UID |
| `name` | `text` | NOT NULL | Full name |
| `phone_number` | `text` | NOT NULL | Contact phone |
| `location` | `text` | NOT NULL | General area |
| `district` | `text` | NOT NULL | Kigali district (gasabo / kicukiro / nyarugenge) |
| `email` | `text` | NOT NULL | Email address |
| `is_verified` | `boolean` | DEFAULT false | Verification flag |
| `total_jobs_posted` | `integer` | DEFAULT 0 | Running count of jobs posted |
| `joined_at` | `timestamptz` | DEFAULT now() | Account creation time |

---

### `artisans`

Stores the professional profile for every user who signs up as an artisan.
The `id` is the same UUID issued by Supabase Auth.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | PK, references `auth.users(id)` | Auth UID |
| `name` | `text` | NOT NULL | Full name |
| `trade` | `text` | NOT NULL | Primary trade (e.g. Plumber, Electrician) |
| `phone_number` | `text` | NOT NULL | Contact phone |
| `location` | `text` | NOT NULL | Service area |
| `about` | `text` | NOT NULL | Bio / description |
| `skills` | `text[]` | NOT NULL, DEFAULT '{}' | Array of skill tags |
| `years_of_experience` | `integer` | NOT NULL, DEFAULT 0 | Years in trade |
| `starting_price` | `integer` | NOT NULL, DEFAULT 0 | Minimum price in RWF |
| `rating` | `numeric(3,1)` | DEFAULT 0.0 | Average star rating (auto-updated by trigger) |
| `total_reviews` | `integer` | DEFAULT 0 | Review count (auto-updated by trigger) |
| `completed_jobs` | `integer` | DEFAULT 0 | Jobs completed (auto-updated by trigger) |
| `is_available` | `boolean` | DEFAULT true | Availability toggle |
| `profile_image_url` | `text` | NULLABLE | Supabase Storage URL |
| `verification_id` | `text` | NOT NULL, DEFAULT '' | Verification badge ID |
| `verified_on` | `timestamptz` | DEFAULT now() | Verification date |
| `created_at` | `timestamptz` | DEFAULT now() | Profile creation time |

---

### `jobs`

A job request posted by a homeowner seeking a service.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | PK, DEFAULT gen_random_uuid() | Job ID |
| `homeowner_id` | `uuid` | NOT NULL, FK → `homeowners(id)` | Job owner |
| `title` | `text` | NOT NULL | Short job title |
| `description` | `text` | NOT NULL | Full job description |
| `location` | `text` | NOT NULL | Job site address/area |
| `category` | `text` | NOT NULL | Service category (plumbing / electrical / painting / carpentry / cleaning / masonry) |
| `status` | `text` | NOT NULL, DEFAULT 'requested' | Job lifecycle state |
| `budget_rwf` | `integer` | NULLABLE | Homeowner budget in RWF |
| `photo_url` | `text` | NULLABLE | Job photo (Supabase Storage) |
| `assigned_artisan_id` | `uuid` | NULLABLE, FK → `artisans(id)` | Set when a bid is accepted |
| `requested_at` | `timestamptz` | DEFAULT now() | Posting time |

**`status` values (ordered):**
`requested` → `quoted` → `booked` → `on_the_way` → `in_progress` → `completed` | `cancelled`

---

### `bids`

An artisan's offer to complete a specific job.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | PK, DEFAULT gen_random_uuid() | Bid ID |
| `job_id` | `uuid` | NOT NULL, FK → `jobs(id)` | Job being bid on |
| `artisan_id` | `uuid` | NOT NULL, FK → `artisans(id)` | Bidding artisan |
| `amount_rwf` | `integer` | NOT NULL | Bid price in RWF |
| `note` | `text` | NOT NULL, DEFAULT '' | Artisan's message |
| `status` | `text` | NOT NULL, DEFAULT 'pending' | `pending` / `accepted` / `rejected` |
| `created_at` | `timestamptz` | DEFAULT now() | Bid submission time |

**Unique constraint:** `(job_id, artisan_id)` — one bid per artisan per job.

---

### `bookings`

Created when a homeowner books an artisan directly (not via a bid).

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | PK, DEFAULT gen_random_uuid() | Booking ID |
| `job_id` | `uuid` | NOT NULL, FK → `jobs(id)` | Associated job |
| `homeowner_id` | `uuid` | NOT NULL, FK → `homeowners(id)` | Booking homeowner |
| `artisan_id` | `uuid` | NOT NULL, FK → `artisans(id)` | Booked artisan |
| `scheduled_at` | `timestamptz` | NULLABLE | Requested appointment time |
| `note` | `text` | NULLABLE | Extra instructions |
| `created_at` | `timestamptz` | DEFAULT now() | Booking creation time |

---

### `reviews`

A homeowner's rating and comment after a completed job.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | PK, DEFAULT gen_random_uuid() | Review ID |
| `artisan_id` | `uuid` | NOT NULL, FK → `artisans(id)` | Reviewed artisan |
| `homeowner_id` | `uuid` | NOT NULL, FK → `homeowners(id)` | Reviewer |
| `rating` | `integer` | NOT NULL, CHECK (1–5) | Star rating |
| `comment` | `text` | NOT NULL, DEFAULT '' | Written review |
| `created_at` | `timestamptz` | DEFAULT now() | Review time |

**After INSERT trigger `on_review_inserted`:**
Recalculates `artisans.rating` (average, rounded to 1 decimal) and
`artisans.total_reviews` (count) for the affected artisan.

---

### `notifications`

In-app notification inbox; one row per event per recipient.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | PK, DEFAULT gen_random_uuid() | Notification ID |
| `user_id` | `uuid` | NOT NULL, FK → `auth.users(id)` | Recipient user |
| `type` | `text` | NOT NULL | Event type (see below) |
| `title` | `text` | NOT NULL | Notification heading |
| `body` | `text` | NOT NULL | Notification body text |
| `data` | `jsonb` | NOT NULL, DEFAULT '{}' | Payload (job_id, bid_id, etc.) |
| `is_read` | `boolean` | NOT NULL, DEFAULT false | Read/unread flag |
| `created_at` | `timestamptz` | DEFAULT now() | Event time |

**`type` values:**

| Type | Recipient | Trigger |
|---|---|---|
| `new_bid` | Homeowner | Artisan submits a bid |
| `bid_accepted` | Artisan | Homeowner accepts a bid |
| `bid_rejected` | Artisan | Homeowner rejects a bid |
| `booking_declined` | Homeowner | Artisan declines the booking |
| `job_invitation` | Artisan | Homeowner sends a direct invitation |
| `invitation_accepted` | Homeowner | Artisan accepts an invitation |
| `invitation_declined` | Homeowner | Artisan declines an invitation |
| `job_completed` | Both | Job is marked completed |

---

### `favorites`

Join table: a homeowner's saved/favourite artisans.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | PK, DEFAULT gen_random_uuid() | Row ID |
| `homeowner_id` | `uuid` | NOT NULL, FK → `homeowners(id)` | Saving homeowner |
| `artisan_id` | `uuid` | NOT NULL, FK → `artisans(id)` | Saved artisan |
| `created_at` | `timestamptz` | DEFAULT now() | Save time |

**Unique constraint:** `(homeowner_id, artisan_id)` — no duplicate saves.

---

### `invitations`

A direct job invitation from a homeowner to a specific artisan.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `uuid` | PK, DEFAULT gen_random_uuid() | Invitation ID |
| `job_id` | `uuid` | NOT NULL, FK → `jobs(id)` | Relevant job |
| `homeowner_id` | `uuid` | NOT NULL, FK → `homeowners(id)` | Inviting homeowner |
| `artisan_id` | `uuid` | NOT NULL, FK → `artisans(id)` | Invited artisan |
| `status` | `text` | NOT NULL, DEFAULT 'pending' | `pending` / `accepted` / `declined` |
| `message` | `text` | NULLABLE | Optional personal message |
| `created_at` | `timestamptz` | DEFAULT now() | Invitation time |

---

## Database Triggers

### `on_review_inserted` (AFTER INSERT on `reviews`)

```sql
CREATE OR REPLACE FUNCTION recalculate_artisan_rating()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE artisans
  SET
    rating       = (SELECT ROUND(AVG(rating)::numeric, 1) FROM reviews WHERE artisan_id = NEW.artisan_id),
    total_reviews = (SELECT COUNT(*) FROM reviews WHERE artisan_id = NEW.artisan_id)
  WHERE id = NEW.artisan_id;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_review_inserted
  AFTER INSERT ON reviews
  FOR EACH ROW EXECUTE FUNCTION recalculate_artisan_rating();
```

### `on_job_completed` (AFTER UPDATE on `jobs`)

Increments `artisans.completed_jobs` whenever a job transitions to `'completed'`.
Resolves the artisan ID from `assigned_artisan_id` first; falls back to the
accepted bid if the column is null (bid-flow jobs).

```sql
CREATE OR REPLACE FUNCTION increment_artisan_completed_jobs()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_artisan_id uuid;
BEGIN
  IF NEW.status = 'completed' AND OLD.status <> 'completed' THEN
    v_artisan_id := NEW.assigned_artisan_id;
    IF v_artisan_id IS NULL THEN
      SELECT artisan_id INTO v_artisan_id
      FROM bids
      WHERE job_id = NEW.id AND status = 'accepted'
      LIMIT 1;
    END IF;
    IF v_artisan_id IS NOT NULL THEN
      UPDATE artisans
      SET completed_jobs = completed_jobs + 1
      WHERE id = v_artisan_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_job_completed
  AFTER UPDATE ON jobs
  FOR EACH ROW EXECUTE FUNCTION increment_artisan_completed_jobs();
```

---

## Indexes

```sql
CREATE INDEX ON jobs(homeowner_id);
CREATE INDEX ON jobs(status);
CREATE INDEX ON bids(job_id);
CREATE INDEX ON bids(artisan_id);
CREATE INDEX ON notifications(user_id, is_read);
CREATE INDEX ON favorites(homeowner_id);
CREATE INDEX ON reviews(artisan_id);
```

---

## Row-Level Security Policies (summary)

| Table | Policy | Who can read | Who can write |
|---|---|---|---|
| `homeowners` | Owner only | Own row | Own row |
| `artisans` | Public read | All authenticated | Own row |
| `jobs` | Mixed | All authenticated | Homeowner (own) |
| `bids` | Mixed | Job owner + artisan | Artisan (own) |
| `bookings` | Parties only | Homeowner + artisan | Homeowner (own) |
| `reviews` | Public read | All authenticated | Homeowner (own) |
| `notifications` | Owner only | Own rows | Service role only |
| `favorites` | Owner only | Own rows | Own rows |
| `invitations` | Parties only | Homeowner + artisan | Homeowner (own) |
