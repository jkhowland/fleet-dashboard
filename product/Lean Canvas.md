# Fleet Dashboard — Lean Canvas

## Problem
1. Autonomous delivery state is fragmented across tmux, GitHub, logs, and chat updates.
2. Stalled blades/PR loops are detected too late, slowing milestone completion.
3. There is no unified, queryable operational model for fleet throughput and reliability.

## Customer Segments
- **Primary:** Internal Howlers operators (Ragnar/Joshua) running multi-issue autonomous pipelines.
- **Early adopters:** Teams running high-frequency blade workflows that require active orchestration.

## Unique Value Proposition
**The internal operations cockpit for autonomous software delivery — one place to monitor, diagnose, and steer the entire code fleet.**

## Solution
- Real-time fleet dashboard (issues, blade sessions, PR states, milestone progress).
- Health and blocker detection (stalled sessions, loop caps, branch/base mismatch, failed checks).
- Guided interventions and one-click operational actions.
- Supabase-backed telemetry and historical performance analytics.

## Channels
- Internal rollout in Howlers engineering operations.
- Embedded into existing milestone execution workflow.
- Daily operational use during active milestone cycles.

## Revenue Streams
- Internal product (no external monetization in phase 1).
- Future option: operational analytics and fleet-control SaaS for AI-native teams.

## Cost Structure
- Frontend/dashboard engineering and maintenance.
- Supabase storage/query cost for fleet event telemetry.
- Integration maintenance for GitHub/OpenClaw/session providers.
- Alerting and reliability tooling overhead.

## Key Metrics
- Mean time to detect blocked/stalled issue execution.
- Mean time to recover from stalled blade/PR loops.
- Milestone cycle time (start → complete).
- % issues completed autonomously without manual intervention.
- PR first-pass merge rate.

## Unfair Advantage
Howlers controls the full autonomous stack (orchestration, blades, milestones, and data layer), enabling deeper operational visibility and intervention than generic engineering dashboards.

## Known Unknowns
- Best default workflows for issue-level triage.
- Minimal dashboard surface needed for daily operational command.
- Which interventions should be automated vs human-confirmed.
