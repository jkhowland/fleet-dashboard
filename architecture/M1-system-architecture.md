# Fleet Dashboard M1 — System Architecture

## Purpose
Define the foundational architecture for Fleet Dashboard as an internal operations cockpit for autonomous software delivery.

## Core Subsystems
1. **Dashboard UI (Operator Surface)**
   - Real-time visibility into milestones, issues, blade sessions, PR pipeline, and alerts.
2. **Telemetry Ingestion Layer**
   - Receives normalized fleet events from GitHub/session sources and validates schema.
3. **Operational Data Layer (Supabase)**
   - Canonical store for entities, events, aggregates, and derived health status.
4. **Workflow Orchestration Layer**
   - Executes operator actions (relaunch, steer, review, merge) with auditability.
5. **Alerting/Health Engine**
   - Computes blocker/stall conditions and surfaces intervention prompts.

## Data Flow
1. Integrations emit raw events.
2. Ingestion normalizes and validates events.
3. Canonical events persist to Supabase.
4. Aggregators compute current fleet state and health.
5. Dashboard queries read models; operators trigger orchestration actions.
6. Orchestration actions produce new events (closed loop).

## Control Boundaries
- UI never writes directly to canonical tables; all writes flow through orchestrator APIs.
- Health scoring is deterministic and derived only from canonical events.
- Intervention actions require explicit operator identity and action audit records.

## External Integrations
- **GitHub**: issues, PRs, checks, review state.
- **Session Runtime (tmux/OpenClaw)**: blade session lifecycle and status.
- **Supabase**: canonical persistence, read models, and analytics.

## Failure Modes and Mitigations
- Event ingestion outage → retry queue + dead-letter stream.
- Integration API drift/failure → adapter versioning + contract tests.
- Stale dashboard state → freshness SLAs + stale-state indicators.
- Action execution failure → idempotent retries + explicit failed-action events.

## M1→M2 Compatibility
This architecture supports M2 implementation by preserving strict event sourcing boundaries, enabling incremental UI and automation rollout without schema ambiguity.
