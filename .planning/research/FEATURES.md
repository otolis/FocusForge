# Feature Research

**Domain:** AI-powered productivity (task management + habit tracking + daily planning + collaborative boards)
**Researched:** 2026-03-16
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete or broken.

#### Task Management Core

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Task CRUD with title, description, priority, deadline | Every task app has this. It is the bare minimum. | LOW | Foundation for everything else. Priority should use P1-P4 system with color badges. |
| Task list with filters, sort, and search | Users expect to find tasks instantly. Todoist, TickTick, and every competitor have this. | MEDIUM | Full-text search, filter by priority/category/date, sort by due date/priority/created. |
| Natural language task input | Todoist popularized "file taxes Friday p1" style input. Users now expect it. | MEDIUM | Parse dates, priorities, and categories from free text. Regex+heuristics first, upgrade to NLP later. |
| Recurring tasks | Daily/weekly/monthly repeats are expected in any task manager. TickTick and Todoist both support complex recurrence. | MEDIUM | Support daily, weekly, monthly, custom intervals. Show next occurrence. |
| Due date reminders and notifications | Users rely on task apps to remind them. Without reminders, the app is a glorified notepad. | MEDIUM | Push notifications via FCM. Configurable reminder timing (at time, 15m before, 1h before, 1d before). |
| Categories/labels/tags | Users need to organize tasks by context (work, personal, health). Universal across competitors. | LOW | Color-coded categories. Allow user-created categories. |

#### Habit Tracking Core

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Habit CRUD with flexible frequency | TickTick, Habitica, Streaks all offer daily/weekly/custom frequency. Table stakes. | LOW | Daily, weekly (pick days), custom intervals. Target count support (e.g., "drink 8 glasses water"). |
| Visual streak tracking | Streaks are THE core mechanic of habit apps. Duolingo, Snapchat proved streaks drive retention. Apps with streaks see 40-60% higher DAU. | MEDIUM | Consecutive-day counter, streak freeze option (prevents anxiety from accidental breaks), visual chain display. |
| Habit progress charts and analytics | TickTick includes habit statistics. Users want to see their progress over time. | MEDIUM | Completion rate charts via fl_chart. Weekly/monthly/yearly views. Best streak display. |
| Check-in UI (quick daily check-off) | Must be frictionless. One tap to mark a habit complete. If checking in takes more than 2 seconds, users stop. | LOW | Large tap targets, satisfying feedback animation, batch check-in for multiple habits. |

#### Authentication and User Profile

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Email + OAuth sign-in | Every modern app supports social login. Google sign-in covers the Android user base. | LOW | Supabase Auth handles this. Email + Google for v1. Apple deferred (no Mac). |
| User profile with avatar and preferences | Users expect personalization. Required for collaborative features (who is this person on my board?). | LOW | Display name, avatar (upload or default), timezone, notification preferences. |

#### UX Essentials

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Dark mode | 80%+ of mobile users use dark mode. Missing it feels unprofessional. | LOW | Material 3 theme toggle. Persist preference. System-default option. |
| Responsive, polished UI | For a portfolio app, visual polish IS the product. Recruiters judge quality in 10 seconds. | MEDIUM | Material 3 design system, consistent spacing, proper loading states, empty states, error states. |
| Onboarding flow | 74% of users abandon apps with poor onboarding. Must explain value in under 60 seconds. | LOW | 3-4 screen intro, skip option, progressive disclosure of features. Do NOT front-load every feature. |

### Differentiators (Competitive Advantage)

Features that set FocusForge apart. These are where the portfolio value lives.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| AI daily planner (cloud LLM) | Motion charges $34/mo for AI scheduling. FocusForge does it free via Groq API. Generates an optimized daily timeline from tasks, habits, and energy preferences. This is THE flagship feature. | HIGH | Supabase Edge Function calls Groq (Llama 3). Input: tasks + habits + energy pattern + calendar. Output: time-blocked daily plan. 14,400 req/day free tier. |
| Energy-pattern-aware scheduling | Reclaim.ai and Motion hint at this but don't expose it directly. Matching deep work to peak energy hours is backed by chronotype science. Demonstrates domain knowledge beyond CRUD. | MEDIUM | User sets energy profile (morning person, night owl, or standard). AI planner assigns hard tasks to peak hours, routine tasks to troughs. Visual energy curve in settings. |
| Voice-to-task capture | Speak a task, AI parses it into structured data (title, priority, deadline, category). Goes beyond Todoist's text parsing -- adds voice as input. Shows on-device AI capability. | MEDIUM | speech_to_text package for voice capture. Parse transcript with regex+heuristics. "Call dentist tomorrow priority 2" becomes a structured task. |
| On-device TFLite task classification | Zero-latency, zero-cost, works offline. Classifies tasks into categories and suggests priority. Demonstrates ML engineering skills -- a strong portfolio differentiator over typical Flutter apps. | HIGH | Phase 2 upgrade from regex. Train simple text classifier. tflite_flutter for inference. Model size under 5MB. Accuracy target: 80%+ on common task categories. |
| Realtime collaborative project boards | Multiplayer Kanban with live updates. Demonstrates Supabase Realtime, WebSocket architecture, conflict resolution. The hardest feature = the most impressive for portfolio. | HIGH | Supabase Realtime subscriptions. Drag-and-drop Kanban columns. Board CRUD, card CRUD, member invite, role management (owner/editor/viewer). |
| Live presence indicators on boards | Shows who is online and active on a shared board. Avatar stack with online status dots. Industry standard in Figma, Google Docs, Notion. Demonstrates realtime architecture depth. | MEDIUM | Supabase Presence channel. Broadcast join/leave events. Show colored avatar circles with online indicators. |
| Drag-to-reschedule daily timeline | Interactive timeline where users drag tasks to different time slots. Beyond static lists -- shows advanced Flutter gesture handling and state management. | MEDIUM | GestureDetector + Riverpod state. Snap to 15-minute increments. Visual feedback during drag. Persist changes to Supabase. |
| Completion animations (Lottie/Rive) | Micro-interactions that make task completion feel rewarding. Gamification without being childish. Shows attention to UX craft. | LOW | Lottie for task completion confetti, habit check-in celebrations, streak milestone animations. Keep subtle -- no more than 1 second per animation. |
| Adaptive reminder timing | Notifications that learn when users actually complete tasks, not just when they set reminders. Shows AI integration beyond a single feature. | MEDIUM | Track completion patterns. If user always does "morning run" at 7am, remind at 6:45am. Requires data collection phase before adaptation kicks in. |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems. Explicitly NOT building these.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Offline-first with SQLite sync | "I want to use it without internet" | Offline sync is one of the hardest problems in mobile dev. Conflict resolution with Supabase Realtime boards is a nightmare. Adds weeks of complexity for a portfolio project where the demo will be online anyway. | Online-only for v1. Show graceful offline error states. Queue actions during brief disconnects. |
| Real-time chat in boards | "Teams need to communicate" | Chat is a separate product. Building it well requires typing indicators, read receipts, message history, media support. Massive scope creep. | Comments on cards (async). Link to external chat (Discord/Slack). |
| Calendar integration (Google/Outlook sync) | "I want to see my tasks in my calendar" | OAuth complexity, two-way sync conflicts, timezone edge cases. Each calendar provider is a separate integration to maintain. | AI planner generates a standalone daily view. Export to .ics file as a v2 feature. |
| Gamification with points/levels/leaderboards | "Make it fun like Habitica" | Full gamification requires economy balancing, anti-cheat, social comparison anxiety. Habitica's model works because it IS the product. For a productivity app, it's a distraction from core value. | Subtle gamification: streaks, milestone celebrations, completion animations. Reward consistency, not competition. |
| Social features (friend feed, public profiles) | "I want accountability partners" | Social features require content moderation, privacy controls, blocking, reporting. Massive compliance surface. Not core to the productivity value. | Collaborative boards serve the "work with others" need. No public social layer. |
| Pomodoro timer | "TickTick has one" | Pomodoro is a separate workflow. Building it well means custom intervals, break reminders, session history, focus mode. Scope creep that dilutes the AI planning differentiator. | The AI daily planner already time-blocks work sessions. Focus mode (DND) is a phone OS feature. |
| Apple sign-in | "iOS users expect it" | Requires Mac for testing, Apple Developer account, and platform-specific configuration. No Mac available. | Email + Google covers the audience. Add Apple sign-in post-v1 when Mac access is available. |
| File/image attachments on tasks | "I want to attach photos and documents" | Storage costs, file type validation, preview generation, virus scanning. Supabase Storage free tier is limited. | Text descriptions and links. Rich text editor for task descriptions as a v2 feature. |
| Multi-language/i18n | "Support my language" | Proper i18n requires translation management, RTL support, date/number formatting, ongoing maintenance. Overkill for a portfolio project. | English only for v1. Structure code with l10n in mind (use Flutter intl patterns) so it CAN be added later. |

## Feature Dependencies

```
[Auth (Email + Google)]
    |-- requires --> [Supabase Auth Setup]
    |-- enables --> [User Profile]
    |                   |-- enables --> [Energy Pattern Preferences]
    |                   |                   |-- enables --> [AI Daily Planner (energy-aware)]
    |                   |-- enables --> [Collaborative Board Membership]
    |
    |-- enables --> [Task CRUD]
    |                   |-- enables --> [Task Filters & Search]
    |                   |-- enables --> [Natural Language Input]
    |                   |                   |-- enhances --> [Voice-to-Task Capture]
    |                   |-- enables --> [Task Categories/Labels]
    |                   |-- enables --> [Due Date Reminders (FCM)]
    |                   |-- enables --> [Recurring Tasks]
    |                   |-- enables --> [On-Device TFLite Classification]
    |
    |-- enables --> [Habit CRUD]
    |                   |-- enables --> [Streak Tracking]
    |                   |                   |-- enables --> [Streak Animations (Lottie)]
    |                   |-- enables --> [Habit Analytics (fl_chart)]
    |                   |-- enables --> [Quick Check-in UI]
    |
    |-- enables --> [AI Daily Planner]
    |                   |-- requires --> [Task CRUD + Habit CRUD + Energy Preferences]
    |                   |-- enables --> [Daily Timeline View]
    |                   |                   |-- enables --> [Drag-to-Reschedule]
    |                   |-- requires --> [Supabase Edge Function + Groq API]
    |
    |-- enables --> [Collaborative Boards]
                        |-- requires --> [Supabase Realtime]
                        |-- enables --> [Kanban Drag-and-Drop]
                        |-- enables --> [Board Member Invite & Roles]
                        |-- enables --> [Live Presence Indicators]

[Dark Mode] -- independent (no dependencies)
[Onboarding Flow] -- independent (no dependencies, but should reference existing features)
[Completion Animations] -- enhances --> [Task CRUD, Habit Check-in, Streak Milestones]
[Adaptive Reminder Timing] -- requires --> [Due Date Reminders + Completion Pattern Data]
```

### Dependency Notes

- **AI Daily Planner requires Task CRUD + Habit CRUD + Energy Preferences:** The planner needs tasks and habits to exist before it can schedule them. Energy preferences must be set in user profile first.
- **On-Device TFLite requires Task CRUD:** Needs task data to classify. Also needs a trained model, which requires collecting task data to train on -- Phase 2 feature.
- **Collaborative Boards require Auth + User Profile:** Board membership depends on user identity. Presence indicators depend on profile data (avatar, name).
- **Drag-to-Reschedule requires Daily Timeline:** Can't drag tasks on a timeline that doesn't exist yet.
- **Adaptive Reminder Timing requires Reminders + Data:** Needs baseline completion data before it can adapt. This is a late-stage feature.
- **Voice-to-Task enhances Natural Language Input:** Voice adds a capture modality; NLP parsing works the same whether input is typed or spoken.

## MVP Definition

### Launch With (v1)

Minimum viable product -- enough to demonstrate all four pillars (tasks, habits, AI planning, collaboration) in a working app.

- [ ] Auth (email + Google) -- gatekeeper for everything
- [ ] User profile with energy preferences -- required for AI planner differentiation
- [ ] Task CRUD with priority, category, deadline -- core pillar #1
- [ ] Natural language task input (text) -- shows NLP capability
- [ ] Task list with filters and search -- usability essential
- [ ] Habit CRUD with daily/weekly frequency -- core pillar #2
- [ ] Streak tracking with visual display -- the hook that keeps users coming back
- [ ] AI daily planner via Groq API -- core pillar #3, flagship differentiator
- [ ] Daily timeline view -- visual output of AI planner
- [ ] Collaborative project board with Kanban -- core pillar #4, portfolio showpiece
- [ ] Supabase Realtime for live board updates -- proves realtime architecture skill
- [ ] Push notifications (FCM) -- table stakes for mobile
- [ ] Dark mode -- expected by all users
- [ ] Completion animations (Lottie) -- polish that signals quality
- [ ] Onboarding flow (3-4 screens) -- prevents Day 1 abandonment

### Add After Validation (v1.x)

Features to add once core is working and demo-ready.

- [ ] Voice-to-task capture -- when text NLP parsing is solid and proven
- [ ] Habit analytics with progress charts (fl_chart) -- when users have enough data to visualize
- [ ] Drag-to-reschedule on daily timeline -- when timeline view is stable
- [ ] Live presence indicators on boards -- when board realtime is reliable
- [ ] Board member invite and role management -- when boards work for single user
- [ ] Recurring tasks -- when basic task CRUD is polished
- [ ] Adaptive reminder timing -- when enough completion data is collected
- [ ] Streak freeze mechanic -- when streak tracking proves engaging

### Future Consideration (v2+)

Features to defer until the portfolio demo is polished and deployed.

- [ ] On-device TFLite task classification -- requires model training, task data corpus. Phase 2 upgrade from regex.
- [ ] .ics calendar export -- low priority, nice-to-have
- [ ] Rich text task descriptions -- markdown editor, beyond MVP scope
- [ ] Board templates (sprint board, personal project, etc.) -- content creation overhead
- [ ] Multi-language support -- structure code for it now, implement later
- [ ] Offline queue for brief disconnects -- graceful degradation, not full offline sync

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Auth (email + Google) | HIGH | LOW | P1 |
| User profile + energy preferences | HIGH | LOW | P1 |
| Task CRUD | HIGH | LOW | P1 |
| Natural language task input | HIGH | MEDIUM | P1 |
| Task filters and search | HIGH | MEDIUM | P1 |
| Habit CRUD with frequency | HIGH | LOW | P1 |
| Streak tracking (visual) | HIGH | MEDIUM | P1 |
| AI daily planner (Groq) | HIGH | HIGH | P1 |
| Daily timeline view | HIGH | MEDIUM | P1 |
| Collaborative Kanban boards | HIGH | HIGH | P1 |
| Supabase Realtime board updates | HIGH | MEDIUM | P1 |
| Push notifications (FCM) | MEDIUM | MEDIUM | P1 |
| Dark mode | MEDIUM | LOW | P1 |
| Completion animations | MEDIUM | LOW | P1 |
| Onboarding flow | MEDIUM | LOW | P1 |
| Categories/labels | MEDIUM | LOW | P1 |
| Recurring tasks | MEDIUM | MEDIUM | P2 |
| Voice-to-task | HIGH | MEDIUM | P2 |
| Habit analytics (charts) | MEDIUM | MEDIUM | P2 |
| Drag-to-reschedule | MEDIUM | MEDIUM | P2 |
| Live presence indicators | MEDIUM | MEDIUM | P2 |
| Board invite + roles | MEDIUM | MEDIUM | P2 |
| Adaptive reminders | MEDIUM | HIGH | P2 |
| Streak freeze | LOW | LOW | P2 |
| On-device TFLite | HIGH | HIGH | P3 |
| .ics export | LOW | LOW | P3 |
| Offline queue | LOW | HIGH | P3 |

**Priority key:**
- P1: Must have for launch -- core loop of tasks + habits + AI planner + boards
- P2: Should have -- adds polish and depth after core is stable
- P3: Nice to have -- defer until portfolio is demo-ready

## Competitor Feature Analysis

| Feature | Todoist | TickTick | Motion | Reclaim.ai | FocusForge Approach |
|---------|---------|---------|--------|------------|---------------------|
| Task CRUD | Excellent, minimal | Full-featured | AI-driven | Calendar-first | Clean CRUD with AI classification layer |
| Natural language input | Best-in-class text parsing | Good text parsing | N/A | N/A | Text + voice input with NLP heuristics |
| Habit tracking | Bolt-on (extension) | Native, with streaks | None | Habits as calendar blocks | Native with streaks, analytics, and AI planner integration |
| AI scheduling | Basic (smart schedule) | None | Core product ($34/mo) | Core product ($10/mo) | Free via Groq API -- budget differentiator |
| Energy/chronotype awareness | None | None | Implied | Time preferences | Explicit energy profile with AI schedule optimization |
| Collaboration | Shared projects | Shared lists | Team scheduling | Team calendar | Realtime Kanban boards with presence |
| Realtime sync | Eventual consistency | Eventual consistency | Realtime | Realtime (calendar) | Supabase Realtime (true realtime boards) |
| On-device AI | None | None | None | None | TFLite task classification (unique differentiator) |
| Price | $5/mo (premium) | $3/mo (premium) | $34/mo | $10/mo | Free (portfolio project) |
| Animations/polish | Minimal | Moderate | Professional | Professional | Lottie/Rive completion animations |

### Key Competitive Insights

1. **No competitor combines all four pillars** (tasks + habits + AI planner + realtime boards) in one app. Todoist does tasks well. TickTick adds habits. Motion does AI scheduling. None do all four.
2. **AI scheduling is premium everywhere** ($10-34/mo). FocusForge delivers it free via Groq's free tier -- an impressive constraint to showcase in a portfolio.
3. **On-device ML is absent from all competitors.** TFLite task classification is a genuine differentiator that demonstrates ML engineering skill no other task app showcases.
4. **Realtime collaboration in a personal productivity app is rare.** Most task apps are single-user or use eventual consistency. True realtime Kanban with presence is a portfolio-grade technical achievement.

## Sources

- [Zapier: Best AI Productivity Tools 2026](https://zapier.com/blog/best-ai-productivity-tools/)
- [Morgen: 5 Best AI Task Manager Software Tools 2026](https://www.morgen.so/blog-posts/ai-task-manager)
- [Motion: Todoist vs TickTick](https://www.usemotion.com/blog/todoist-vs-ticktick)
- [Kuse: I Tested 14 Best AI Task Managers 2026](https://www.kuse.ai/blog/workflows-productivity/ai-task-manager)
- [Trophy: How Streaks Leverages Gamification for Retention](https://trophy.so/blog/streaks-gamification-case-study)
- [Zapier: Chronotype Productivity Schedule](https://zapier.com/blog/chronotype-productivity-schedule/)
- [Reclaim.ai: AI Calendar for Work & Life](https://reclaim.ai/)
- [Plotline: Streaks and Milestones for Gamification](https://www.plotline.so/blog/streaks-for-gamification-in-mobile-apps)
- [Emizentech: Complete Guide on Habit Tracking App 2025](https://emizentech.com/blog/habit-tracking-app.html)
- [Taskade: 10 Best AI To-Do List Apps 2026](https://www.taskade.com/blog/best-ai-todo-list-apps)
- [DEV: Presence Indicators Like Live Cursors](https://dev.to/superviz/how-to-use-presence-indicators-like-live-cursors-to-enhance-user-experience-38jn)
- [Medium: Building Flutter App with On-Device ML Models](https://dasroot.net/posts/2025/12/building-a-flutter-app-with-on-device/)
- [Medium: Building AI-Powered Mobile Apps with On-Device LLMs](https://medium.com/@stepan_plotytsia/building-ai-powered-mobile-apps-running-on-device-llms-in-android-and-flutter-2025-guide-0b440c0ae08b)

---
*Feature research for: AI-powered productivity (task management + habit tracking + daily planning + collaborative boards)*
*Researched: 2026-03-16*
