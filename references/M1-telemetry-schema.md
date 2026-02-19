# Fleet Dashboard M1 — Canonical Telemetry Schema

## Goals
Create a shared operational contract for fleet observability, health scoring, and intervention workflows.

## Canonical Entities
- `milestone`: id, name, state, started_at, completed_at
- `issue`: id, milestone_id, state, assignee, priority
- `blade_session`: id, issue_id, runtime, state, started_at, last_heartbeat_at
- `pull_request`: id, issue_id, state, checks_state, review_state, base_branch
- `fleet_alert`: id, entity_type, entity_id, severity, reason, opened_at, resolved_at

## Event Envelope
Required fields for every event:
- `event_id` (UUID)
- `event_type`
- `occurred_at` (UTC)
- `source` (`github`, `openclaw`, `operator`, `system`)
- `entity_type` + `entity_id`
- `payload` (JSON object)
- `schema_version`

## Core Event Types
- `issue.created`, `issue.started`, `issue.blocked`, `issue.completed`
- `blade.started`, `blade.heartbeat`, `blade.stalled`, `blade.stopped`
- `pr.opened`, `pr.checks_failed`, `pr.ready_for_review`, `pr.merged`
- `milestone.started`, `milestone.at_risk`, `milestone.completed`
- `operator.action_requested`, `operator.action_succeeded`, `operator.action_failed`

## Lifecycle Constraints
- Entity state transitions must be monotonic and valid-by-type.
- `blade.stalled` requires stale heartbeat evidence in payload.
- `pr.merged` requires final `base_branch` and merge SHA.
- All intervention outcomes must emit action result events.

## Health/Blocker Inputs
- Last heartbeat age
- Consecutive failed checks
- Review loop attempt count
- Time-in-state thresholds
- Dependency-blocked flags

## Versioning
- Start at `schema_version = 1` for M1.
- Backward-compatible additions only within major version.
- Breaking changes require new major and migration notes.
