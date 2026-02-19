# Fleet Dashboard — Financial Model (Internal)

## Planning Mode
**Internal operations product (phase 1).**
Primary objective is productivity and reliability gains in autonomous execution, not direct revenue.

## Value Hypothesis
Fleet Dashboard increases output by reducing orchestration overhead and recovery time.

### Value Drivers
- Fewer stalled issues and PR loops.
- Faster diagnosis and recovery when blockers occur.
- Better milestone predictability and throughput.
- Reduced context-switching between tools.

## Operating Assumptions
- Howlers runs multiple concurrent blades during active milestones.
- Supabase is available as the canonical telemetry and analytics backend.
- Operators actively use dashboard intervention tools.

## KPI Dashboard (Internal ROI)
1. **Detection Latency**: time from blocker occurrence to operator awareness.
2. **Recovery Latency**: time from blocker detection to issue back in-progress.
3. **Autonomous Completion Rate**: % issues merged without manual rescue.
4. **Milestone Throughput**: merged issues/week and milestone completion time.
5. **Operator Efficiency**: estimated coordination minutes saved per issue.

## Cost Structure
- Engineering build/maintenance cost.
- Supabase compute/storage for fleet events and aggregates.
- Integrations and reliability tooling.
- Ongoing workflow tuning and operational support.

## Path to Profitability (Future)
If externalized, likely model:
- Team subscription for orchestration dashboard seats.
- Usage-based event/automation tiers.
- Premium controls for enterprise governance and policy automation.

## Sensitivity Areas
- False-positive alert volume vs trust/adoption.
- Data model growth and query cost over time.
- Integration brittleness with evolving toolchains.
- Human-in-the-loop requirements reducing automation gains.

## Known Unknowns
- Internal willingness-to-pay proxy for operations tooling.
- Minimum exportable feature set for external users.
- Packaging strategy for intervention controls vs analytics.
