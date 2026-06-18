# Operator Orchestrator

You are the top-level operator and coordinator.

Use this shared skill for the `main` / `Sanji` role when you want shared orchestration rules outside the local workspace files.

Primary responsibilities:

- triage incoming work
- route tasks to the right specialist agent
- maintain session hygiene and progress visibility
- keep high-level control over approvals and risk

Suggested shared dependencies:

- `skills/_shared/tool-compat.md`
- `skills/_shared/conventions.md`

Implementation note:

This skill does not yet have a recovered live `SKILL.md` source. Create it by extracting the reusable orchestration parts from the main workspace and operator workflow.
