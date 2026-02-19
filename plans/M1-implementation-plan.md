# Fleet Dashboard M1 — Phased Implementation Plan

## Phase 1: Foundations (M1)
- Finalize architecture, telemetry schema, and validation strategy.
- Establish canonical milestone tracking artifacts.
- Exit criteria: all M1 documentation issues merged.

## Phase 2: Data Platform Bootstrap (M2)
- Implement Supabase schema for entities/events.
- Build ingestion adapters for GitHub + session runtime.
- Exit criteria: canonical event ingestion and queryable read models.

## Phase 3: Operator Surface (M3)
- Build real-time dashboard views for issues, sessions, PRs, milestones.
- Add health indicators and blocker surfacing.
- Exit criteria: operators can monitor full fleet status in one interface.

## Phase 4: Guided Intervention (M4)
- Implement context-aware actions (relaunch, steer, review, merge handoffs).
- Add audit trail and failure-aware action UX.
- Exit criteria: interventions are traceable and recover failed flows quickly.

## Risks and Mitigations
- Integration drift risk → contract tests and adapter versioning.
- Alert fatigue risk → threshold tuning with operator feedback loops.
- Data quality risk → strict schema validation + dead-letter handling.

## Critical Path
1. M1 docs complete
2. M2 data model + ingestion operational
3. M3 dashboard operational views
4. M4 intervention actions
