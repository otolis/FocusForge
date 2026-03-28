# FocusForge

A smart productivity app that combines task management, habit tracking, and AI-powered daily planning — built with Flutter and Supabase.

## What It Does

- **Smart Task Input** — Type naturally, FocusForge extracts the title, deadline, priority, and category for you
- **AI Daily Planner** — Get a personalized schedule based on your tasks, energy levels, and priorities
- **Habit Tracking** — Build streaks, visualize progress, and stay consistent
- **Collaborative Boards** — Share project boards with your team in real-time
- **Smart Notifications** — Timely reminders that adapt to your schedule

## Tech Stack

| Layer | Tech |
|---|---|
| Frontend | Flutter + Material 3 |
| State | Riverpod 2.x |
| Backend | Supabase (Auth, DB, Realtime, Edge Functions) |
| AI | On-device NLP + Groq LLM |
| Navigation | go_router |

## Getting Started

```bash
# Clone the repo
git clone https://github.com/your-username/FocusForge.git
cd FocusForge

# Install dependencies
flutter pub get

# Set up Supabase credentials
cp lib/core/constants/supabase_constants.dart.example lib/core/constants/supabase_constants.dart
# Edit the file with your Supabase URL and anon key

# Run
flutter run
```

## Status

Actively in development. Core features are built and functional — more updates coming soon.

## License

MIT
