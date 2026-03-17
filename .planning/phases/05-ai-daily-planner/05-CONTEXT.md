# Phase 5: AI Daily Planner - Context

**Gathered:** 2026-03-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Users can create plannable items, generate an AI-optimized daily schedule via a Supabase Edge Function calling Groq API (Llama 3), view the schedule as a visual time-blocked timeline, and drag items to different time slots. The AI respects the user's energy pattern preferences (peak/low hours from their profile). Real tasks (Phase 2) and habits (Phase 4) are wired in during Phase 8 -- this phase uses its own standalone plannable items.

</domain>

<decisions>
## Implementation Decisions

### Schedule data source
- Manual plannable items -- users add items with title, estimated duration, and energy level
- Item fields: title (free text), duration (15/30/45/60/90/120 min picker), energy level (high/medium/low)
- AI uses item energy level to match against user's peak/low hours from their profile
- Items persist in Supabase (new DB table) -- needed for Edge Function access and cross-session persistence
- Users can plan for today (default) or select a future date
- Phase 8 later wires real tasks/habits into this planner, replacing or supplementing manual items

### Timeline visual design
- Vertical scrollable timeline with hour markers on the left (6 AM to 10 PM, matching energy picker range)
- Time blocks rendered as colored cards spanning their proportional duration (15 min = small, 2 hours = tall)
- Energy zones shown as subtle background color bands: warm amber for peak hours, muted sage for low hours, neutral for regular hours
- Empty time slots shown as dotted placeholder outlines with a "+" to add items
- Proportional height gives accurate visual sense of how the day is packed

### AI generation flow
- Prominent "Plan My Day" button (FAB or primary button) at top of planner screen
- First visit shows empty timeline with the button as the primary CTA
- Tapping sends plannable items + energy pattern to the Supabase Edge Function
- While generating: shimmer skeleton on timeline (placeholder blocks where schedule will appear)
- After generation: "Regenerate" option appears, with optional text input for constraints (e.g., "I have a meeting at 2 PM")
- On Groq API failure: friendly warm error message with retry button, no fallback scheduling logic in v1

### Drag-to-reschedule
- 15-minute snap intervals with faint horizontal guide lines shown while dragging
- Dragged block lifts with Material elevation shadow; original position shows translucent ghost outline
- Drop zone highlighted with primary amber color
- Push-down displacement when blocks would overlap -- lower block pushes to next available slot
- No block resizing in v1 -- move only. Users edit duration from item detail instead

### Claude's Discretion
- Edge Function implementation details (Deno/TypeScript, prompt engineering for Groq)
- Exact shimmer/skeleton animation style
- Plannable item card design details (within warm/friendly theme direction)
- Database table schema for plannable items and generated schedules
- Whether to cache generated schedules or always regenerate
- Specific Groq model version (Llama 3.x)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Energy pattern model
- `lib/features/profile/domain/profile_model.dart` -- EnergyPattern class with peakHours/lowHours (List<int>), Profile model with energyPattern field
- `lib/features/profile/presentation/widgets/energy_prefs_picker.dart` -- Hour range 6 AM-10 PM, peak (primary) vs low (tertiary) color coding
- `supabase/migrations/00001_create_profiles.sql` -- energy_pattern JSONB column with default {"peak_hours": [9,10,11], "low_hours": [14,15]}

### Navigation and app shell
- `lib/core/router/app_router.dart` -- `/planner` route exists as PlaceholderTab, wired in ShellRoute
- `lib/shared/widgets/app_shell.dart` -- Bottom nav with Planner tab (calendar icon) at index 2

### Theme and shared widgets
- `lib/core/theme/app_theme.dart` -- Material 3 theme with amber seed color
- `lib/core/theme/color_schemes.dart` -- Light/dark color schemes
- `lib/shared/widgets/app_button.dart` -- Reusable button widget
- `lib/shared/widgets/app_text_field.dart` -- Reusable text field widget
- `lib/shared/widgets/loading_overlay.dart` -- Loading overlay widget

### Requirements
- PLAN-01: AI-optimized daily schedule via Edge Function + Groq API
- PLAN-02: Visual time-blocked timeline view
- PLAN-03: Drag tasks to time slots with 15-min snap

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `EnergyPattern` model (profile_model.dart): Already has peakHours/lowHours with JSON serialization -- Edge Function can consume this directly
- `EnergyPrefsPicker` widget: Establishes the 6 AM-10 PM hour range and peak/low color scheme that the timeline should mirror
- `AppButton`, `AppTextField`, `LoadingOverlay`: Shared widgets available for planner UI
- Material 3 theme with amber/teal color scheme: Timeline energy bands should use these same semantic colors

### Established Patterns
- Clean Architecture: planner feature needs data/ (repository + Supabase client), domain/ (models), presentation/ (screens + providers + widgets)
- Riverpod 2: StateNotifier or AsyncNotifier for planner state (schedule, loading, plannable items)
- go_router: `/planner` route already registered, just needs the real screen swapped in

### Integration Points
- `app_router.dart` line 105: Replace `PlaceholderTab(title: 'Planner')` with the real PlannerScreen
- `profile_provider.dart`: Profile data (including energy pattern) accessible via existing provider
- Supabase client: Already configured in the app via `supabase_flutter` SDK
- First Edge Function in the project: `supabase/functions/` directory needs to be created

</code_context>

<specifics>
## Specific Ideas

- User selected manual plannable items for standalone utility before Phase 8 wires real tasks
- Energy zone visualization (amber peak, sage low) mirrors the EnergyPrefsPicker color language -- users see consistency between settings and schedule
- "Plan My Day" as primary CTA aligns with the app's warm, encouraging tone ("Let's plan your day!")
- Push-down displacement for overlap prevention keeps rearranging intuitive without manual conflict resolution

</specifics>

<deferred>
## Deferred Ideas

None -- discussion stayed within phase scope

</deferred>

---

*Phase: 05-ai-daily-planner*
*Context gathered: 2026-03-18*
