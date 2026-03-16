# Architecture Research

**Domain:** Cross-platform Flutter productivity app with AI, realtime collaboration, and Supabase backend
**Researched:** 2026-03-16
**Confidence:** HIGH

## Standard Architecture

### System Overview

```
+------------------------------------------------------------------+
|                    PRESENTATION LAYER                              |
|  +----------+  +---------+  +---------+  +---------+  +---------+ |
|  |  Auth    |  |  Tasks  |  | Habits  |  | Planner |  | Boards  | |
|  | Screens  |  | Screens |  | Screens |  | Screens |  | Screens | |
|  +----+-----+  +----+----+  +----+----+  +----+----+  +----+----+ |
|       |              |            |            |            |       |
|  +----+-----+  +----+----+  +----+----+  +----+----+  +----+----+ |
|  |  Auth    |  |  Task   |  | Habit   |  | Planner |  | Board   | |
|  |Controller|  |Controler|  |Controler|  |Controler|  |Controler| |
|  | (Notif.) |  |(AsyncN) |  |(AsyncN) |  |(AsyncN) |  |(AsyncN) | |
|  +----+-----+  +----+----+  +----+----+  +----+----+  +----+----+ |
+-------|--------------|-----------|-----------|-----------|---------+
        |              |           |           |           |
+-------|--------------|-----------|-----------|-----------|---------+
|       v              v           v           v           v         |
|                    DOMAIN LAYER                                    |
|  +----------+  +---------+  +---------+  +---------+  +---------+ |
|  |  Auth    |  |  Task   |  | Habit   |  | Planner |  | Board   | |
|  | Entities |  | Entities|  | Entities|  | Entities|  | Entities| |
|  +----------+  +---------+  +---------+  +---------+  +---------+ |
|  +----------+  +---------+  +---------+  +---------+  +---------+ |
|  |  Auth    |  |  Task   |  | Habit   |  | Planner |  | Board   | |
|  | Repo I/F |  | Repo I/F|  | Repo I/F|  | Repo I/F|  | Repo I/F| |
|  +----+-----+  +----+----+  +----+----+  +----+----+  +----+----+ |
+-------|--------------|-----------|-----------|-----------|---------+
        |              |           |           |           |
+-------|--------------|-----------|-----------|-----------|---------+
|       v              v           v           v           v         |
|                    DATA LAYER                                      |
|  +----------+  +---------+  +---------+  +---------+  +---------+ |
|  |  Auth    |  |  Task   |  | Habit   |  | Planner |  | Board   | |
|  | Repo Imp |  | Repo Imp|  | Repo Imp|  | Repo Imp|  | Repo Imp| |
|  +----+-----+  +----+----+  +----+----+  +----+----+  +----+----+ |
|       |              |           |           |           |         |
|  +----+--------------+-----------+-----------+-----------+-------+ |
|  |               SUPABASE DATA SOURCES                           | |
|  |  +-------+ +--------+ +---------+ +----------+ +-----------+ | |
|  |  | Auth  | | PostgRE| | Realtime| | Edge Fn  | | Storage   | | |
|  |  | Client| | ST API | | Channel | | Invoker  | | Client    | | |
|  |  +-------+ +--------+ +---------+ +----------+ +-----------+ | |
|  +---------------------------------------------------------------+ |
+--------------------------------------------------------------------+
        |              |           |           |           |
+-------v--------------v-----------v-----------v-----------v---------+
|                    SUPABASE BACKEND                                 |
|  +-------+ +----------+ +---------+ +----------+ +---------+      |
|  | Auth  | | Postgres | | Realtime| | Edge     | | Storage |      |
|  |       | | + RLS    | | Server  | | Functions| |         |      |
|  +-------+ +----------+ +---------+ +----------+ +---------+      |
|                                          |                         |
|                                     +----v----+                    |
|                                     | Groq AI |                    |
|                                     | (Llama3)|                    |
|                                     +---------+                    |
+--------------------------------------------------------------------+
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| Screens/Pages | Render UI, consume AsyncValue states, dispatch user actions | StatelessWidget using `ConsumerWidget` or `HookConsumerWidget`, calls controller methods on user interaction |
| Controllers (Notifiers) | Manage feature state, orchestrate use cases, expose AsyncValue | `AsyncNotifier` subclasses with `@riverpod` code generation, one per screen or screen-group |
| Entities | Pure Dart immutable data classes, business rules | `freezed` data classes with `==` and `copyWith`, zero framework dependencies |
| Repository Interfaces | Define data contracts the domain expects | Abstract Dart classes in `domain/repositories/`, return `Future<Entity>` or `Stream<List<Entity>>` |
| Repository Implementations | Fulfill domain contracts using Supabase SDK | Concrete classes in `data/repositories/`, convert DTOs to entities, handle error mapping |
| Data Sources | Raw Supabase client calls | Thin wrappers around `supabase.from()`, `supabase.auth`, `supabase.channel()`, `supabase.functions.invoke()` |
| DTOs / Models | JSON serialization layer | `json_serializable` or `freezed` classes with `fromJson`/`toJson`, map 1:1 to Supabase table rows |
| Providers | Riverpod DI wiring | Generated `@riverpod` providers in feature-level `providers.dart` files |
| Router | Navigation and auth guards | `go_router` with Riverpod redirect, watches auth state provider |
| Edge Functions | Server-side AI proxy, secure API key storage | TypeScript (Deno) functions in `supabase/functions/`, invoked from Flutter via `supabase.functions.invoke()` |

## Recommended Project Structure

```
lib/
├── app.dart                          # MaterialApp.router with ProviderScope
├── main.dart                         # Entry point, Supabase.initialize()
├── core/
│   ├── constants/
│   │   ├── app_constants.dart        # Sizing, durations, limits
│   │   └── supabase_constants.dart   # Table names, column names
│   ├── errors/
│   │   ├── failures.dart             # Domain failure classes
│   │   └── exceptions.dart           # Data layer exceptions
│   ├── extensions/                   # Dart extension methods
│   ├── router/
│   │   ├── app_router.dart           # GoRouter config with Riverpod
│   │   └── route_names.dart          # Named route constants
│   ├── theme/
│   │   ├── app_theme.dart            # Material 3 light/dark themes
│   │   └── app_colors.dart           # Color palette
│   ├── providers/
│   │   ├── supabase_provider.dart    # Supabase client provider
│   │   └── shared_providers.dart     # Cross-feature providers
│   └── widgets/                      # Shared reusable widgets
│       ├── loading_indicator.dart
│       └── error_display.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── auth_remote_data_source.dart
│   │   │   ├── models/
│   │   │   │   └── user_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── app_user.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository.dart
│   │   ├── presentation/
│   │   │   ├── controllers/
│   │   │   │   └── auth_controller.dart
│   │   │   ├── screens/
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── register_screen.dart
│   │   │   └── widgets/
│   │   │       └── social_sign_in_button.dart
│   │   └── providers.dart
│   ├── tasks/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── task_remote_data_source.dart
│   │   │   ├── models/
│   │   │   │   └── task_model.dart
│   │   │   └── repositories/
│   │   │       └── task_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── task.dart
│   │   │   └── repositories/
│   │   │       └── task_repository.dart
│   │   ├── presentation/
│   │   │   ├── controllers/
│   │   │   │   ├── task_list_controller.dart
│   │   │   │   └── task_detail_controller.dart
│   │   │   ├── screens/
│   │   │   │   ├── task_list_screen.dart
│   │   │   │   └── task_detail_screen.dart
│   │   │   └── widgets/
│   │   │       ├── task_card.dart
│   │   │       └── priority_badge.dart
│   │   └── providers.dart
│   ├── habits/
│   │   ├── data/...
│   │   ├── domain/...
│   │   ├── presentation/...
│   │   └── providers.dart
│   ├── planner/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── planner_remote_data_source.dart
│   │   │   │   └── ai_remote_data_source.dart    # Edge Function invoker
│   │   │   ├── models/
│   │   │   │   ├── schedule_model.dart
│   │   │   │   └── ai_response_model.dart
│   │   │   └── repositories/
│   │   │       └── planner_repository_impl.dart
│   │   ├── domain/...
│   │   ├── presentation/...
│   │   └── providers.dart
│   ├── boards/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── board_remote_data_source.dart
│   │   │   │   └── board_realtime_data_source.dart  # Realtime channels
│   │   │   ├── models/...
│   │   │   └── repositories/
│   │   │       └── board_repository_impl.dart
│   │   ├── domain/...
│   │   ├── presentation/
│   │   │   ├── controllers/
│   │   │   │   ├── board_controller.dart
│   │   │   │   └── board_presence_controller.dart
│   │   │   ├── screens/
│   │   │   │   ├── board_list_screen.dart
│   │   │   │   └── board_detail_screen.dart
│   │   │   └── widgets/
│   │   │       ├── kanban_column.dart
│   │   │       ├── task_card_draggable.dart
│   │   │       └── presence_avatar_row.dart
│   │   └── providers.dart
│   ├── profile/
│   │   ├── data/...
│   │   ├── domain/...
│   │   ├── presentation/...
│   │   └── providers.dart
│   └── smart_input/
│       ├── data/
│       │   └── datasources/
│       │       ├── speech_data_source.dart       # speech_to_text plugin
│       │       └── nlp_parser_data_source.dart   # Regex/TFLite parser
│       ├── domain/...
│       ├── presentation/...
│       └── providers.dart
supabase/
├── functions/
│   ├── generate-schedule/
│   │   └── index.ts                  # Groq API call for daily planner
│   ├── classify-task/
│   │   └── index.ts                  # Optional cloud classification fallback
│   └── _shared/
│       └── groq_client.ts            # Shared Groq API wrapper
├── migrations/
│   └── *.sql                         # Database schema migrations
└── config.toml                       # Supabase project config
```

### Structure Rationale

- **Feature-first with layers inside:** Each feature is a self-contained module with data/domain/presentation sub-layers. This is the dominant pattern in production Flutter Clean Architecture projects. Developers working on "boards" never need to jump to distant folders. New features are added by creating a new feature directory with no impact on existing code.
- **`core/` for cross-cutting concerns:** Router, theme, shared providers, and error types live here. These are used by all features but owned by none.
- **`providers.dart` per feature:** Each feature exports its Riverpod providers from a single file. This is the DI boundary -- other features depend on providers, never on concrete implementations.
- **`supabase/` at project root:** Edge Functions and migrations live outside `lib/` because they are server-side Deno/TypeScript code deployed independently via `supabase functions deploy`.
- **Separate `models/` from `entities/`:** Models handle JSON serialization (data layer). Entities are pure Dart (domain layer). This separation means swapping Supabase for another backend only touches `data/`.

## Architectural Patterns

### Pattern 1: AsyncNotifier Controller Pattern

**What:** Each screen (or screen-group) gets an `AsyncNotifier` controller that manages its state lifecycle. The controller calls repository methods and exposes `AsyncValue<T>` for the UI to consume with `.when(data:, loading:, error:)`.

**When to use:** Every feature screen that fetches or mutates data. This is the default pattern.

**Trade-offs:** Small overhead per screen but consistent error/loading handling everywhere. Avoids the chaos of mixing FutureProvider, StateProvider, and StreamProvider ad-hoc.

**Example:**
```dart
@riverpod
class TaskListController extends _$TaskListController {
  @override
  Future<List<Task>> build() async {
    final repo = ref.watch(taskRepositoryProvider);
    return repo.getTasks();
  }

  Future<void> deleteTask(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(taskRepositoryProvider);
      await repo.deleteTask(id);
      return repo.getTasks();
    });
  }
}
```

### Pattern 2: Repository Abstraction with Supabase Implementation

**What:** Domain layer defines abstract repository interfaces. Data layer provides Supabase-specific implementations. Riverpod providers wire them together. The domain layer never imports `supabase_flutter`.

**When to use:** Always. This is non-negotiable in Clean Architecture. It enables testability (mock repositories) and backend swappability.

**Trade-offs:** More files than calling Supabase directly from controllers. Worth it for any project beyond a prototype -- especially a portfolio piece demonstrating architecture skill.

**Example:**
```dart
// domain/repositories/task_repository.dart
abstract class TaskRepository {
  Future<List<Task>> getTasks();
  Future<Task> createTask(Task task);
  Future<void> deleteTask(String id);
  Stream<List<Task>> watchTasks();  // For realtime
}

// data/repositories/task_repository_impl.dart
class TaskRepositoryImpl implements TaskRepository {
  final SupabaseClient _client;
  TaskRepositoryImpl(this._client);

  @override
  Future<List<Task>> getTasks() async {
    final response = await _client.from('tasks').select();
    return response.map((json) => TaskModel.fromJson(json).toEntity()).toList();
  }

  @override
  Stream<List<Task>> watchTasks() {
    return _client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((json) => TaskModel.fromJson(json).toEntity()).toList());
  }
}

// providers.dart
@riverpod
TaskRepository taskRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return TaskRepositoryImpl(client);
}
```

### Pattern 3: Realtime Channel Management for Collaborative Boards

**What:** The boards feature uses Supabase Realtime channels for three distinct purposes: Postgres Changes (live Kanban card updates), Presence (who is viewing the board), and Broadcast (cursor position or drag events). Each maps to a dedicated data source class, managed by a controller that handles channel lifecycle.

**When to use:** The collaborative boards feature specifically. Other features use the simpler `.stream()` API for live data.

**Trade-offs:** Channel management adds complexity (subscribe on enter, unsubscribe on leave, handle reconnection). But this is the portfolio differentiator feature, so the complexity is justified.

**Example:**
```dart
// Board realtime data source
class BoardRealtimeDataSource {
  final SupabaseClient _client;
  late RealtimeChannel _channel;

  void initChannel(String boardId) {
    _channel = _client.channel('board:$boardId');

    _channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'board_cards',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'board_id',
            value: boardId,
          ),
          callback: (payload) => _handleCardChange(payload),
        )
        .onPresenceSync((_) => _handlePresenceSync())
        .onPresenceJoin((payload) => _handlePresenceJoin(payload))
        .onPresenceLeave((payload) => _handlePresenceLeave(payload))
        .subscribe((status, error) async {
          if (status == RealtimeSubscribeStatus.subscribed) {
            await _channel.track({
              'user_id': _client.auth.currentUser!.id,
              'online_at': DateTime.now().toIso8601String(),
            });
          }
        });
  }

  void dispose() {
    _client.removeChannel(_channel);
  }
}
```

### Pattern 4: GoRouter + Riverpod Auth Guard

**What:** `go_router` is configured as a Riverpod provider that watches the auth state. When auth state changes (login/logout), the router's `redirect` function fires and sends users to the correct screen. No manual navigation on auth change.

**When to use:** App-level routing setup. Applied once in `core/router/`.

**Trade-offs:** Slightly complex initial setup but eliminates an entire class of auth-related navigation bugs.

**Example:**
```dart
@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    refreshListenable: authState,
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isOnAuth = state.matchedLocation.startsWith('/auth');

      if (!isLoggedIn && !isOnAuth) return '/auth/login';
      if (isLoggedIn && isOnAuth) return '/tasks';
      return null;
    },
    routes: [
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/tasks', builder: (_, __) => const TaskListScreen()),
          GoRoute(path: '/habits', builder: (_, __) => const HabitListScreen()),
          GoRoute(path: '/planner', builder: (_, __) => const PlannerScreen()),
          GoRoute(path: '/boards', builder: (_, __) => const BoardListScreen()),
          GoRoute(path: '/boards/:id', builder: (_, state) =>
              BoardDetailScreen(boardId: state.pathParameters['id']!)),
        ],
      ),
    ],
  );
}
```

### Pattern 5: Edge Function AI Proxy

**What:** AI-powered features (daily planner, task classification) never call external AI APIs directly from the Flutter client. Instead, the client invokes a Supabase Edge Function, which holds the Groq API key securely and proxies the request. The Edge Function is TypeScript/Deno, deployed via `supabase functions deploy`.

**When to use:** Any feature requiring external AI API calls (Groq/Llama 3). Never expose API keys in client code.

**Trade-offs:** Adds a network hop (client -> Edge Function -> Groq -> Edge Function -> client). Latency is acceptable for non-realtime AI features like generating a daily schedule. Edge Functions have cold starts but V8 isolate startup is fast (milliseconds).

## Data Flow

### Request Flow (Standard CRUD)

```
[User taps "Add Task"]
    |
    v
[TaskDetailScreen]  -- calls --> [TaskDetailController.createTask(task)]
    |                                       |
    |                                  state = AsyncLoading
    |                                       |
    |                                       v
    |                              [TaskRepository.createTask(task)]
    |                                       |
    |                                       v
    |                       [TaskRepositoryImpl] -- maps Entity to DTO -->
    |                                       |
    |                                       v
    |                       [supabase.from('tasks').insert(dto.toJson())]
    |                                       |
    |                                       v
    |                              [Supabase Postgres]
    |                                       |
    |                                  returns row
    |                                       |
    |                                       v
    |                       [TaskModel.fromJson() -> .toEntity()]
    |                                       |
    |                                       v
    |                              state = AsyncData(updatedList)
    |                                       |
    v                                       v
[Screen rebuilds with .when(data: ..., loading: ..., error: ...)]
```

### Realtime Data Flow (Collaborative Boards)

```
[User A drags card]                    [User B viewing same board]
    |                                           |
    v                                           |
[BoardController.moveCard()]                    |
    |                                           |
    v                                           |
[boardRepository.updateCard()]                  |
    |                                           |
    v                                           |
[Supabase Postgres UPDATE]                      |
    |                                           |
    v                                           |
[Realtime Postgres Changes]  -- pushes -->  [onPostgresChanges callback]
    |                                           |
    |                                     [BoardRealtimeDataSource]
    |                                           |
    |                                     [BoardController.state updated]
    |                                           |
    |                                     [BoardDetailScreen rebuilds]
    |                                           |
    +--- Presence channel --->  [presenceState() shows User A + B online]
```

### AI Planner Flow

```
[User taps "Generate Schedule"]
    |
    v
[PlannerController.generateSchedule()]
    |
    v
[PlannerRepository.requestAiSchedule(tasks, energyPrefs)]
    |
    v
[AiRemoteDataSource.invoke('generate-schedule', body: {...})]
    |
    v
[supabase.functions.invoke('generate-schedule', body: payload)]
    |
    v
[Supabase Edge Function (TypeScript/Deno)]
    |
    v
[Groq API (Llama 3) -- prompt with tasks + user energy pattern]
    |
    v
[Edge Function returns structured schedule JSON]
    |
    v
[ScheduleModel.fromJson() -> .toEntity()]
    |
    v
[PlannerController.state = AsyncData(schedule)]
    |
    v
[PlannerScreen renders timeline with drag-to-reschedule]
```

### State Management

```
[Riverpod ProviderScope (app root)]
    |
    +--- [supabaseClientProvider] -- singleton SupabaseClient
    |
    +--- [authStateProvider] -- StreamProvider watching auth changes
    |       |
    |       +--- [appRouterProvider] -- GoRouter watches auth
    |
    +--- [Feature Providers (per feature)]
            |
            +--- [repositoryProvider] -- watches supabaseClientProvider
            |
            +--- [controllerProvider] -- AsyncNotifier, watches repository
            |
            +--- [UI Widgets] -- ConsumerWidget watches controller
```

### Key Data Flows

1. **Auth flow:** Supabase Auth emits session stream -> `authStateProvider` (StreamProvider) updates -> GoRouter redirect fires -> user sent to correct screen. All features read `authStateProvider` for current user ID.

2. **CRUD flow:** Screen -> Controller (AsyncNotifier) -> Repository -> Supabase Client -> Postgres. Response maps back through DTO -> Entity -> AsyncValue. UI rebuilds reactively.

3. **Realtime board flow:** Board entry subscribes to Realtime channel (Postgres Changes + Presence). Card mutations go through normal CRUD path. Supabase pushes changes to all subscribers. Board exit calls `removeChannel()` to clean up.

4. **AI planner flow:** Controller invokes Edge Function via `supabase.functions.invoke()`. Edge Function calls Groq with user's tasks and energy preferences. Returns structured JSON schedule. Controller parses and exposes as AsyncValue.

5. **Smart input flow:** `speech_to_text` plugin captures voice -> raw text fed to NLP parser (regex first, TFLite later) -> parsed task fields (title, priority, deadline) -> pre-fill task creation form.

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 0-1k users | Current architecture is fine. Supabase free tier handles this. Single Postgres instance, realtime channels per board. |
| 1k-10k users | Enable Supabase connection pooling (PgBouncer). Add RLS indexes on `user_id` columns. Limit concurrent realtime subscriptions per user. Edge Function warm-up becomes relevant. |
| 10k+ users | Upgrade Supabase compute tier. Consider read replicas for heavy query features (habits analytics). Shard realtime channels by board. Evaluate if Edge Functions need regional deployment. |

### Scaling Priorities

1. **First bottleneck: Realtime connections.** Each board viewer holds a persistent WebSocket. Supabase free tier supports limited concurrent connections. Mitigation: unsubscribe from board channels when user navigates away (autoDispose on controller). Never hold channels open globally.

2. **Second bottleneck: Edge Function cold starts.** The AI planner calls Groq through an Edge Function. First invocation per region has a cold start. Mitigation: acceptable for FocusForge's use case (users tap "Generate Schedule" at most a few times per day). Not a real concern until very high concurrency.

3. **Third bottleneck: Postgres row-level security complexity.** Complex RLS policies on boards (owner, member roles) can slow queries if not indexed. Mitigation: add indexes on `board_id`, `user_id`, and membership role columns from the start.

## Anti-Patterns

### Anti-Pattern 1: Passing `ref` to Repositories

**What people do:** Inject the Riverpod `ref` into repository classes so they can read other providers directly.
**Why it's wrong:** Breaks Clean Architecture. The data layer becomes coupled to Riverpod. Repositories become untestable without a full ProviderContainer. The domain/data layer should have zero knowledge of the state management framework.
**Do this instead:** Inject concrete dependencies (SupabaseClient, other repositories) via constructor parameters. Let the Riverpod provider definition handle wiring.

### Anti-Pattern 2: Calling Supabase Directly from Controllers

**What people do:** Skip the repository layer and call `supabase.from('tasks').select()` inside AsyncNotifier controllers.
**Why it's wrong:** Scatters data access logic. Makes testing require Supabase mocking everywhere. Violates Clean Architecture's dependency rule. Makes backend migration impossible.
**Do this instead:** Always route through repository interfaces. Controllers depend on abstractions, never on Supabase SDK directly.

### Anti-Pattern 3: Global Realtime Subscriptions

**What people do:** Subscribe to all Realtime channels at app startup and keep them alive forever.
**Why it's wrong:** Wastes connections. Supabase has connection limits. Battery drain on mobile. Unnecessary data processing for screens not being viewed.
**Do this instead:** Subscribe when entering a screen, unsubscribe when leaving. Use Riverpod's `autoDispose` so controllers (and their channels) are cleaned up when no longer watched. The board channel should only exist while the user is on the board screen.

### Anti-Pattern 4: Fat Entities with Serialization Logic

**What people do:** Put `fromJson`/`toJson` methods on domain entities, blurring the data/domain boundary.
**Why it's wrong:** Domain entities become coupled to the JSON structure of the API. Changing the API response format requires changing domain code. Violates the Clean Architecture boundary.
**Do this instead:** Keep entities as pure immutable Dart classes (ideally with `freezed`). Create separate Model/DTO classes in `data/models/` with serialization, and add `toEntity()`/`fromEntity()` conversion methods on the model.

### Anti-Pattern 5: One Mega-Controller per Feature

**What people do:** Create a single controller that manages the entire feature state (list, detail, create, edit, delete all in one Notifier).
**Why it's wrong:** Becomes unwieldy. State type conflicts (list vs detail). Unnecessary rebuilds across the entire feature when only one aspect changes.
**Do this instead:** Split into focused controllers: `TaskListController`, `TaskDetailController`, `TaskCreateController`. Each has a clear state type and lifecycle. They can share the same repository provider.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| Supabase Auth | `supabase.auth.signInWithPassword()`, `supabase.auth.signInWithOAuth()` for Google, `onAuthStateChange` stream | Use `authStateProvider` StreamProvider. Google OAuth requires Supabase dashboard config + Android SHA-1 fingerprint. |
| Supabase Postgres | `supabase.from('table').select/insert/update/delete()` | Always through repository layer. Enable RLS on all tables. Use `.stream()` for simple realtime. |
| Supabase Realtime | `supabase.channel('topic')` with `.onPostgresChanges()`, `.onPresenceSync/Join/Leave()`, `.onBroadcast()` | Used for boards feature only. Subscribe on screen entry, `removeChannel()` on exit. |
| Supabase Edge Functions | `supabase.functions.invoke('function-name', body: payload)` | AI features only. Edge Functions written in TypeScript (Deno). Store Groq API key in Edge Function secrets. |
| Groq API (Llama 3) | Called from Edge Functions only, never from client | Free tier: 14,400 requests/day. Structure prompts with user's tasks + energy pattern. Return structured JSON. |
| speech_to_text | Flutter plugin, on-device | Captures voice input. Returns raw text string. Fed into NLP parser. |
| TFLite (future) | `tflite_flutter` plugin, on-device inference | Post-MVP upgrade. Replaces regex parser for task classification. Zero API cost. |
| FCM Push Notifications | `firebase_messaging` plugin + Supabase Database Webhooks or Edge Functions to trigger | Supabase can trigger Edge Function on DB events, which sends FCM push. Alternatively use Supabase's built-in webhook to a push service. |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Feature A <-> Feature B | Through shared Riverpod providers only | Features never import each other's internal classes. Cross-feature data (e.g., tasks shown in planner) is accessed via the task repository provider, not by importing task feature internals. |
| Presentation <-> Domain | Via repository interfaces and entity types | Controllers call abstract repository methods. They receive domain entities. No DTO or Supabase types cross this boundary. |
| Domain <-> Data | Via repository implementations | Data layer implements domain interfaces. Conversion between DTOs and entities happens here. Domain has zero imports from data layer. |
| Flutter Client <-> Supabase Backend | HTTP (REST) + WebSocket (Realtime) + HTTP (Edge Functions) | All through `supabase_flutter` SDK. Anon key on client, service role key only in Edge Functions. RLS enforces per-user data access. |
| Edge Function <-> Groq AI | HTTPS from Edge Function | API key stored as Supabase secret (`supabase secrets set GROQ_API_KEY=...`). Never exposed to client. |

## Build Order Implications

Based on dependencies between components, the recommended build order is:

1. **Core infrastructure first:** Supabase project setup, `core/` folder (theme, router shell, error types, supabase provider), and the auth feature. Everything else depends on having a Supabase client and authenticated user.

2. **Tasks feature second:** The simplest CRUD feature. Validates the full Clean Architecture pattern (entity, repository, controller, screen) end-to-end. Establishes patterns that all subsequent features copy.

3. **Smart input third:** Builds on top of the tasks feature. Adds voice capture and NLP parsing that pre-fill the task creation form. This is an enhancement to tasks, not a standalone feature.

4. **Habits feature fourth:** Parallel structure to tasks but adds streak calculation logic and chart rendering (`fl_chart`). Domain layer is more interesting (streak algorithms).

5. **AI Planner fifth:** Requires tasks and habits to exist (the planner schedules existing tasks, respects habit times). Introduces Edge Functions and Groq integration. First server-side code.

6. **Collaborative boards sixth:** Most complex feature. Requires auth (member management), realtime channels, presence, drag-and-drop UI. Build this last because it is the hardest and benefits from all patterns established in earlier features.

7. **Polish last:** Push notifications, Lottie/Rive animations, dark mode toggle, web deployment, README. These are cross-cutting enhancements, not structural features.

## Sources

- [Flutter App Architecture with Riverpod: An Introduction (Code with Andrea)](https://codewithandrea.com/articles/flutter-app-architecture-riverpod-introduction/) - Four-layer architecture reference
- [Flutter Clean Architecture with Riverpod and Supabase (Otakoyi)](https://otakoyi.software/blog/flutter-clean-architecture-with-riverpod-and-supabase) - Feature-first structure with Supabase integration
- [Flutter Riverpod Clean Architecture Template (DEV Community)](https://dev.to/ssoad/flutter-riverpod-clean-architecture-the-ultimate-production-ready-template-for-scalable-apps-gdh) - Production template structure
- [How to use Notifier and AsyncNotifier with Riverpod Generator (Code with Andrea)](https://codewithandrea.com/articles/flutter-riverpod-async-notifier/) - AsyncNotifier patterns
- [Flutter Project Structure: Feature-first or Layer-first? (Code with Andrea)](https://codewithandrea.com/articles/flutter-project-structure/) - Structure comparison
- [Supabase Realtime Concepts (Official Docs)](https://supabase.com/docs/guides/realtime/concepts) - Realtime architecture
- [Supabase Flutter: Subscribe to Channel (Official Docs)](https://supabase.com/docs/reference/dart/subscribe) - Dart Realtime API
- [Edge Functions Architecture (Supabase Official Docs)](https://supabase.com/docs/guides/functions/architecture) - Edge Function runtime details
- [Guarding Routes with GoRouter and Riverpod (DEV Community)](https://dev.to/dinko7/guarding-routes-in-flutter-with-gorouter-and-riverpod-40h4) - Auth guard pattern

---
*Architecture research for: FocusForge - Flutter AI-powered productivity app*
*Researched: 2026-03-16*
