# Phase 2: Task Management - Research

**Researched:** 2026-03-18
**Domain:** Flutter CRUD with Supabase backend, recurring task scheduling, full-text search
**Confidence:** HIGH

## Summary

Phase 2 implements full task CRUD (create, read, update, delete), user-created color-coded categories, filtering/searching, and recurring task scheduling. The existing codebase establishes clear patterns: MVVM with `data/` (repository), `domain/` (models), `presentation/` (screens + providers + widgets). The project uses Riverpod 3.x (`flutter_riverpod: ^3.3.1`), but Phase 1 code uses `Notifier` (sync) and `FutureProvider` patterns rather than `AsyncNotifier`. For consistency with the existing codebase, Phase 2 should follow the same patterns already established -- using `AsyncNotifierProvider` for task list state that needs mutation methods (CRUD), while keeping repositories as simple `Provider` instances.

The Supabase backend needs three new tables (`tasks`, `categories`, `recurrence_rules`) with RLS policies following the pattern established in the `00001_create_profiles.sql` migration. Full-text search uses PostgreSQL's native `tsvector`/`tsquery` with a generated column and GIN index, queried via Supabase Dart SDK's `.textSearch()` method. Recurring tasks use a simple approach: store recurrence rules in a dedicated table and pre-generate task instances for the next 2 weeks, with a Supabase Edge Function or database function to generate more as time passes.

**Primary recommendation:** Build the data layer (migration + models + repository) first, then the state management layer (providers), then the UI layer (screens + widgets), following the exact patterns from Phase 1's profile feature.

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions
- Card-based layout in the main task list (matches warm/friendly app vibe)
- Each card shows: title, priority badge (P1-P4 with color coding), category chip, deadline chip, completion checkbox
- Cards grouped by date sections: "Today", "Tomorrow", "This Week", "Later"
- Swipe right to complete, swipe left to delete (with undo snackbar)
- Completed tasks move to a "Completed" section at the bottom (collapsible)
- FAB on task list screen opens a bottom sheet for quick creation
- Bottom sheet shows: title field, priority selector (P1-P4 chips), deadline date picker -- minimum viable creation in 3 taps
- "More details" expands to full-screen form with: description, category selector, recurrence settings
- Edit mode reuses the full-screen form layout
- Delete available via swipe or from the edit screen with confirmation dialog
- Fully user-created categories (no pre-defined defaults)
- Each category has a name and color chosen from 10 preset colors (Material 3 palette-derived)
- Categories display as small colored chips on task cards
- Tasks without a category show no chip (clean default state)
- Category management accessible from a dedicated screen (reachable from task filter bar or settings)
- Category CRUD: create, rename, recolor, delete (with "reassign or remove from tasks" option on delete)
- Recurrence options: daily, weekly (select days), monthly (select date), custom interval (every N days)
- Instances pre-generated for the next 2 weeks; more auto-generated as time passes
- Recurring tasks show a subtle recurrence label on the card
- Editing a recurring task prompts: "This instance only" or "All future instances"
- Deleting a recurring task prompts: "This instance only" or "Entire series"
- Completing one instance does not affect others -- each instance is independent once generated

### Claude's Discretion
- Exact card elevation, padding, and spacing values
- Priority color mapping (P1-P4 specific hex values -- should fit amber/teal theme)
- Animation for task completion (checkbox feedback)
- Search bar placement and behavior (inline vs expandable)
- Filter UI design (chips bar, dropdown, or bottom sheet)
- Supabase table schema design for tasks, categories, and recurrence rules
- Full-text search implementation approach (Supabase text search vs client-side)
- Date section header styling

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope

</user_constraints>

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| TASK-01 | User can create, read, update, and delete tasks with title, description, priority (P1-P4), category, and deadline | Supabase schema design, repository pattern from Phase 1, AsyncNotifier CRUD pattern, bottom sheet quick-create and full-screen form patterns |
| TASK-03 | User can filter tasks by priority, category, and date range, and search tasks with full-text search | PostgreSQL tsvector/tsquery with GIN index, Supabase `.textSearch()` Dart SDK method, filter chip UI pattern |
| TASK-04 | User can create, edit, and assign color-coded categories/labels to tasks | Separate categories table with FK relationship, 10 preset Material 3 colors, category management screen |
| TASK-05 | User can set tasks to recur on daily, weekly, monthly, or custom intervals | Recurrence rules table, instance pre-generation (2-week window), "this instance" vs "all future" edit/delete UX |

</phase_requirements>

## Standard Stack

### Core (Already in pubspec.yaml)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter_riverpod | ^3.3.1 | State management | Already in project; AsyncNotifier for CRUD state |
| supabase_flutter | ^2.12.0 | Backend SDK | Already in project; provides `.textSearch()`, CRUD, auth |
| go_router | ^17.1.0 | Navigation | Already in project; add sub-routes for task screens |

### New Dependencies Required
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| flutter_slidable | ^4.0.3 | Swipe actions on task cards | Bidirectional swipe (complete/delete) with customizable actions |
| intl | ^0.19.0 | Date formatting | Format deadlines, date section headers ("Today", "Tomorrow", etc.) |
| uuid | ^4.5.1 | Client-side UUID generation | Generate task IDs client-side for optimistic UI |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| flutter_slidable | Dismissible (built-in) | Dismissible removes the widget; flutter_slidable reveals action panes without removing, better for "complete" action that transforms rather than removes |
| intl | timeago | timeago is relative ("2 hours ago"); intl gives precise formatting needed for date sections |
| uuid (client-side) | Server-generated UUIDs | Client-side UUIDs enable optimistic UI; server UUIDs require waiting for response |

**Installation:**
```bash
flutter pub add flutter_slidable intl uuid
```

## Architecture Patterns

### Recommended Project Structure
```
lib/features/tasks/
  data/
    task_repository.dart          # Supabase CRUD for tasks
    category_repository.dart      # Supabase CRUD for categories
  domain/
    task_model.dart               # Task, Priority enum, TaskStatus enum
    category_model.dart           # Category model with color
    recurrence_model.dart         # RecurrenceRule, RecurrenceType enum
  presentation/
    providers/
      task_provider.dart          # AsyncNotifier<List<Task>> for task list
      task_filter_provider.dart   # StateProvider for active filters
      category_provider.dart      # AsyncNotifier<List<Category>> for categories
    screens/
      task_list_screen.dart       # Main task list with date sections
      task_form_screen.dart       # Full-screen create/edit form
      category_management_screen.dart  # Category CRUD screen
    widgets/
      task_card.dart              # Card with swipe actions
      task_quick_create_sheet.dart # Bottom sheet for quick creation
      priority_badge.dart         # P1-P4 colored badge widget
      category_chip.dart          # Colored category chip widget
      deadline_chip.dart          # Deadline display chip
      recurrence_label.dart       # "Daily", "Mon/Wed/Fri" label
      task_filter_bar.dart        # Filter chips bar
      date_section_header.dart    # "Today", "Tomorrow", etc.
```

### Pattern 1: Repository Pattern (Matching Phase 1)
**What:** Thin wrapper around Supabase client, accepts optional client for DI in tests.
**When to use:** All data access. Never call Supabase directly from providers or UI.
**Example:**
```dart
// Source: Existing profile_repository.dart pattern
class TaskRepository {
  TaskRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;
  final SupabaseClient _client;

  Future<List<Task>> getTasks(String userId, {TaskFilter? filter}) async {
    var query = _client.from('tasks').select('*, categories(*)').eq('user_id', userId);
    if (filter?.priority != null) query = query.eq('priority', filter!.priority!.index);
    if (filter?.categoryId != null) query = query.eq('category_id', filter!.categoryId!);
    // ... additional filters
    final data = await query.order('deadline', ascending: true);
    return data.map((json) => Task.fromJson(json)).toList();
  }

  Future<Task> createTask(Task task) async {
    final data = await _client.from('tasks').insert(task.toJson()).select().single();
    return Task.fromJson(data);
  }

  Future<void> updateTask(Task task) async {
    await _client.from('tasks').update(task.toJson()).eq('id', task.id);
  }

  Future<void> deleteTask(String taskId) async {
    await _client.from('tasks').delete().eq('id', taskId);
  }

  Future<List<Task>> searchTasks(String userId, String query) async {
    final data = await _client
        .from('tasks')
        .select('*, categories(*)')
        .eq('user_id', userId)
        .textSearch('fts', "'${query.replaceAll(' ', "' & '")}'", config: 'english');
    return data.map((json) => Task.fromJson(json)).toList();
  }
}
```

### Pattern 2: AsyncNotifier for CRUD State
**What:** Riverpod AsyncNotifier managing task list with loading/error/data states.
**When to use:** Any provider that fetches data async and exposes mutation methods.
**Example:**
```dart
// Follows existing Notifier pattern from auth_provider.dart but async
final taskListProvider = AsyncNotifierProvider<TaskListNotifier, List<Task>>(
  TaskListNotifier.new,
);

class TaskListNotifier extends AsyncNotifier<List<Task>> {
  @override
  FutureOr<List<Task>> build() async {
    final userId = _getCurrentUserId();
    final repo = ref.read(taskRepositoryProvider);
    return repo.getTasks(userId);
  }

  Future<void> addTask(Task task) async {
    final repo = ref.read(taskRepositoryProvider);
    final created = await repo.createTask(task);
    state = AsyncData([...state.value ?? [], created]);
  }

  Future<void> toggleComplete(String taskId) async {
    // Optimistic update
    final tasks = [...state.value ?? []];
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;
    tasks[index] = tasks[index].copyWith(isCompleted: !tasks[index].isCompleted);
    state = AsyncData(tasks);
    // Sync to server
    final repo = ref.read(taskRepositoryProvider);
    await repo.updateTask(tasks[index]);
  }

  Future<void> deleteTask(String taskId) async {
    final repo = ref.read(taskRepositoryProvider);
    await repo.deleteTask(taskId);
    state = AsyncData([...state.value ?? []]..removeWhere((t) => t.id == taskId));
  }

  String _getCurrentUserId() {
    return Supabase.instance.client.auth.currentUser!.id;
  }
}
```

### Pattern 3: Bottom Sheet Quick Create
**What:** Modal bottom sheet with minimal fields for fast task creation.
**When to use:** FAB tap on task list screen.
**Example:**
```dart
// Source: Flutter official docs + Material 3 bottom sheet guidelines
Future<Task?> showQuickCreateSheet(BuildContext context) {
  return showModalBottomSheet<Task>(
    context: context,
    isScrollControlled: true, // Required for keyboard avoidance
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 8,
      ),
      child: const TaskQuickCreateSheet(),
    ),
  );
}
```

### Pattern 4: flutter_slidable for Swipe Actions
**What:** Bidirectional swipe revealing action panes (complete left, delete right).
**When to use:** Every task card in the list.
**Example:**
```dart
// Source: flutter_slidable 4.0.3 official docs
Slidable(
  key: ValueKey(task.id),
  startActionPane: ActionPane(
    motion: const BehindMotion(),
    children: [
      SlidableAction(
        onPressed: (context) => onComplete(task),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: Icons.check_circle,
        label: 'Complete',
        borderRadius: BorderRadius.circular(16),
      ),
    ],
  ),
  endActionPane: ActionPane(
    motion: const BehindMotion(),
    dismissible: DismissiblePane(onDismissed: () => onDelete(task)),
    children: [
      SlidableAction(
        onPressed: (context) => onDelete(task),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        icon: Icons.delete,
        label: 'Delete',
        borderRadius: BorderRadius.circular(16),
      ),
    ],
  ),
  child: TaskCard(task: task),
)
```

### Pattern 5: Date Section Grouping
**What:** Group tasks by temporal proximity: Today, Tomorrow, This Week, Later.
**When to use:** Main task list display.
**Example:**
```dart
// Utility function for date section assignment
String getDateSection(DateTime? deadline) {
  if (deadline == null) return 'No Deadline';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final endOfWeek = today.add(Duration(days: 7 - today.weekday));

  if (deadline.isBefore(tomorrow)) return 'Today';
  if (deadline.isBefore(tomorrow.add(const Duration(days: 1)))) return 'Tomorrow';
  if (deadline.isBefore(endOfWeek.add(const Duration(days: 1)))) return 'This Week';
  return 'Later';
}
```

### Anti-Patterns to Avoid
- **Calling Supabase from widgets directly:** Always go through repository -> provider -> widget. Never `Supabase.instance.client.from('tasks')...` in a build method.
- **Using StateNotifier for new code:** The project uses Riverpod 3.x. New providers should use `Notifier`/`AsyncNotifier`, not the legacy `StateNotifier`. (Note: existing Phase 1 code uses `Notifier` which is correct for sync state; use `AsyncNotifier` for async CRUD.)
- **Storing all recurring instances forever:** Only pre-generate 2 weeks of instances. Generate more on demand.
- **Full-text search without GIN index:** Always create the GIN index on the `fts` column; without it, every query scans every row.
- **Blocking UI on server response for common actions:** Use optimistic updates for toggle-complete and delete, with rollback on error.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Swipe actions on list items | Custom GestureDetector + AnimationController | flutter_slidable 4.0.3 | Handles gesture conflicts with scrolling, animation curves, auto-close on scroll, accessibility |
| Full-text search | Client-side string matching / LIKE queries | PostgreSQL tsvector + Supabase `.textSearch()` | Stemming, ranking, language-aware tokenization, GIN index performance |
| Date formatting | Manual string concatenation | intl DateFormat | Handles locale-aware formatting, relative dates, timezone edge cases |
| UUID generation | Timestamp-based IDs or auto-increment | uuid package | Globally unique, no collisions in offline/optimistic scenarios |
| Recurrence date calculation | Manual date math | Store rules + generate instances with PostgreSQL interval arithmetic | Handles month-end edge cases, leap years, DST transitions |
| Modal bottom sheet keyboard handling | Manual padding calculation | `isScrollControlled: true` + `MediaQuery.viewInsets.bottom` | Built-in Flutter mechanism, handles all keyboard show/hide transitions |

**Key insight:** Swipe gestures and scrolling conflict resolution is notoriously tricky. flutter_slidable (a Flutter Favorite with 2.8K stars) handles all edge cases including auto-closing when other slidables open, closing on scroll, and gesture threshold tuning.

## Common Pitfalls

### Pitfall 1: Keyboard Overlapping Bottom Sheet Form Fields
**What goes wrong:** The soft keyboard covers the title input in the quick-create bottom sheet.
**Why it happens:** `showModalBottomSheet` defaults to `isScrollControlled: false`, which does not resize for the keyboard.
**How to avoid:** Always set `isScrollControlled: true` and add `padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom)` to the bottom sheet content.
**Warning signs:** Text field not visible when keyboard opens; user cannot see what they type.

### Pitfall 2: RLS Policies Blocking Supabase Queries Silently
**What goes wrong:** Queries return empty results instead of the expected data.
**Why it happens:** RLS is enabled on the table but policies are missing or misconfigured. Supabase does not throw an error -- it silently filters rows.
**How to avoid:** Always create explicit SELECT, INSERT, UPDATE, DELETE policies. Test each operation with the Supabase SQL Editor as the authenticated user. Follow the `(select auth.uid()) = user_id` pattern from Phase 1's profiles migration.
**Warning signs:** CRUD operations succeed (no error) but data does not appear in subsequent reads.

### Pitfall 3: Full-Text Search Returning No Results for Partial Words
**What goes wrong:** Searching "gro" does not find "groceries".
**Why it happens:** PostgreSQL `to_tsquery` requires complete words by default. Prefix matching needs `:*` suffix.
**How to avoid:** Use an RPC function that appends `:*` to the search term for prefix matching: `to_tsquery(prefix || ':*')`. Alternatively, use `websearch` type for more forgiving input parsing.
**Warning signs:** Search works for complete words but fails for typing-in-progress queries.

### Pitfall 4: Optimistic Update State Desync
**What goes wrong:** UI shows a task as completed, but the server update fails, leaving the UI and database out of sync.
**Why it happens:** Optimistic update modifies local state before the server confirms.
**How to avoid:** Wrap server call in try/catch; on failure, revert the optimistic state change and show an error snackbar. Keep a copy of the previous state before mutating.
**Warning signs:** Intermittent data inconsistencies, especially on poor network connections.

### Pitfall 5: go_router `context.go` vs `context.push` Confusion
**What goes wrong:** Navigating to task detail replaces the task list instead of pushing on top, losing the bottom navigation bar.
**Why it happens:** `context.go('/tasks/123')` replaces the navigation stack. `context.push('/tasks/123')` pushes on top.
**How to avoid:** Use `context.push` for detail/edit screens that should show a back button. Use `context.go` only for tab-level navigation. For full-screen forms (create/edit), use `parentNavigatorKey` set to the root navigator to push over the shell.
**Warning signs:** Bottom navigation disappears on detail screens; back button does not return to the list.

### Pitfall 6: Recurring Task Instance Explosion
**What goes wrong:** Database fills with thousands of task instances for a daily recurring task.
**Why it happens:** No limit on how far ahead instances are generated.
**How to avoid:** Only pre-generate instances for a 2-week rolling window. Use a database function or scheduled job to generate the next batch as the window advances.
**Warning signs:** Slow queries, growing storage, large lists of future tasks that the user never sees.

### Pitfall 7: Category Delete Orphaning Tasks
**What goes wrong:** Deleting a category leaves tasks with a dangling `category_id` foreign key.
**Why it happens:** FK constraint without proper ON DELETE behavior.
**How to avoid:** Use `ON DELETE SET NULL` on the FK, which clears the category from tasks when a category is deleted. The UI already handles null categories (no chip displayed). Alternatively, prompt user to reassign before delete.
**Warning signs:** Foreign key constraint errors on category delete, or orphaned references.

## Code Examples

### Supabase Migration: Tasks Table
```sql
-- Source: Supabase docs + existing profiles migration pattern
create table public.categories (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references auth.users on delete cascade,
  name text not null,
  color_index int not null default 0,  -- index into preset color list (0-9)
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table public.tasks (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references auth.users on delete cascade,
  title text not null,
  description text,
  priority int not null default 3,  -- 1=P1(urgent), 2=P2, 3=P3, 4=P4(low)
  category_id uuid references public.categories on delete set null,
  deadline timestamptz,
  is_completed boolean default false,
  completed_at timestamptz,
  recurrence_rule_id uuid,  -- FK added after recurrence_rules table
  parent_task_id uuid references public.tasks on delete cascade,  -- for recurring instances
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  -- Generated full-text search column
  fts tsvector generated always as (
    to_tsvector('english', coalesce(title, '') || ' ' || coalesce(description, ''))
  ) stored
);

create index tasks_fts on public.tasks using gin (fts);
create index tasks_user_id on public.tasks using btree (user_id);
create index tasks_deadline on public.tasks using btree (deadline);
create index tasks_category on public.tasks using btree (category_id);

create table public.recurrence_rules (
  id uuid default gen_random_uuid() primary key,
  task_id uuid not null references public.tasks on delete cascade,  -- the "template" task
  type text not null,  -- 'daily', 'weekly', 'monthly', 'custom'
  interval_days int,   -- for 'custom': every N days
  days_of_week int[],  -- for 'weekly': [1,3,5] = Mon,Wed,Fri (ISO weekday)
  day_of_month int,    -- for 'monthly': which day (1-31)
  created_at timestamptz default now()
);

alter table public.tasks
  add constraint fk_recurrence_rule
  foreign key (recurrence_rule_id) references public.recurrence_rules on delete set null;
```

### Supabase RLS Policies for Tasks
```sql
-- Source: Existing profiles RLS pattern
alter table public.tasks enable row level security;
alter table public.categories enable row level security;
alter table public.recurrence_rules enable row level security;

-- Tasks: user can only access their own
create policy "Users can view own tasks"
  on public.tasks for select using ((select auth.uid()) = user_id);
create policy "Users can insert own tasks"
  on public.tasks for insert with check ((select auth.uid()) = user_id);
create policy "Users can update own tasks"
  on public.tasks for update
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "Users can delete own tasks"
  on public.tasks for delete using ((select auth.uid()) = user_id);

-- Categories: same pattern
create policy "Users can view own categories"
  on public.categories for select using ((select auth.uid()) = user_id);
create policy "Users can insert own categories"
  on public.categories for insert with check ((select auth.uid()) = user_id);
create policy "Users can update own categories"
  on public.categories for update
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "Users can delete own categories"
  on public.categories for delete using ((select auth.uid()) = user_id);

-- Recurrence rules: access through task ownership
create policy "Users can view own recurrence rules"
  on public.recurrence_rules for select
  using (exists (select 1 from public.tasks where tasks.id = recurrence_rules.task_id and tasks.user_id = (select auth.uid())));
create policy "Users can insert own recurrence rules"
  on public.recurrence_rules for insert
  with check (exists (select 1 from public.tasks where tasks.id = recurrence_rules.task_id and tasks.user_id = (select auth.uid())));
create policy "Users can update own recurrence rules"
  on public.recurrence_rules for update
  using (exists (select 1 from public.tasks where tasks.id = recurrence_rules.task_id and tasks.user_id = (select auth.uid())))
  with check (exists (select 1 from public.tasks where tasks.id = recurrence_rules.task_id and tasks.user_id = (select auth.uid())));
create policy "Users can delete own recurrence rules"
  on public.recurrence_rules for delete
  using (exists (select 1 from public.tasks where tasks.id = recurrence_rules.task_id and tasks.user_id = (select auth.uid())));
```

### Full-Text Search with Prefix Matching (RPC Function)
```sql
-- Source: Supabase docs on prefix matching
create or replace function search_tasks(p_user_id uuid, p_query text)
returns setof public.tasks as $$
begin
  return query
  select * from public.tasks
  where user_id = p_user_id
    and fts @@ to_tsquery('english', replace(trim(p_query), ' ', ' & ') || ':*')
  order by ts_rank(fts, to_tsquery('english', replace(trim(p_query), ' ', ' & ') || ':*')) desc;
end;
$$ language plpgsql security definer;
```

### Task Model (Dart)
```dart
// Source: Existing profile_model.dart pattern
enum Priority { p1, p2, p3, p4 }

class Task {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final Priority priority;
  final String? categoryId;
  final DateTime? deadline;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? recurrenceRuleId;
  final String? parentTaskId;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Joined data (from select with categories(*))
  final Category? category;

  const Task({ /* ... */ });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: Priority.values[json['priority'] as int? ?? 2],
      categoryId: json['category_id'] as String?,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      recurrenceRuleId: json['recurrence_rule_id'] as String?,
      parentTaskId: json['parent_task_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      category: json['categories'] != null ? Category.fromJson(json['categories'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'title': title,
    'description': description,
    'priority': priority.index,
    'category_id': categoryId,
    'deadline': deadline?.toIso8601String(),
    'is_completed': isCompleted,
    'completed_at': completedAt?.toIso8601String(),
    'recurrence_rule_id': recurrenceRuleId,
    'parent_task_id': parentTaskId,
    'updated_at': DateTime.now().toIso8601String(),
  };

  Task copyWith({ /* ... all fields ... */ });
}
```

### Category Model with Preset Colors
```dart
class Category {
  final String id;
  final String userId;
  final String name;
  final int colorIndex;  // 0-9 index into preset colors
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({ /* ... */ });

  // 10 preset colors derived from Material 3 palette
  // Fits amber/teal theme from color_schemes.dart
  static const List<Color> presetColors = [
    Color(0xFFEF5350), // Red
    Color(0xFFEC407A), // Pink
    Color(0xFFAB47BC), // Purple
    Color(0xFF5C6BC0), // Indigo
    Color(0xFF42A5F5), // Blue
    Color(0xFF26A69A), // Teal
    Color(0xFF66BB6A), // Green
    Color(0xFFFFCA28), // Amber
    Color(0xFFFFA726), // Orange
    Color(0xFF8D6E63), // Brown
  ];

  Color get color => presetColors[colorIndex.clamp(0, 9)];
}
```

### Recurrence Instance Generation (Database Function)
```sql
-- Generate recurring task instances for the next 2 weeks
create or replace function generate_recurring_instances(p_task_id uuid)
returns void as $$
declare
  v_rule recurrence_rules%rowtype;
  v_task tasks%rowtype;
  v_next_date date;
  v_end_date date := current_date + interval '14 days';
  v_last_instance date;
begin
  select * into v_task from tasks where id = p_task_id;
  select * into v_rule from recurrence_rules where task_id = p_task_id;
  if v_rule is null then return; end if;

  -- Find the latest existing instance
  select max(deadline::date) into v_last_instance
  from tasks where parent_task_id = p_task_id;

  v_next_date := coalesce(v_last_instance + 1, v_task.deadline::date);

  while v_next_date <= v_end_date loop
    -- Check if this date matches the recurrence pattern
    if v_rule.type = 'daily' then
      -- Every day: always matches
      null;
    elsif v_rule.type = 'weekly' then
      if not (extract(isodow from v_next_date)::int = any(v_rule.days_of_week)) then
        v_next_date := v_next_date + 1;
        continue;
      end if;
    elsif v_rule.type = 'monthly' then
      if extract(day from v_next_date)::int != v_rule.day_of_month then
        v_next_date := v_next_date + 1;
        continue;
      end if;
    elsif v_rule.type = 'custom' then
      if (v_next_date - v_task.deadline::date) % v_rule.interval_days != 0 then
        v_next_date := v_next_date + 1;
        continue;
      end if;
    end if;

    -- Insert instance if it doesn't already exist
    insert into tasks (user_id, title, description, priority, category_id, deadline, parent_task_id, recurrence_rule_id)
    select v_task.user_id, v_task.title, v_task.description, v_task.priority,
           v_task.category_id, v_next_date::timestamptz, p_task_id, v_rule.id
    where not exists (
      select 1 from tasks where parent_task_id = p_task_id and deadline::date = v_next_date
    );

    v_next_date := v_next_date + 1;
  end loop;
end;
$$ language plpgsql security definer;
```

### go_router Sub-Routes for Tasks
```dart
// Source: Existing app_router.dart pattern + go_router ShellRoute docs
// Inside the ShellRoute routes list, replace the tasks PlaceholderTab:
GoRoute(
  path: '/tasks',
  builder: (context, state) => const TaskListScreen(),
  routes: [
    GoRoute(
      path: 'create',
      parentNavigatorKey: rootNavigatorKey,  // Push over shell (no bottom nav)
      builder: (context, state) => const TaskFormScreen(),
    ),
    GoRoute(
      path: ':id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final taskId = state.pathParameters['id']!;
        return TaskFormScreen(taskId: taskId);
      },
    ),
  ],
),
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| StateNotifier + StateNotifierProvider | Notifier/AsyncNotifier + NotifierProvider/AsyncNotifierProvider | Riverpod 2.0 (2023), emphasized in 3.0 (Sep 2025) | Less boilerplate, built-in AsyncValue handling, exhaustive pattern matching |
| LIKE '%query%' for search | tsvector + GIN index + textSearch() | Supabase SDK 2.x | 5-10x faster, language-aware stemming, ranking support |
| Dismissible widget for swipe | flutter_slidable 4.x | 2023+ | Non-destructive reveal of actions, better scrolling conflict handling |
| Manual Navigator.push | go_router with ShellRoute | go_router 6+ | Declarative routing, deep linking, persistent bottom nav |

**Deprecated/outdated:**
- `StateNotifier`: Still works in Riverpod 3.x but imported from a legacy package; new code should use `Notifier`/`AsyncNotifier`
- `ChangeNotifierProvider`: Deprecated in Riverpod 3.x; use `NotifierProvider` instead (note: existing `AuthNotifier` uses `ChangeNotifier` for GoRouter compatibility, which is a valid exception)

## Open Questions

1. **Supabase pg_cron for Recurring Instance Generation**
   - What we know: Supabase supports pg_cron for scheduled jobs. The `generate_recurring_instances` function needs to run periodically.
   - What's unclear: Whether pg_cron is available on Supabase free tier, or if we need to trigger generation client-side on app open.
   - Recommendation: Generate instances client-side when the task list loads (check if the 2-week window needs extending). Fall back to this approach; pg_cron can be added later as an optimization.

2. **Existing Riverpod Pattern Consistency**
   - What we know: Phase 1 uses `Notifier` (sync) for auth state and `FutureProvider.family` for profile. Phase 2 needs mutable async state (CRUD).
   - What's unclear: Whether to use code generation (`@riverpod` annotation) or manual provider declarations.
   - Recommendation: Use manual `AsyncNotifierProvider` declarations to match Phase 1's explicit style. Code generation can be adopted project-wide in a future refactor.

3. **Full-Text Search Debouncing**
   - What we know: Each keystroke in the search bar could trigger a Supabase query.
   - What's unclear: Best debounce duration for perceived responsiveness.
   - Recommendation: Use a 300ms debounce on the search text field. Display local client-side filtering immediately (title contains) while the server FTS query runs in the background for ranked results.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test + mockito 5.4.4 |
| Config file | None (Flutter default) |
| Quick run command | `flutter test test/unit/tasks/` |
| Full suite command | `flutter test` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TASK-01 | Task CRUD (create, read, update, delete with all fields) | unit | `flutter test test/unit/tasks/task_model_test.dart -x` | Wave 0 |
| TASK-01 | Task repository Supabase calls | unit | `flutter test test/unit/tasks/task_repository_test.dart -x` | Wave 0 |
| TASK-03 | Filter tasks by priority, category, date range | unit | `flutter test test/unit/tasks/task_filter_test.dart -x` | Wave 0 |
| TASK-03 | Full-text search returns matching tasks | unit | `flutter test test/unit/tasks/task_search_test.dart -x` | Wave 0 |
| TASK-04 | Category CRUD (create, rename, recolor, delete) | unit | `flutter test test/unit/tasks/category_model_test.dart -x` | Wave 0 |
| TASK-05 | Recurrence rule model serialization | unit | `flutter test test/unit/tasks/recurrence_model_test.dart -x` | Wave 0 |
| TASK-05 | Recurring instance generation logic | unit | `flutter test test/unit/tasks/recurrence_generator_test.dart -x` | Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test test/unit/tasks/`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/unit/tasks/task_model_test.dart` -- covers TASK-01 model serialization
- [ ] `test/unit/tasks/task_repository_test.dart` -- covers TASK-01 repository (mocked Supabase)
- [ ] `test/unit/tasks/task_filter_test.dart` -- covers TASK-03 filter logic
- [ ] `test/unit/tasks/task_search_test.dart` -- covers TASK-03 search
- [ ] `test/unit/tasks/category_model_test.dart` -- covers TASK-04 model
- [ ] `test/unit/tasks/recurrence_model_test.dart` -- covers TASK-05 model
- [ ] `test/unit/tasks/recurrence_generator_test.dart` -- covers TASK-05 instance generation

## Sources

### Primary (HIGH confidence)
- [Supabase Full-Text Search Guide](https://supabase.com/docs/guides/database/full-text-search) - tsvector setup, GIN index, query patterns
- [Supabase Dart SDK textSearch](https://supabase.com/docs/reference/dart/textsearch) - textSearch API, TextSearchType options
- [Flutter Dismissible Cookbook](https://docs.flutter.dev/cookbook/gestures/dismissible) - Swipe-to-dismiss pattern
- [flutter_slidable pub.dev](https://pub.dev/packages/flutter_slidable) - v4.0.3, ActionPane, motion types
- [Material 3 Bottom Sheets](https://m3.material.io/components/bottom-sheets/guidelines) - Modal bottom sheet guidelines
- [Supabase RLS Docs](https://supabase.com/docs/guides/database/postgres/row-level-security) - Policy structure, auth.uid() helper
- [Riverpod What's New (3.0)](https://riverpod.dev/docs/whats_new) - AsyncNotifier, exhaustive matching
- [go_router ShellRoute](https://pub.dev/documentation/go_router/latest/go_router/ShellRoute-class.html) - Nested navigation, parentNavigatorKey
- Existing codebase: `profile_repository.dart`, `profile_model.dart`, `profile_provider.dart`, `auth_provider.dart`, `app_router.dart` - Established patterns

### Secondary (MEDIUM confidence)
- [Code With Andrea - AsyncNotifier](https://codewithandrea.com/articles/flutter-riverpod-async-notifier/) - CRUD patterns with AsyncNotifier
- [Code With Andrea - go_router go vs push](https://codewithandrea.com/articles/flutter-navigation-gorouter-go-vs-push/) - Navigation behavior differences
- [Supabase RLS Performance](https://www.antstack.com/blog/optimizing-rls-performance-with-supabase/) - Index optimization for `auth.uid()` policies
- [Thoughtbot Recurring Events PostgreSQL](https://thoughtbot.com/blog/recurring-events-and-postgresql) - Interval-based recurrence pattern

### Tertiary (LOW confidence)
- [rrule_plpgsql](https://github.com/sirrodgepodge/rrule_plpgsql) - Pure PL/pgSQL iCalendar RRULE (not needed for our simpler recurrence model, but useful reference)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All libraries verified on pub.dev, existing project patterns confirmed from source code
- Architecture: HIGH - Directly follows established Phase 1 patterns, verified with Supabase docs
- Pitfalls: HIGH - Common patterns well-documented in official docs and community resources
- Recurring tasks: MEDIUM - Schema design is sound but client-side instance generation approach needs runtime validation
- Full-text search: HIGH - Supabase official docs provide complete implementation path

**Research date:** 2026-03-18
**Valid until:** 2026-04-17 (30 days - stable domain, no fast-moving dependencies)
