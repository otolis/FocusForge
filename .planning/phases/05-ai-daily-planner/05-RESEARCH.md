# Phase 5: AI Daily Planner - Research

**Researched:** 2026-03-18
**Domain:** Supabase Edge Functions (Deno/TypeScript), Groq LLM API, Flutter drag-and-drop timeline UI
**Confidence:** HIGH

## Summary

Phase 5 requires three technical pillars: (1) a Supabase Edge Function calling the Groq API to generate optimized daily schedules, (2) a vertical timeline UI showing time-blocked schedule cards with energy zone backgrounds, and (3) drag-to-reschedule interaction with 15-minute snap intervals. The project has no existing Edge Functions, making this the first serverless function. The existing `EnergyPattern` model, profile provider, and theme system provide solid integration points.

The recommended approach uses a raw `fetch()` call to Groq's OpenAI-compatible API from the Deno Edge Function (avoiding npm SDK overhead), a new `plannable_items` Supabase table for standalone items, and a `generated_schedules` table to cache generated plans. On the Flutter side, `LongPressDraggable` + `DragTarget` widgets handle drag-to-reschedule with vertical axis locking and custom snap logic. No third-party Flutter packages are needed beyond what the project already uses.

**Primary recommendation:** Use raw HTTP `fetch()` to Groq from the Edge Function with JSON mode, build the timeline with Flutter's built-in `LongPressDraggable`/`DragTarget` + `GestureDetector` for snap behavior, and store both plannable items and generated schedules in Supabase tables with RLS.

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions

- **Schedule data source:** Manual plannable items with title, estimated duration (15/30/45/60/90/120 min picker), and energy level (high/medium/low). Items persist in Supabase. Users can plan for today (default) or select a future date. Phase 8 later wires real tasks/habits.
- **Timeline visual design:** Vertical scrollable timeline with hour markers (6 AM to 10 PM), proportionally-sized colored cards, energy zone background bands (warm amber peak, muted sage low, neutral regular), empty slot placeholders with "+" button.
- **AI generation flow:** "Plan My Day" button as primary CTA, shimmer skeleton during generation, "Regenerate" option with optional constraint text input, friendly error + retry on Groq failure, no fallback scheduling logic.
- **Drag-to-reschedule:** 15-minute snap intervals with faint guide lines, Material elevation shadow on dragged block, translucent ghost at original position, push-down displacement for overlap, no block resizing (move only).

### Claude's Discretion

- Edge Function implementation details (Deno/TypeScript, prompt engineering for Groq)
- Exact shimmer/skeleton animation style
- Plannable item card design details (within warm/friendly theme direction)
- Database table schema for plannable items and generated schedules
- Whether to cache generated schedules or always regenerate
- Specific Groq model version (Llama 3.x)

### Deferred Ideas (OUT OF SCOPE)

None -- discussion stayed within phase scope

</user_constraints>

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PLAN-01 | User can generate an AI-optimized daily schedule from their tasks, habits, and energy preferences via Supabase Edge Function calling Groq API | Edge Function boilerplate, Groq API format, prompt engineering, DB schema for plannable items and schedules |
| PLAN-02 | User can view daily schedule as a visual time-blocked timeline | Timeline widget architecture, proportional height calculation, energy zone background rendering, hour marker layout |
| PLAN-03 | User can drag tasks to different time slots on the timeline (snap to 15-minute increments) | LongPressDraggable + DragTarget pattern, snap logic, push-down displacement algorithm, ghost/elevation feedback |

</phase_requirements>

## Standard Stack

### Core (Already in Project)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| supabase_flutter | ^2.12.0 | Backend SDK, Edge Function invocation | Already installed; `functions.invoke()` handles auth headers automatically |
| flutter_riverpod | ^3.3.1 | State management for planner | Already installed; AsyncNotifier pattern for schedule state |
| go_router | ^17.1.0 | Navigation | Already installed; `/planner` route exists as placeholder |

### Edge Function Runtime

| Technology | Version | Purpose | Why Standard |
|------------|---------|---------|--------------|
| Deno | Built-in (Supabase Edge Runtime) | Edge Function runtime | No choice -- Supabase Edge Functions run on Deno |
| TypeScript | Deno-native | Edge Function language | Default for Supabase Edge Functions |

### AI Model

| Service | Model | Purpose | Why This One |
|---------|-------|---------|--------------|
| Groq API | `llama-3.3-70b-versatile` | Schedule generation | Best quality on free tier; 1K RPD and 100K TPD sufficient for a portfolio app; fast inference |

### No Additional Packages Needed

The phase does not require any new Flutter packages. The drag-and-drop functionality uses Flutter's built-in `LongPressDraggable`, `DragTarget`, and `GestureDetector` widgets. The shimmer effect can be built with Flutter's `LinearGradient` + `AnimationController` or a simple `Container` with opacity animation -- no package needed for the scope described.

## Architecture Patterns

### Recommended Feature Structure

```
lib/features/planner/
  data/
    planner_repository.dart       # Supabase CRUD for plannable items + Edge Function invocation
  domain/
    plannable_item_model.dart     # PlannableItem with title, duration, energyLevel
    schedule_model.dart           # GeneratedSchedule with list of ScheduleBlock
    schedule_block_model.dart     # ScheduleBlock with itemId, startTime, endTime
  presentation/
    providers/
      planner_provider.dart       # AsyncNotifier managing schedule state
      plannable_items_provider.dart # StateNotifier for plannable items CRUD
    screens/
      planner_screen.dart         # Main screen with FAB + timeline
    widgets/
      timeline_widget.dart        # Vertical scrollable timeline container
      time_block_card.dart        # Individual schedule block card (draggable)
      hour_marker.dart            # Hour label on the left axis
      energy_zone_band.dart       # Background color band for energy zones
      empty_slot.dart             # Dotted placeholder with "+" button
      shimmer_timeline.dart       # Shimmer skeleton for loading state
      add_item_sheet.dart         # Bottom sheet for adding plannable items
      regenerate_bar.dart         # Regenerate button + constraint text input

supabase/
  functions/
    _shared/
      cors.ts                     # CORS headers (shared across all future functions)
    generate-schedule/
      index.ts                    # Edge Function: receives items + energy pattern, calls Groq, returns schedule
  migrations/
    00002_create_planner_tables.sql  # plannable_items + generated_schedules tables
```

### Pattern 1: Edge Function with Groq API

**What:** A Supabase Edge Function that receives plannable items and energy pattern, constructs a prompt, calls Groq's chat completions API, and returns a structured schedule.

**When to use:** Any AI-powered feature that needs server-side LLM access with secret API key management.

**Example:**

```typescript
// supabase/functions/generate-schedule/index.ts
// Source: Supabase Edge Functions docs + Groq API reference

import { corsHeaders } from '../_shared/cors.ts'

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { items, energyPattern, constraints } = await req.json()
    const groqApiKey = Deno.env.get('GROQ_API_KEY')

    if (!groqApiKey) {
      throw new Error('GROQ_API_KEY not configured')
    }

    const systemPrompt = buildSystemPrompt(energyPattern, constraints)
    const userPrompt = buildUserPrompt(items)

    const response = await fetch(
      'https://api.groq.com/openai/v1/chat/completions',
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${groqApiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: 'llama-3.3-70b-versatile',
          messages: [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: userPrompt },
          ],
          temperature: 0.3,
          max_completion_tokens: 2048,
          response_format: { type: 'json_object' },
        }),
      }
    )

    if (!response.ok) {
      const error = await response.text()
      throw new Error(`Groq API error: ${response.status} - ${error}`)
    }

    const completion = await response.json()
    const scheduleJson = JSON.parse(
      completion.choices[0].message.content
    )

    return new Response(JSON.stringify(scheduleJson), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
})
```

### Pattern 2: Flutter Edge Function Invocation

**What:** Calling the Edge Function from Flutter using `supabase.functions.invoke()`.

**When to use:** Any client-side call to a Supabase Edge Function.

**Example:**

```dart
// Source: supabase.com/docs/reference/dart/functions-invoke
class PlannerRepository {
  PlannerRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<GeneratedSchedule> generateSchedule({
    required List<PlannableItem> items,
    required EnergyPattern energyPattern,
    String? constraints,
  }) async {
    final response = await _client.functions.invoke(
      'generate-schedule',
      body: {
        'items': items.map((i) => i.toJson()).toList(),
        'energyPattern': energyPattern.toJson(),
        if (constraints != null) 'constraints': constraints,
      },
    );

    if (response.status != 200) {
      throw Exception('Schedule generation failed: ${response.data}');
    }

    return GeneratedSchedule.fromJson(response.data as Map<String, dynamic>);
  }
}
```

### Pattern 3: Drag-to-Reschedule with Snap

**What:** LongPressDraggable blocks on a vertical timeline that snap to 15-minute grid positions.

**When to use:** When users need to reorder or reposition items in a time-based layout.

**Example:**

```dart
// Snap logic for 15-minute intervals
// Each 15 minutes = a fixed pixel height (e.g., 20px per 15 min = 80px per hour)

const double pixelsPerMinute = 80.0 / 60.0; // ~1.33 px/min
const int snapMinutes = 15;
const double snapHeight = pixelsPerMinute * snapMinutes; // ~20px

int snapToNearest15(double yOffset, double timelineTop) {
  final relativeY = yOffset - timelineTop;
  final totalMinutes = relativeY / pixelsPerMinute;
  final snappedMinutes = (totalMinutes / snapMinutes).round() * snapMinutes;
  final startHour = 6; // 6 AM
  return startHour * 60 + snappedMinutes; // Returns minutes from midnight
}

// In widget tree:
LongPressDraggable<ScheduleBlock>(
  axis: Axis.vertical,
  data: block,
  feedback: Material(
    elevation: 8,
    borderRadius: BorderRadius.circular(12),
    child: SizedBox(
      width: cardWidth,
      height: block.durationMinutes * pixelsPerMinute,
      child: TimeBlockCard(block: block, isDragging: true),
    ),
  ),
  childWhenDragging: Opacity(
    opacity: 0.3,
    child: TimeBlockCard(block: block, isGhost: true),
  ),
  child: TimeBlockCard(block: block),
)
```

### Anti-Patterns to Avoid

- **Storing Groq API key in client code:** The key MUST only live in Supabase Edge Function secrets, never in Flutter. The existing pattern in CLAUDE.md confirms this.
- **Using groq-sdk npm package in Edge Function:** Raw `fetch()` is simpler, avoids npm import overhead in Deno, and the API is OpenAI-compatible with a straightforward request/response format.
- **Building a custom scheduler fallback:** CONTEXT.md explicitly states "no fallback scheduling logic in v1." If Groq fails, show error + retry.
- **Using Draggable instead of LongPressDraggable:** The timeline is in a scrollable list. `Draggable` would conflict with scroll gestures. `LongPressDraggable` requires a deliberate long-press to initiate drag, avoiding accidental drags while scrolling.
- **Resizing blocks via drag:** CONTEXT.md explicitly states "no block resizing in v1 -- move only."

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| AI schedule optimization | Custom scheduling algorithm | Groq LLM with structured prompt | LLM handles complex heuristics (energy matching, task ordering, gap filling) better than hand-coded rules |
| CORS handling | Custom header management | Supabase `_shared/cors.ts` pattern | Standard boilerplate, prevents subtle bugs with preflight requests |
| Edge Function auth | Custom JWT validation | Supabase built-in auth header forwarding | `supabase.functions.invoke()` automatically attaches the user's JWT; Edge Function can read it via `req.headers.get('Authorization')` |
| Drag-and-drop | Custom pan gesture tracker | Flutter's `LongPressDraggable` + `DragTarget` | Built-in hit testing, feedback widget, data passing -- handles edge cases (cancelled drag, multi-touch) |

**Key insight:** The AI scheduling is the core value -- everything else is plumbing. Keep the Edge Function focused on prompt engineering and the Flutter side focused on clean timeline rendering.

## Common Pitfalls

### Pitfall 1: Missing CORS Headers on Error Responses

**What goes wrong:** Edge Function returns error without CORS headers; browser blocks the error from being read by Flutter web (if ever used) or shows generic network error.
**Why it happens:** Developers add CORS to success responses but forget the catch block.
**How to avoid:** Spread `...corsHeaders` into EVERY `new Response()`, including error responses. The boilerplate pattern above handles this correctly.
**Warning signs:** "CORS error" in browser console, generic "request failed" errors in Flutter.

### Pitfall 2: LongPressDraggable Inside ScrollView Conflicts

**What goes wrong:** Drag gesture fights with the scroll gesture; user can't scroll the timeline or can't initiate drag.
**Why it happens:** Both `LongPressDraggable` and `SingleChildScrollView` compete for vertical gesture recognition.
**How to avoid:** LongPressDraggable's long-press delay (default 500ms) naturally disambiguates from scroll. Do NOT set `delay: Duration.zero`. If still problematic, wrap the scrollable area and set `physics: ClampingScrollPhysics()` to reduce bounce interference. The `axis: Axis.vertical` constraint on the draggable helps too.
**Warning signs:** Intermittent drag failures, timeline not scrolling smoothly.

### Pitfall 3: Groq JSON Mode Requires System Prompt Instruction

**What goes wrong:** Setting `response_format: { type: 'json_object' }` but the LLM returns malformed or free-text content.
**Why it happens:** Groq's JSON mode requires that the system or user prompt explicitly instructs the model to output JSON. Without this instruction, the model may ignore the format directive.
**How to avoid:** Always include "Respond with valid JSON" or similar instruction in the system prompt when using `json_object` mode.
**Warning signs:** JSON parse errors in the Edge Function's response handler.

### Pitfall 4: Groq Free Tier Rate Limits

**What goes wrong:** Users get 429 errors during schedule generation.
**Why it happens:** Free tier: 30 RPM, 1,000 RPD for `llama-3.3-70b-versatile`. A single user regenerating frequently could approach limits; multiple test users could exceed daily cap.
**How to avoid:** Cache generated schedules in the database. Only call Groq on explicit "Plan My Day" or "Regenerate" actions. Display the cached schedule on subsequent visits. The `generated_schedules` table handles this.
**Warning signs:** 429 HTTP status in Edge Function logs.

### Pitfall 5: Push-Down Displacement Complexity

**What goes wrong:** Overlap detection and push-down logic gets buggy with edge cases (moving to the end of day, multiple overlapping blocks, blocks near 10 PM boundary).
**Why it happens:** Naive overlap detection doesn't handle cascading pushes (block A pushes B, which now overlaps C).
**How to avoid:** After a drop, sort all blocks by start time. Walk through sequentially: if any block overlaps the previous, push its start to after the previous block's end. This handles cascading naturally. Clamp the last block's end to 10 PM (22:00). If a block can't fit, show a warning.
**Warning signs:** Blocks visually overlapping, blocks pushed past 10 PM.

### Pitfall 6: Edge Function Cold Start

**What goes wrong:** First invocation after inactivity takes 1-3 seconds, making it feel slow.
**Why it happens:** Supabase Edge Functions have cold start latency when the function hasn't been invoked recently.
**How to avoid:** The shimmer skeleton loading state handles perceived latency well. Groq inference itself is very fast (~0.5-1s for this payload size). Combined cold start + inference should be under 3-4 seconds. No mitigation needed beyond the shimmer UX.
**Warning signs:** Inconsistent response times (fast on repeated calls, slow after idle periods).

## Code Examples

### Database Migration: Planner Tables

```sql
-- supabase/migrations/00002_create_planner_tables.sql

-- Plannable items: standalone items users create for scheduling
create table public.plannable_items (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references auth.users on delete cascade,
  title text not null,
  duration_minutes integer not null check (duration_minutes in (15, 30, 45, 60, 90, 120)),
  energy_level text not null check (energy_level in ('high', 'medium', 'low')),
  plan_date date not null default current_date,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.plannable_items enable row level security;

create policy "Users can view own plannable items"
  on public.plannable_items for select
  using ((select auth.uid()) = user_id);

create policy "Users can insert own plannable items"
  on public.plannable_items for insert
  with check ((select auth.uid()) = user_id);

create policy "Users can update own plannable items"
  on public.plannable_items for update
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "Users can delete own plannable items"
  on public.plannable_items for delete
  using ((select auth.uid()) = user_id);

-- Generated schedules: cached AI-generated daily plans
create table public.generated_schedules (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references auth.users on delete cascade,
  plan_date date not null,
  schedule_blocks jsonb not null default '[]'::jsonb,
  constraints_text text,
  created_at timestamptz default now(),
  unique(user_id, plan_date)
);

alter table public.generated_schedules enable row level security;

create policy "Users can view own schedules"
  on public.generated_schedules for select
  using ((select auth.uid()) = user_id);

create policy "Users can insert own schedules"
  on public.generated_schedules for insert
  with check ((select auth.uid()) = user_id);

create policy "Users can update own schedules"
  on public.generated_schedules for update
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "Users can delete own schedules"
  on public.generated_schedules for delete
  using ((select auth.uid()) = user_id);

-- Index for fast lookups by user and date
create index idx_plannable_items_user_date on public.plannable_items(user_id, plan_date);
create index idx_generated_schedules_user_date on public.generated_schedules(user_id, plan_date);
```

### Domain Models

```dart
// lib/features/planner/domain/plannable_item_model.dart

enum EnergyLevel { high, medium, low }

class PlannableItem {
  final String id;
  final String userId;
  final String title;
  final int durationMinutes;     // 15, 30, 45, 60, 90, or 120
  final EnergyLevel energyLevel;
  final DateTime planDate;
  final DateTime createdAt;

  const PlannableItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.durationMinutes,
    required this.energyLevel,
    required this.planDate,
    required this.createdAt,
  });

  factory PlannableItem.fromJson(Map<String, dynamic> json) {
    return PlannableItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      durationMinutes: json['duration_minutes'] as int,
      energyLevel: EnergyLevel.values.byName(json['energy_level'] as String),
      planDate: DateTime.parse(json['plan_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'duration_minutes': durationMinutes,
    'energy_level': energyLevel.name,
    'plan_date': planDate.toIso8601String().split('T').first,
  };
}
```

```dart
// lib/features/planner/domain/schedule_block_model.dart

class ScheduleBlock {
  final String itemId;
  final String title;
  final int startMinute;       // Minutes from midnight (e.g., 540 = 9:00 AM)
  final int durationMinutes;
  final EnergyLevel energyLevel;

  const ScheduleBlock({
    required this.itemId,
    required this.title,
    required this.startMinute,
    required this.durationMinutes,
    required this.energyLevel,
  });

  int get endMinute => startMinute + durationMinutes;

  // Convert 6:00 AM start offset to pixel position
  double get topOffset => (startMinute - 360) * pixelsPerMinute; // 360 = 6 AM
  double get height => durationMinutes * pixelsPerMinute;

  static const double pixelsPerMinute = 80.0 / 60.0; // 80px per hour

  factory ScheduleBlock.fromJson(Map<String, dynamic> json) {
    return ScheduleBlock(
      itemId: json['item_id'] as String,
      title: json['title'] as String,
      startMinute: json['start_minute'] as int,
      durationMinutes: json['duration_minutes'] as int,
      energyLevel: EnergyLevel.values.byName(json['energy_level'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'item_id': itemId,
    'title': title,
    'start_minute': startMinute,
    'duration_minutes': durationMinutes,
    'energy_level': energyLevel.name,
  };

  ScheduleBlock copyWith({int? startMinute}) {
    return ScheduleBlock(
      itemId: itemId,
      title: title,
      startMinute: startMinute ?? this.startMinute,
      durationMinutes: durationMinutes,
      energyLevel: energyLevel,
    );
  }
}
```

### Edge Function: Shared CORS

```typescript
// supabase/functions/_shared/cors.ts
// Source: supabase.com/docs/guides/functions/cors

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}
```

### Prompt Engineering for Schedule Generation

```typescript
// Inside the Edge Function

function buildSystemPrompt(
  energyPattern: { peak_hours: number[]; low_hours: number[] },
  constraints?: string
): string {
  const peakStr = energyPattern.peak_hours
    .map((h) => `${h > 12 ? h - 12 : h}${h >= 12 ? 'PM' : 'AM'}`)
    .join(', ')
  const lowStr = energyPattern.low_hours
    .map((h) => `${h > 12 ? h - 12 : h}${h >= 12 ? 'PM' : 'AM'}`)
    .join(', ')

  let prompt = `You are a daily schedule optimizer. Given a list of items with titles, durations, and energy levels, create an optimized daily schedule.

Rules:
1. Schedule items between 6:00 AM (360 min) and 10:00 PM (1320 min).
2. HIGH energy items should be placed during peak hours: ${peakStr}.
3. LOW energy items should be placed during low-energy hours: ${lowStr}.
4. MEDIUM energy items can go in any remaining slots.
5. Leave reasonable gaps (15-30 min) between items.
6. Do not overlap items.
7. All times are in minutes from midnight (e.g., 9:00 AM = 540, 2:00 PM = 840).

Respond with valid JSON in this exact format:
{
  "blocks": [
    {
      "item_id": "<id from input>",
      "title": "<title from input>",
      "start_minute": <number>,
      "duration_minutes": <number>,
      "energy_level": "<high|medium|low>"
    }
  ]
}`

  if (constraints) {
    prompt += `\n\nAdditional user constraints: ${constraints}`
  }

  return prompt
}

function buildUserPrompt(
  items: Array<{
    id: string
    title: string
    duration_minutes: number
    energy_level: string
  }>
): string {
  const itemList = items
    .map(
      (i) =>
        `- ID: ${i.id}, Title: "${i.title}", Duration: ${i.duration_minutes} min, Energy: ${i.energy_level}`
    )
    .join('\n')

  return `Schedule these items for today:\n${itemList}`
}
```

### Timeline Pixel Math

```dart
// Constants for timeline layout
class TimelineConstants {
  static const int startHour = 6;     // 6 AM
  static const int endHour = 22;      // 10 PM
  static const int totalHours = endHour - startHour; // 16 hours
  static const double hourHeight = 80.0;
  static const double totalHeight = totalHours * hourHeight; // 1280px
  static const double pixelsPerMinute = hourHeight / 60.0;   // ~1.33px
  static const int snapMinutes = 15;
  static const double snapHeight = snapMinutes * pixelsPerMinute; // ~20px

  /// Convert a minute-from-midnight value to a Y pixel offset.
  static double minuteToY(int minute) {
    return (minute - startHour * 60) * pixelsPerMinute;
  }

  /// Convert a Y pixel offset to the nearest 15-minute mark (in minutes from midnight).
  static int yToSnappedMinute(double y) {
    final rawMinutes = (y / pixelsPerMinute).round() + startHour * 60;
    return (rawMinutes / snapMinutes).round() * snapMinutes;
  }

  /// Determine the energy zone for a given hour.
  static EnergyZone getZone(int hour, EnergyPattern pattern) {
    if (pattern.peakHours.contains(hour)) return EnergyZone.peak;
    if (pattern.lowHours.contains(hour)) return EnergyZone.low;
    return EnergyZone.regular;
  }
}

enum EnergyZone { peak, low, regular }
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| supabase functions serve (manual) | Dashboard editor for quick prototypes | 2025 | Can use either; CLI preferred for version-controlled code |
| Custom CORS per function | `_shared/cors.ts` import pattern | Supabase docs standard | Prevents CORS bugs across multiple functions |
| groq-sdk npm package in Deno | Raw `fetch()` to OpenAI-compatible endpoint | Always viable | Simpler, no npm import overhead, fewer dependencies |
| Groq `json_object` mode | `json_schema` structured output (limited models) | July 2025 | `json_schema` only supported on Llama 4 / GPT-OSS models, NOT on `llama-3.3-70b-versatile`. Use `json_object` mode instead. |

**Deprecated/outdated:**
- Dart Edge (writing Edge Functions in Dart): Not actively maintained due to WASM breaking changes. Use TypeScript.
- `supabase/functions/_shared/cors.ts` with old import path: For supabase_flutter >= v2.95.0, can import from `@supabase/supabase-js/cors` directly, but manual file is safer and more portable.

## Open Questions

1. **Groq model availability on free tier**
   - What we know: `llama-3.3-70b-versatile` is available with 30 RPM, 1K RPD, 12K TPM, 100K TPD limits
   - What's unclear: Whether Groq will deprecate older Llama models; newer Llama 4 models may be available but with different limits
   - Recommendation: Use `llama-3.3-70b-versatile` now. If it gets deprecated, swap to whatever the current recommended versatile model is -- the raw fetch approach makes this a one-line change.

2. **Schedule caching strategy**
   - What we know: Context says caching is Claude's discretion
   - Recommendation: Cache in `generated_schedules` table with `unique(user_id, plan_date)`. On "Plan My Day", upsert (replace) the cache. On subsequent screen visits, load from cache. On "Regenerate", call Groq and upsert again. This saves API quota and gives instant load on revisit.

3. **Supabase Edge Function deployment without Supabase CLI**
   - What we know: STATE.md notes "Flutter SDK not installed on machine" -- Supabase CLI may also not be installed
   - What's unclear: Whether the developer has Supabase CLI set up locally
   - Recommendation: Create the function files in the correct directory structure. Deployment can be done via Dashboard editor (paste code) or CLI when available. Document both paths.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test + mockito (already in project) |
| Config file | pubspec.yaml (dev_dependencies section) |
| Quick run command | `flutter test test/unit/planner/` |
| Full suite command | `flutter test` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PLAN-01 | PlannerRepository.generateSchedule calls Edge Function and parses response | unit | `flutter test test/unit/planner/planner_repository_test.dart -x` | No -- Wave 0 |
| PLAN-01 | PlannableItem model serialization roundtrip | unit | `flutter test test/unit/planner/plannable_item_model_test.dart -x` | No -- Wave 0 |
| PLAN-01 | ScheduleBlock model serialization roundtrip | unit | `flutter test test/unit/planner/schedule_block_model_test.dart -x` | No -- Wave 0 |
| PLAN-02 | TimelineConstants.minuteToY and yToSnappedMinute math | unit | `flutter test test/unit/planner/timeline_constants_test.dart -x` | No -- Wave 0 |
| PLAN-02 | PlannerScreen renders timeline with blocks | widget | `flutter test test/widget/planner/planner_screen_test.dart -x` | No -- Wave 0 |
| PLAN-03 | Snap logic rounds to nearest 15-minute increment | unit | `flutter test test/unit/planner/timeline_constants_test.dart -x` | No -- Wave 0 |
| PLAN-03 | Push-down displacement resolves overlaps correctly | unit | `flutter test test/unit/planner/schedule_overlap_test.dart -x` | No -- Wave 0 |

### Sampling Rate

- **Per task commit:** `flutter test test/unit/planner/`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `test/unit/planner/plannable_item_model_test.dart` -- covers PLAN-01 model serialization
- [ ] `test/unit/planner/schedule_block_model_test.dart` -- covers PLAN-01 block serialization
- [ ] `test/unit/planner/planner_repository_test.dart` -- covers PLAN-01 Edge Function invocation (mocked)
- [ ] `test/unit/planner/timeline_constants_test.dart` -- covers PLAN-02/PLAN-03 pixel math and snap logic
- [ ] `test/unit/planner/schedule_overlap_test.dart` -- covers PLAN-03 push-down displacement
- [ ] `test/widget/planner/planner_screen_test.dart` -- covers PLAN-02 timeline rendering

## Sources

### Primary (HIGH confidence)

- [Supabase Edge Functions Docs](https://supabase.com/docs/guides/functions) -- function structure, Deno.serve pattern, secrets, deployment
- [Supabase Edge Functions CORS Guide](https://supabase.com/docs/guides/functions/cors) -- shared CORS pattern, preflight handling
- [Supabase Dart functions-invoke Reference](https://supabase.com/docs/reference/dart/functions-invoke) -- Flutter SDK invocation API
- [Supabase Edge Functions Development Environment](https://supabase.com/docs/guides/functions/development-environment) -- file structure, _shared convention, local development
- [Supabase Environment Variables / Secrets](https://supabase.com/docs/guides/functions/secrets) -- Deno.env.get, CLI secrets management
- [Groq API Reference](https://console.groq.com/docs/api-reference) -- chat completions endpoint, request/response format
- [Groq Rate Limits](https://console.groq.com/docs/rate-limits) -- free tier limits per model
- [Flutter LongPressDraggable API](https://api.flutter.dev/flutter/widgets/LongPressDraggable-class.html) -- axis constraint, callbacks, feedback widget
- [Flutter Drag a UI Element Cookbook](https://docs.flutter.dev/cookbook/effects/drag-a-widget) -- DragTarget + Draggable pattern
- Existing codebase: `profile_model.dart`, `profile_repository.dart`, `app_router.dart`, `energy_prefs_picker.dart`, `app_shell.dart`, `color_schemes.dart`

### Secondary (MEDIUM confidence)

- [Groq Text Generation Docs](https://console.groq.com/docs/text-chat) -- model IDs, temperature, JSON mode usage
- [Groq Structured Outputs Docs](https://console.groq.com/docs/structured-outputs) -- json_schema vs json_object mode, supported models
- [nikofischer.com Supabase CORS Fix Guide](https://nikofischer.com/supabase-edge-functions-cors-error-fix) -- CORS error patterns and fixes

### Tertiary (LOW confidence)

- [Zilgist Groq Free Tier Analysis](https://www.zilgist.com/2026/02/groq-api-free-tier-rate-limits-best.html) -- community analysis of rate limits (verify against official docs)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all libraries already in the project; Groq API is well-documented and OpenAI-compatible
- Architecture: HIGH -- follows established project patterns (Clean Architecture, Riverpod, Supabase); Edge Function structure is documented by Supabase
- Pitfalls: HIGH -- CORS, gesture conflicts, JSON mode requirements are well-documented issues
- Drag-and-drop snap logic: MEDIUM -- custom implementation needed; no exact Flutter pattern exists for 15-minute grid snap on vertical timeline, but the building blocks (LongPressDraggable, DragTarget, pixel math) are well understood
- Groq rate limits: MEDIUM -- verified against official docs but limits can change; the STATE.md blocker note about "14,400 req/day" appears to be outdated (current free tier is 1K RPD for the 70B model)

**Research date:** 2026-03-18
**Valid until:** 2026-04-17 (30 days -- Groq limits may shift, but core patterns are stable)
