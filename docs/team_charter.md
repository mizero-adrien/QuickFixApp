# Team Charter : QuickFix
**Course:** Flutter Widgets & UI Design
**Team Size:** 2 Members
**Project Duration:** 9 Weeks
**Date Established:** March 27, 2026

---

## Team Members & Roles

| Member | Primary Role | Secondary Role |
|--------|-------------|---------------|
| Member 1 | Lead Developer (Flutter UI) | Field Researcher |
| Member 2 | UI/UX Designer & Documentation | Field Researcher |

### Role Descriptions

**Member 1 — Lead Developer**
Responsible for building Flutter screens, implementing state management, integrating Firebase, and writing Dart logic. Leads all technical decisions.

**Member 2 — UI/UX Designer & Documentation**
Responsible for wireframes, user flow diagrams, Figma designs, and all written documentation including this charter, field research, and app concept. Supports development with widget implementation.

> Both members share equal responsibility for field research, testing, and final showcase preparation.

---

## Communication Protocols

### Tools
- **WhatsApp** : daily check-ins, quick questions, sharing files
- **GitHub** : all code and documentation. Commits made with clear messages
- **Google Meet / In-person** — weekly planning meetings

### Meeting Schedule
- **Weekly sync:** Every Saturday, 9:00 AM – 12:00 AM (in-person or Google Meet)
- **Mid-week check-in:** Every Wednesday via WhatsApp (async, no meeting required)
- **Emergency contact:** WhatsApp message  respond within 3 hours during daytime

### Decision Making
- Minor decisions (UI tweaks, small feature changes): individual member decides and informs the other
- Major decisions (feature scope, tech choices, design changes): both members must agree before proceeding
- Disagreements: discuss in the next meeting; if unresolved, default to the decision that best serves the assessment criteria

### Code & Document Standards
- All code committed to `main` branch via pull requests — no direct pushes
- Commit messages follow format: `[feature/fix/docs]: short description`
- Documents written in Markdown and stored in `/docs` folder
- Wireframes stored as PNG or PDF in `/wireframes` folder

---

## GitHub Repository Structure

```
quickfix-app/
├── docs/
│   ├── field_research.md
│   ├── app_concept.md
│   └── team_charter.md
├── wireframes/
│   ├── homeowner_flow.png
│   ├── artisan_flow.png
│   └── screen_designs.pdf
├── interview_recording
│   ├── recording1.mp3
│   ├── recording2.mp3
├
└── README.md
```

---

## 9-Week Project Roadmap

### Phase 1 — Foundation (Weeks 1–2)
**Goal:** Research, planning, and design complete

 Day  Tasks  Owner 

 week 1  Field research, user interviews, problem statement , Both 
 week 1 Set up GitHub repo, project structure, Flutter project init Member 1 
 week 2  Wireframes — all screens sketched and digitized , Member 2 
 week 2  User flow diagrams, app concept document finalized Member 2 

**Milestone:** Assessment 1 submission (field_research.md, app_concept.md, team_charter.md, wireframes)

---

### Phase 2 — Core Screens (Weeks 3–5)
**Goal:** All main Flutter screens built and navigable

| Week | Tasks | Owner |
|------|-------|-------|
| Week 3 | Auth screens — login, signup, role selection (homeowner vs artisan) | Member 1 |
| Week 3 | Bottom navigation bar, routing setup | Member 1 |
| Week 4 | Artisan profile screen | Member 1 |
| Week 4 | Home/search screen with category filters | Member 1 |
| Week 5 | Job request form screen | Member 1 |
| Week 5 | Quote card UI, job listing screen | Member 2 |

---

### Phase 3 — Features & Integration (Weeks 6–8)
**Goal:** Core features functional end-to-end

| Week | Tasks | Owner |
|------|-------|-------|
| Week 6 | Firebase Firestore integration — jobs, profiles, quotes | Member 1 |
| Week 6 | Job status tracking screen (Stepper widget) | Member 2 |
| Week 7 | MoMo payment screen (simulated for demo) | Member 1 |
| Week 7 | Ratings & reviews screen | Member 2 |
| Week 8 | Bug fixes, UI polish, loading states | Both |
| Week 8 | Offline caching with shared_preferences | Member 1 |

---

### Phase 4 — Showcase Preparation (Week 9)
**Goal:** Demo-ready app with compelling presentation

| Task | Owner |
|------|-------|
| Record demo video walkthrough | Both |
| Prepare presentation slides | Member 2 |
| Final app testing on physical device | Both |
| Rehearse showcase presentation | Both |

---

## Success Criteria for Phase 4 Showcase

Our showcase will be considered successful if it achieves all of the following:

### Technical Success
- [ ] App runs without crashes on a physical Android device
- [ ] All 5 MVP screens are navigable (home, profile, job request, payment, status)
- [ ] At least one end-to-end user flow is demonstrable live (post job → receive quote → pay)
- [ ] Firebase data loads correctly in real time during the demo

### Design Success
- [ ] UI is clean, consistent, and uses a coherent color scheme
- [ ] All screens are responsive and work on different screen sizes
- [ ] Artisan-facing screens use large touch targets and icon-first navigation

### Presentation Success
- [ ] We can clearly explain the problem we solved and who it helps
- [ ] We can connect every feature back to a real friction point from our field research
- [ ] We can answer questions about our design decisions and constraints
- [ ] Demo runs smoothly within the allotted presentation time

---

## Working Agreements

1. Both members commit to attending all weekly meetings on time
2. Work is never left to the last day, each weekly milestone is completed by Friday
3. If a member is blocked or struggling, they message the other within the same day no silent suffering
4. Both members review each other's work before it is submitted or merged
5. Credit is shared equally in all presentations and documents

---

## Academic Integrity Statement

We confirm that:
- All field research was conducted independently by each team member
- All user interviews involved real people (not hypothetical scenarios)
- The QuickFix concept was developed by our team based on our own research
- Any external inspiration has been adapted and cited

- AI tools used: **Claude (Anthropic)** :used to help format and structure documents.