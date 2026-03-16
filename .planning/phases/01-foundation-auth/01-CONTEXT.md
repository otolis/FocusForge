# Phase 1: Foundation & Auth - Context

**Gathered:** 2026-03-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Set up the Flutter project scaffold with Clean Architecture, configure Supabase (Auth, DB), implement email + Google authentication, user profile with energy preferences, dark/light/system theme toggle with Material 3, and a skippable onboarding flow for first launch. This phase establishes the foundation all other phases build on.

</domain>

<decisions>
## Implementation Decisions

### Theme & visual identity
- Warm & friendly overall vibe — approachable, encouraging, "You've got this" feel
- Rounded corners throughout, friendly micro-copy
- Amber/orange seed color (#FF8F00 range) for Material 3 dynamic color scheme
- Light mode: deep amber primary, cream white surfaces, teal/forest green accents
- Dark mode: soft gold primary, warm charcoal surfaces, sage green accents
- System default theme on first launch (follows device setting), user can override in settings to light/dark/system
- Google Fonts for custom typography — specific font pairing at Claude's discretion, matching warm & friendly direction

### Claude's Discretion
- Specific Google Font pairing (recommended direction: rounded/friendly headings like Nunito, clean body like Inter)
- Corner radius values, elevation/shadow style
- Icon set choice (Material Icons vs alternatives)
- Onboarding flow content and illustrations
- App shell navigation structure (bottom nav tabs, placeholder sections)
- Profile screen layout and energy preference picker design
- Avatar handling approach (upload vs initials)

</decisions>

<specifics>
## Specific Ideas

- Amber with teal/green accents gives the app a warm but productive feel — stands out from typical blue/purple productivity apps
- The vibe is Duolingo-like encouragement meets productivity — not gamified, but supportive

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- None — greenfield project, no code exists yet

### Established Patterns
- Clean Architecture decided (data/domain/presentation layers per feature)
- Riverpod 2 for state management
- go_router for navigation

### Integration Points
- Supabase project setup (Auth, PostgreSQL) is the primary integration
- Theme configuration must be accessible app-wide via Riverpod provider
- Auth state drives navigation (unauthenticated → login, authenticated → home)

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-foundation-auth*
*Context gathered: 2026-03-16*
