# Fleet Dashboard M1 — Validation Strategy

## Validation Layers
1. **Contract tests**: telemetry schema and adapter payload validation.
2. **Integration tests**: ingestion → persistence → read model flow.
3. **Workflow tests**: issue-to-PR lifecycle and blocker detection paths.
4. **Operational smoke tests**: dashboard freshness, intervention action round-trip.

## M1 Completion Gates
- Architecture spec approved and merged.
- Telemetry schema approved and merged.
- Implementation plan approved and merged.
- Validation strategy approved and merged.

## M2 Entry Gates
- Canonical schema represented in Supabase migrations.
- At least one end-to-end ingestion test passing.
- Baseline dashboard query set defined for core entities.

## Regression Cadence
- Contract + unit checks on every PR.
- Integration suite on merge to `main`.
- Operational smoke run daily during active milestones.

## Operational Readiness Checks
- Alert thresholds produce low-noise, high-signal incidents.
- Blocked/stalled entities visible within target detection latency.
- Intervention actions emit auditable success/failure events.
