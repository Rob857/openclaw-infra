# Skills Registry Plan

This document defines a target structure for moving shared agent skills into a single source of truth in the `Claw_Memory_Skills` repo, while keeping agent-specific identity and memory in each OpenClaw workspace.

## Goal

Use `~/repos/Claw_Memory_Skills/skills/` on the VPS as the canonical shared skills registry.

This should make it possible to:

- avoid duplicated skill logic across agent workspaces
- keep agent identity separate from reusable workflows
- make skill discovery consistent for all agents
- expose shared skills in Mission Control later

## Recommended Split

### Shared Source of Truth

Store reusable workflows in:

`~/repos/Claw_Memory_Skills/skills/`

Compatibility path on the VPS:

`~/dev-handbook/skills/`

Examples:

- architecture review
- Flutter code review
- issue implementation workflow
- orchestration patterns
- shared tool compatibility notes

### Per-Agent Workspace Content

Keep these inside each agent workspace:

- `SOUL.md`
- `USER.md`
- `TOOLS.md`
- memory files
- optional thin `SKILL.md` wrapper pointing to the shared skill

Do not store large duplicated skill instructions in every workspace unless they are truly private to that agent.

## Target Repo Layout

```text
Claw_Memory_Skills/
  skills/
    registry.yml
    architecture-review/
      SKILL.md
      meta.yml
    flutter-code-review/
      SKILL.md
      meta.yml
    flutter-issue-implementation/
      SKILL.md
      meta.yml
    slack-create-issue/
      SKILL.md
      meta.yml
    operator-orchestrator/
      SKILL.md
      meta.yml
    low-cost-research/
      SKILL.md
      meta.yml
    _shared/
      tool-compat.md
      conventions.md
```

## File Responsibilities

### `registry.yml`

Top-level machine-readable index for Mission Control and other tooling.

Example:

```yaml
skills:
  - id: architecture-review
    path: skills/architecture-review/SKILL.md
  - id: flutter-code-review
    path: skills/flutter-code-review/SKILL.md
  - id: flutter-issue-implementation
    path: skills/flutter-issue-implementation/SKILL.md
```

### `meta.yml`

Machine-readable metadata for one skill.

Example:

```yaml
id: flutter-code-review
name: Flutter Code Review
summary: Review Flutter and Dart changes for correctness, side effects, and architecture compliance.
category: review
owners:
  - robin
used_by:
  - barney
repo: Claw_Memory_Skills
path: skills/flutter-code-review/SKILL.md
source_of_truth: true
```

Recommended fields:

- `id`
- `name`
- `summary`
- `category`
- `owners`
- `used_by`
- `repo`
- `path`
- `source_of_truth`

Optional fields:

- `tags`
- `last_reviewed`
- `depends_on`
- `private`

### `SKILL.md`

Human-readable instructions the agent follows.

This should contain:

- the role and task definition
- exact workflow steps
- output format
- references to `_shared/` docs where relevant

## Agent Mapping

Suggested shared-skill mapping for the current agent set:

- `main` / `Sanji` -> `operator-orchestrator`
- `deepseek-agent` -> `low-cost-research`
- `claudia` -> `architecture-review`
- `barney` -> `flutter-code-review`
- `gordon` -> `slack-create-issue`
- `manfred` -> `flutter-issue-implementation`

## Recommended Workspace Pattern

Each agent workspace keeps its identity files, but uses a thin wrapper for the shared skill.

Example workspace `SKILL.md`:

```md
# Shared Skill Binding

Use the shared skill from:

`~/dev-handbook/skills/flutter-code-review/SKILL.md`

If shared references are needed, also read:

- `~/dev-handbook/skills/_shared/tool-compat.md`
- local `SOUL.md`
- local `TOOLS.md`
```

This keeps agent-specific context local while moving reusable instructions into one maintained location.

## Mission Control Readiness

If Mission Control should later display shared skills, it should read from:

- `~/repos/Claw_Memory_Skills/skills/registry.yml`
- each skill's `meta.yml`

That allows Mission Control to show:

- skill name
- summary
- category
- owning repo/path
- which agents use it
- whether it is shared or local-only

## Migration Plan

### Phase 1: Inventory

Identify current workspace-local skill content:

- `workspace-claudia/SKILL.md`
- `workspace-barney/SKILL.md`
- `workspace-manfred/SKILL.md`
- `agents/gordon/workspace/skills/`

Classify each as:

- shared reusable skill
- agent-local behavior
- stale duplicate

### Phase 2: Extract Shared Skills

Move shared logic into `Claw_Memory_Skills/skills/<skill-id>/SKILL.md`.

Keep:

- architecture review
- Flutter review
- issue implementation
- Slack/team-agent workflow

### Phase 3: Add Metadata

Create:

- `registry.yml`
- one `meta.yml` per skill

### Phase 4: Thin Workspace Wrappers

Replace workspace-local `SKILL.md` files with short wrappers pointing to the handbook skill.

### Phase 5: Provisioning

Update Ansible so the VPS always has a valid deployed `~/repos/Claw_Memory_Skills/skills/` tree before agents run.

### Phase 6: Mission Control Integration

Read `registry.yml` and `meta.yml` to display skills in Mission Control.

## Operational Recommendation

Use this rule:

- shared workflow logic lives in `Claw_Memory_Skills`
- identity, memory, and local notes live in the agent workspace

That is the cleanest path to a real single source of truth without flattening agent personality and local context.
