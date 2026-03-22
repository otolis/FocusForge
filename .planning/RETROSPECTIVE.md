# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.0 — MVP

**Shipped:** 2026-03-22
**Phases:** 8 | **Plans:** 25 | **Timeline:** 6 days (2026-03-16 → 2026-03-22)

### What Was Built
- Full auth flow (email + Google) with profile, onboarding, and Material 3 theming
- Task management with CRUD, categories, recurrence, filters, full-text search
- NLP task parsing (regex + chrono_dart) and TFLite on-device classification
- Habit tracking with streaks, one-tap check-in, heat map, and fl_chart analytics
- AI daily planner with Groq-powered Edge Function, energy-aware scheduling, drag-to-reschedule
- Collaborative Kanban boards with Supabase Realtime, presence indicators, role-based access
- Adaptive push notifications via FCM with quiet hours and completion pattern analysis
- Cross-feature integration, Lottie animations, and Flutter web deployment via GitHub Actions

### What Worked
- **Parallel phase execution (2-7):** Independent vertical slices enabled 6 feature phases to run concurrently, dramatically reducing wall-clock time
- **Wave-based plan execution:** Within each phase, wave grouping respected dependencies while maximizing parallelism
- **Verification loop:** Automated must-have verification after each phase caught 4 gaps in Phase 8 that were closed via gap-closure planning
- **Consistent architecture:** Clean Architecture (data/domain/presentation) per feature kept every phase structurally identical
- **Edge Function pattern:** Shared CORS module and consistent Groq API integration pattern established in Phase 5, reused in Phase 7

### What Was Inefficient
- **ROADMAP sync during parallel execution:** Running phases in parallel terminals caused ROADMAP.md progress table to fall out of sync — required manual checkbox fixes
- **Phase 8 gap closure:** 4 gaps found in verification (planner deep-links, completion sync, SmartInputField in AddItemSheet, reduce-motion guard) — could have been caught earlier with more precise plan must_haves
- **Migration numbering conflicts:** Parallel phases (02, 05, 06) needed manual migration number coordination (00002, 00003, 00004) to avoid collisions

### Patterns Established
- Repository DI pattern: optional SupabaseClient param for testability (ProfileRepository → PlannerRepository → all)
- AsyncNotifier with optimistic updates and try/catch rollback for all CRUD operations
- Data-only FCM messages for Flutter-controlled notification display
- LongPressDraggable with 500ms delay to avoid scroll-drag conflicts
- CelebrationOverlay with reduce-motion guard (MediaQuery.disableAnimations)

### Key Lessons
1. **Parallel execution needs atomic ROADMAP updates** — the CLI tool's sequential `phase complete` calls don't handle concurrent writes well. Future: consider file locking or batch completion
2. **Plan must_haves should include all user-facing interactions** — the Phase 8 verifier caught missing planner interactivity because the original plan scope didn't explicitly require it
3. **Migration numbering needs a registry** — parallel phases should claim migration numbers upfront during planning, not discover conflicts at execution time
4. **Gap closure is fast** — the verify → plan-gaps → execute-gaps → re-verify cycle closed 4 gaps in one round, proving the gap closure workflow is efficient

### Cost Observations
- Model mix: ~70% opus (execution), ~25% sonnet (verification/checking), ~5% haiku (none used)
- Sessions: ~8 (parallel terminals for phases 2-7, sequential for 1 and 8)
- Notable: Executor agents averaged 3-5 min per plan; total execution time dominated by Phase 8 integration

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Timeline | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.0 | 6 days | 8 | Parallel phase execution across 6 concurrent terminals |

### Cumulative Quality

| Milestone | Plans | Verifications | Gap Closures |
|-----------|-------|---------------|-------------|
| v1.0 | 25 | 8/8 passed | 1 round (4 gaps) |

### Top Lessons (Verified Across Milestones)

1. Parallel execution saves time but requires careful state coordination
2. Verification-driven gap closure is reliable and fast — trust the loop
