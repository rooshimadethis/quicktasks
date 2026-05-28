# GEMINI.md — QuickTasks

Context file for AI assistants working on this project. Read this before making any changes.

---

## What This App Is

**QuickTasks** — a personal Flutter calendar + task app for Android 14 (e-ink phone, primary) and macOS (Phase 3). It's a better UI layer over Google Calendar. The user checks this app instead of Google Calendar.

---

## Package & Config

| Key | Value |
|---|---|
| Package name | `me.rooshi.quicktasks` |
| OAuth Client ID (Android debug) | `317034685883-dvmomrhfl9j6pjgfm71a0o1q6jjcmqdl.apps.googleusercontent.com` |
| GCal scope | `https://www.googleapis.com/auth/calendar` |
| QuickTasks calendar name | `QuickTasks` |

---

## Backend: Google Calendar API Only

- **No Google Tasks API** — dropped in favour of GCal Events for everything
- User-created tasks/events → stored as GCal Events in a dedicated **"QuickTasks" calendar**
- External GCal events (from other calendars) → read + write via full `calendar` scope
- Task-specific metadata (completion, category) → stored in GCal **`extendedProperties`** (private) AND local SQLite
- Local SQLite (Drift) is a **cache + pending sync queue**, not the source of truth

### extendedProperties keys (private)
```
isTask: "true" | "false"
isComplete: "true" | "false"
completedAt: ISO8601 string
category: "work" | "personal" | "errand" | "none"
```

### Sync strategy
- First open: full fetch, past 2 weeks + next 8 weeks
- Subsequent: incremental via `syncToken`
- Local-first writes: `SyncStatus` enum — `synced | pendingCreate | pendingUpdate | pendingDelete`
- Conflict resolution: last-write-wins
- Triggers: app foreground, post-edit, manual pull-to-refresh

---

## Core Data Model

```dart
class CalendarItem {
  final String localId;           // always exists
  final String title;
  final String? description;      // GCal event description field
  final CalendarItemType type;    // task | event
  final String? googleEventId;    // null while pendingCreate
  final String googleCalendarId;  // "quicktasks" | external calendar ID
  final bool isExternalEvent;
  final DateTime startAt;
  final DateTime endAt;           // startAt + 30min default for tasks
  final bool isAllDay;
  final bool isComplete;
  final DateTime? completedAt;
  final TaskCategory category;
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
}

enum CalendarItemType { task, event }
enum TaskCategory { work, personal, errand, none }
enum SyncStatus { synced, pendingCreate, pendingUpdate, pendingDelete }
```

---

## Architecture

**State management**: Riverpod  
**Local DB**: Drift (type-safe SQLite)  
**Navigation**: go_router  
**Google API**: `google_sign_in` + `googleapis`

```
lib/
├── app/
│   ├── router.dart
│   └── theme/
│       ├── paper_theme.dart       # MVP — e-ink only
│       └── normal_theme.dart      # Phase 2
├── features/
│   ├── calendar/
│   │   ├── day_view/              # Primary home screen
│   │   └── week_view/             # 5-col, today ±2 days
│   ├── items/
│   │   ├── calendar_item_chip.dart
│   │   ├── item_bottom_sheet.dart # Create + edit
│   │   └── item_detail_sheet.dart
│   ├── backlog/                   # Unscheduled items drawer
│   └── sync/
│       ├── google_auth_provider.dart
│       └── google_calendar_service.dart
├── data/
│   ├── local/                     # Drift SQLite
│   └── remote/                    # GCal API client
└── domain/
    ├── models/calendar_item.dart
    └── repositories/calendar_item_repository.dart
```

---

## MVP Theme: Paper Mode (E-ink)

Normal/dark theme is Phase 2. Do not add color, gradients, shadows, or animations to MVP code.

| Property | Value |
|---|---|
| Background | `#F5F5F0` |
| Ink | `#1A1A1A` |
| Borders | 1.5dp solid `#1A1A1A` |
| Cards | Border-only, no fill |
| Animations | None — instant transitions |
| Categories | ■ Work, ● Personal, ▲ Errand (shapes, not colors) |
| Min tap target | 56dp |
| Font | Inter (Google Fonts) |

---

## Key UX Behaviours

- **Tap** empty time slot → create Task (bottom sheet, time pre-filled, 30min default)
- **Hold + drag down** across slots → create Event with that duration
- Bottom sheet has Task/Event type toggle for override
- **Swipe left** on task → complete (instant)
- **Swipe right** on task → quick reschedule (+30m / +1h / +3h / Tomorrow / Pick)
- **Long press** → full edit sheet
- **Overdue Tray** — at the *bottom* of Day and Week views; hold-to-drag onto timeline; tap for reschedule sheet
- **Week view**: 5 columns (today ±2), swipe shifts by 1 day, Today button recenters
- **FAB** → new task, no pre-filled time
- External GCal events: same chip, small 📅 icon in corner; fully editable in-app

---

## What's Deferred (Do Not Build Yet)

- Phase 2: NLP quick capture, dark/AMOLED theme, drag from backlog onto timeline, notifications, recurring tasks, Firebase backup, GCal push notifications
- Phase 3: macOS desktop, home screen widget
