# QuickTasks — Flutter Calendar & Tasks App Spec

A personal, opinionated calendar + quick-capture task app built in Flutter. Google Calendar is the **single backend** — this app is the better UI layer on top of it.

---

## Project Configuration

| Key | Value |
|---|---|
| Package name | `me.rooshi.quicktasks` |
| GCP Project | QuickTasks |
| OAuth Client ID (Android debug) | `317034685883-dvmomrhfl9j6pjgfm71a0o1q6jjcmqdl.apps.googleusercontent.com` |
| Debug SHA-1 | `37:2B:AC:CB:FD:C1:62:3D:8A:DE:CE:EF:65:9F:C1:08:CB:55:33:34` |
| GCal scope | `https://www.googleapis.com/auth/calendar` |
| QuickTasks calendar name | `QuickTasks` |

---

## The Core Problem

| Pain Point | Root Cause |
|---|---|
| Google Calendar takes too many taps to add a quick task | Deep navigation, mandatory fields, form-heavy UX |
| Hard to read tasks in GCal | GCal mixes events and tasks poorly; dense UI |
| Missed/overdue tasks disappear into the past | Calendar views don't surface items past their time |
| No single "what do I need to do today" view | GCal doesn't prioritize tasks visually |

---

## Design Philosophy

1. **Speed above all** — Adding a task should be 1–2 taps + typing. No required fields beyond a title and a time.
2. **The past is not gone** — Overdue/incomplete tasks surface at the bottom of every view; drag them to reschedule.
3. **Calendar-first** — Everything lives on a timeline. GCal events and personal tasks look the same.
4. **One app to check** — This app replaces your need to open Google Calendar.
5. **E-ink native** — Paper Mode is the primary design target for MVP.
6. **Evolves with you** — Architecture stays simple enough to extend without rewriting.

---

## Platform Targets

| Platform | Priority |
|---|---|
| Android 14 (e-ink phone) | **Primary — MVP** |
| macOS | Phase 3 |
| iOS | Not planned |

---

## Backend Architecture Decision: GCal Events Only

### Why drop Google Tasks?

Google Tasks has no time field — only a due *date*. Storing scheduled times locally was a workaround that created fragility (data lost on reinstall) and required maintaining two separate APIs (Tasks + Calendar).

**Decision: Use Google Calendar Events as the single backend for everything.**

| Concern | Solution |
|---|---|
| Tasks need a "complete" toggle | Store `isComplete` in GCal `extendedProperties` (private, per-app) + local SQLite |
| Tasks need categories | Store `category` in GCal `extendedProperties` + local SQLite |
| Tasks need a description | GCal events have a `description` field natively ✅ |
| Tasks need a scheduled time | GCal events have `start`/`end` natively ✅ |
| Need to distinguish tasks from real events | Use a dedicated **"QuickTasks" calendar** for user-created tasks; other calendars = external events |
| Resilience across reinstall | `extendedProperties` survive reinstall since they live on the GCal event itself |

### Two calendar sources, one unified UI

| Source | Calendar | Editable | Completable |
|---|---|---|---|
| User-created task | "QuickTasks" calendar (dedicated) | ✅ Full edit | ✅ Yes |
| User-created event | "QuickTasks" calendar (dedicated) | ✅ Full edit | ❌ No |
| External GCal event | Any other calendar | ✅ Full edit (full write scope) | ❌ No |

All three appear as the same chip on the timeline. External events get a small 📅 icon.

**Full GCal write scope for all calendars** — keeping everything in-app eliminates switching to Google Calendar, avoids round-trip sync delays, and preserves future flexibility.

### GCal Extended Properties (private) used
```
isTask: "true" | "false"
isComplete: "true" | "false"
completedAt: ISO8601 string
category: "work" | "personal" | "errand" | "none"
```
Max value: 1024 chars. Max 300 properties per event. Well within limits.

### Phase 2: Firebase / GDrive backup
For additional resilience (e.g., recovery if GCal data is accidentally deleted, or cross-device sync of app-specific metadata), a Firebase or GDrive backup layer can be added in Phase 2.

---

## Google Calendar API — Limits & Considerations

For a single-user personal app, rate limits are essentially a non-issue:

| Limit | Value | Impact |
|---|---|---|
| Requests per minute (per user) | 600 | ~10/sec — no concern for personal use |
| Requests per minute (per project) | 10,000 | No concern |
| Extended property key size | 44 chars | Fine |
| Extended property value size | 1,024 chars | Fine |
| Max events per list request | 2,500 | Use pagination + incremental sync |

### Important API considerations
- **Incremental sync** via `syncToken` — on first load, fetch all events for the configured window. On subsequent syncs, use the returned `syncToken` to fetch only *changed* events. Drastically reduces API calls.
- **Push notifications** — GCal supports webhook-style push notifications. Useful for Phase 2 real-time sync. For MVP, poll on foreground + manual refresh.
- **No per-day quota** — the per-minute limits above are what matters now.
- **403 "Calendar usage limits"** — can happen if you hammer a single calendar too fast. Use exponential backoff. Not a concern for normal single-user usage.
- **Event types** — when fetching, specify `eventTypes=default` to exclude focus time / out of office entries unless desired.

---

## Conflict Resolution

This matters when the same event is modified in GCal (e.g., via Google Calendar app) and locally in QuickTasks before a sync.

| Strategy | How it works | Pros | Cons |
|---|---|---|---|
| **Last-write-wins** | Newer timestamp wins, other is discarded | Simple, no UI needed | Could silently lose a change if clocks drift |
| **First-write-wins** | Server version wins; local change discarded | Safe | Local edits silently fail |
| **Manual resolution** | App shows both versions, you pick | Never loses data | Requires UI; annoying for personal app |
| **Field-level merge** | Each field merged independently | Most sophisticated | Complex; can still conflict |

**Decision: Last-write-wins ✅** For a single-user app used primarily on one device, conflicts are extremely rare. A conflict dialog can be added in Phase 2 if needed.

---

## Unified Item Model

```dart
class CalendarItem {
  final String localId;              // Local UUID (always exists)
  final String title;
  final String? description;         // Stored in GCal event description field

  final CalendarItemType type;       // task | event
  final String? googleEventId;       // GCal event ID (null while pending sync)
  final String googleCalendarId;     // "quicktasks" | external calendar ID
  final bool isExternalEvent;        // true = from another calendar, not QuickTasks

  final DateTime startAt;
  final DateTime endAt;              // For tasks: startAt + 30min default
  final bool isAllDay;

  final bool isComplete;             // Stored in extendedProperties + local SQLite
  final DateTime? completedAt;

  final TaskCategory category;       // Stored in extendedProperties + local SQLite

  final SyncStatus syncStatus;       // synced | pendingCreate | pendingUpdate | pendingDelete
  final DateTime createdAt;
  final DateTime updatedAt;
}

enum CalendarItemType { task, event }
enum TaskCategory { work, personal, errand, none }
enum SyncStatus { synced, pendingCreate, pendingUpdate, pendingDelete }
```

---

## Views

### 1. Day View (Primary / Home)
- Scrollable vertical timeline, **30-min slots**
- `CalendarItem` chips stacked in each slot (tasks and events together)
- External GCal event chips: same appearance + small 📅 icon in corner
- Each chip shows 4–5 words of the title, category shape icon (■●▲), completion toggle on leading edge
- **Description** visible in the detail/edit sheet
- **Creating items:**
  - **Tap** empty slot → bottom sheet, defaults to **Task** type, time pre-filled, 30-min default duration
  - **Hold + drag down** across slots → creates an **Event** with duration matching drag span; bottom sheet opens with Event type pre-selected and duration pre-filled (minimum 30 min)
  - Bottom sheet has **Task / Event type toggle** for manual override
  - Only required field: title
- **Swipe left** → mark complete (instant in Paper Mode)
- **Swipe right** → quick reschedule sheet (+30m, +1h, +3h, Tomorrow, Pick time)
- **Long press** → full edit sheet
- **FAB** → new task, no pre-filled time
- **All-day events**: compact strip in the day header, above the timeline
- **Overdue Tray** at the **bottom** of the timeline (after all time slots):
  - Lists all incomplete tasks with a `startAt` in the past
  - **Hold to activate drag** (~300ms threshold), then drag onto a time slot above to reschedule
  - **Tap** → quick reschedule sheet (fallback; works in all modes)
  - Hidden when empty

### 2. Week View (Secondary)
- **5 columns**: today ±2 days (today always centered)
- Swipe left/right → shifts window by 1 day
- **"Today" button** in app bar → recenters window on today
- No date range label (column day labels are sufficient)
- Chips show 4–5 words of title, readable on e-ink
- All-day events as a small strip at the top of each column
- Tap chip → full edit/detail sheet
- Tap column header → navigate to Day View for that date
- **Overdue Tray** at the bottom (same behavior as Day View)

### 3. Backlog / Inbox Drawer
- Items with no `startAt` (unscheduled)
- Tap item → reschedule sheet to pick a date/time
- Drag from here onto Day View timeline: **Phase 2**
- Access: left edge swipe or hamburger menu

---

## Item Bottom Sheet (Create / Edit)

```
┌────────────────────────────────────────────┐
│  [ Task ]  [ Event ]   ← type toggle       │
│                                            │
│  Title: ___________________________        │
│                                            │
│  Description: _____________________        │
│               _____________________        │
│                                            │
│  Time:  3:00 PM  →  3:30 PM               │
│         (end time shown for events)        │
│                                            │
│  Category: ■ Work  ● Personal  ▲ Errand   │
│            (task only)                     │
│                                            │
│              [ Save ]  [ Cancel ]          │
│  [ Delete ]  (edit mode only)              │
└────────────────────────────────────────────┘
```

---

## Google Calendar Integration

### Setup
- On first sign-in: create (or find) a **"QuickTasks"** calendar in the user's Google account
- Read + write access to all calendars (respecting user's "show in agenda" setting)
- OAuth scope: `calendar` (full) — single scope for everything
- Personal app, not on App Store — no OAuth review concerns

### Sync
- **Incremental sync via `syncToken`**: Full fetch on first open (**past 2 weeks + next 8 weeks**); subsequent syncs fetch only changes — keeps API usage near zero
- **Local-first**: writes hit SQLite immediately with `syncStatus: pendingCreate/Update/Delete`; background sync to GCal API
- **Sync triggers**: app foreground, post-create/edit, manual pull-to-refresh
- **Conflict resolution**: last-write-wins ✅
- **Exponential backoff** on 403/429 errors

---

## Theme: Paper Mode (MVP Only)

Normal/dark AMOLED theme is **Phase 2**.

| Property | Value |
|---|---|
| Background | `#F5F5F0` (off-white, reduces e-ink ghosting) |
| Ink | `#1A1A1A` |
| Borders | 1.5dp solid `#1A1A1A` |
| Cards | Border-only, no fill |
| Gradients | None |
| Animations | None (instant transitions) |
| Shadows | None |
| Category indicator | ■ Work, ● Personal, ▲ Errand |
| Min tap target | 56dp |
| Font | Inter (Google Fonts), bold for titles |
| External event badge | Small 📅 icon, corner of chip |
| Completion visual | Strikethrough title, instant |

---

## Architecture

```
lib/
├── main.dart
├── app/
│   ├── router.dart
│   └── theme/
│       ├── paper_theme.dart           # MVP — e-ink
│       └── normal_theme.dart          # Phase 2 — AMOLED dark
├── features/
│   ├── calendar/
│   │   ├── day_view/
│   │   │   ├── day_view_page.dart
│   │   │   ├── timeline_widget.dart
│   │   │   ├── time_slot_widget.dart  # tap + hold-drag detection
│   │   │   └── overdue_tray_widget.dart
│   │   └── week_view/
│   │       ├── week_view_page.dart
│   │       └── day_column_widget.dart
│   ├── items/
│   │   ├── calendar_item_chip.dart    # Unified chip (task + event)
│   │   ├── item_bottom_sheet.dart     # Create + edit
│   │   └── item_detail_sheet.dart
│   ├── backlog/
│   │   └── backlog_drawer.dart
│   └── sync/
│       ├── google_auth_provider.dart
│       └── google_calendar_service.dart
├── data/
│   ├── local/
│   │   ├── database.dart              # Drift SQLite
│   │   └── calendar_item_dao.dart     # Cache + pending sync queue
│   └── remote/
│       └── gcal_api_client.dart
├── domain/
│   ├── models/calendar_item.dart
│   └── repositories/calendar_item_repository.dart
└── shared/
    └── widgets/
        └── draggable_item_chip.dart
```

**State Management**: Riverpod  
**Local DB**: Drift (type-safe SQLite)  
**Navigation**: go_router  
**Google API**: `google_sign_in` + `googleapis` (`calendar` full scope)

---

## MVP Scope (v1)

| Feature | Status |
|---|---|
| Day view timeline (30-min slots) | ✅ MVP |
| Week view (5-col, centered on today) | ✅ MVP |
| Today button recenters week view | ✅ MVP |
| Tap slot → create task | ✅ MVP |
| Hold+drag slot → create event with duration | ✅ MVP |
| Task/Event toggle in bottom sheet | ✅ MVP |
| Description field on all items | ✅ MVP |
| Full in-app editing for all items | ✅ MVP |
| Delete items | ✅ MVP |
| GCal as single backend (QuickTasks calendar) | ✅ MVP |
| Read external GCal calendars (inline, 📅 icon) | ✅ MVP |
| Edit external GCal events in-app | ✅ MVP |
| Incremental sync via syncToken | ✅ MVP |
| Completion toggle (stored in extendedProperties) | ✅ MVP |
| Category (stored in extendedProperties) | ✅ MVP |
| All-day events in day header | ✅ MVP |
| Overdue Tray (bottom of Day + Week) | ✅ MVP |
| Hold-to-activate drag from Overdue Tray | ✅ MVP |
| Tap overdue item → reschedule sheet | ✅ MVP |
| Swipe left → complete | ✅ MVP |
| Swipe right → quick reschedule | ✅ MVP |
| FAB → new task | ✅ MVP |
| Backlog drawer | ✅ MVP |
| Paper Mode theme | ✅ MVP |
| Quick Capture with NLP parsing | ❌ Phase 2 |
| Normal / dark AMOLED theme | ❌ Phase 2 |
| Drag from backlog onto timeline | ❌ Phase 2 |
| Notifications / reminders | ❌ Phase 2 |
| Recurring tasks | ❌ Phase 2 |
| Firebase / GDrive metadata backup | ❌ Phase 2 |
| Push notifications from GCal API | ❌ Phase 2 |
| macOS desktop | ❌ Phase 3 |
| Home screen widget | ❌ Phase 3 |

---

## Resolved Decisions

| Decision | Choice |
|---|---|
| App & calendar name | **QuickTasks** |
| Backend | Google Calendar API only (no Google Tasks API) |
| OAuth scope | `calendar` full scope for all calendars |
| External event editing | Full in-app edit (no deep links to GCal) |
| Default duration (task + event) | **30 minutes** |
| Sync window on install | Past 2 weeks + next 8 weeks |
| Conflict resolution | Last-write-wins |
| Theme for MVP | Paper Mode (e-ink) only |
| Week view columns | 5 (today ±2), Today button recenters, no date range label |
| Drag threshold | Hold before drag activates (~300ms) |
| Overdue tray position | Bottom of Day and Week views |

---

## Risks & Mitigations

| Risk | Mitigation |
|---|---|
| GCal extended properties lost if event deleted in GCal | Acceptable — local SQLite cache retains state until next full sync |
| Conflict between GCal-app edits and QuickTasks edits | Last-write-wins; negligible for single primary device |
| Hold+drag gesture conflicts with scroll | ~300ms hold threshold before drag activates; velocity heuristics |
| GCal 403 on fast bulk operations | Exponential backoff; not a concern for normal single-user usage |
| "QuickTasks" calendar accidentally deleted by user | Detect on sync, offer to recreate; items lost if not in local cache |
| OAuth scope (full calendar write) | Personal-use app, not published to App Store; no review concerns |
