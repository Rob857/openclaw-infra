# Skills Migration Checklist

This checklist turns the recovered live agent skill layout into a concrete migration plan toward a single shared skills source of truth in `~/repos/Claw_Memory_Skills/skills/`.

Use this together with [SKILLS-REGISTRY-PLAN.md](/Users/robinbeyer/GitMapletics/openclaw-infra/docs/SKILLS-REGISTRY-PLAN.md).

## Current Sources

Recovered shared-skill candidates:

- `workspace-claudia/SKILL.md`
- `workspace-barney/SKILL.md`
- `workspace-manfred/SKILL.md`
- `agents/gordon/workspace/skills/create-issue/SKILL.md`

Recovered per-agent identity files that should stay local:

- `SOUL.md`
- `USER.md`
- `TOOLS.md`
- memory files
- workspace-specific `AGENTS.md`

## Proposed Canonical Skills

Create these shared skills in `Claw_Memory_Skills`:

- `architecture-review`
- `flutter-code-review`
- `flutter-issue-implementation`
- `slack-create-issue`
- `operator-orchestrator`
- `low-cost-research`

## Exact Mapping

### Claudia

Current source:

- [workspace-claudia/SKILL.md](/Users/robinbeyer/GitMapletics/openclaw-infra/tmp/server-export-20260325-101438/unpacked/workspace-claudia/SKILL.md)

Target shared skill:

- `~/dev-handbook/skills/architecture-review/SKILL.md`

Keep local:

- [workspace-claudia/SOUL.md](/Users/robinbeyer/GitMapletics/openclaw-infra/tmp/server-export-20260325-101438/unpacked/workspace-claudia/SOUL.md)
- `USER.md`
- `TOOLS.md`

Wrapper after migration:

- replace local `SKILL.md` with a thin pointer to `architecture-review`

### Barney

Current source:

- [workspace-barney/SKILL.md](/Users/robinbeyer/GitMapletics/openclaw-infra/tmp/server-export-20260325-101438/unpacked/workspace-barney/SKILL.md)

Target shared skill:

- `~/dev-handbook/skills/flutter-code-review/SKILL.md`

Keep local:

- [workspace-barney/SOUL.md](/Users/robinbeyer/GitMapletics/openclaw-infra/tmp/server-export-20260325-101438/unpacked/workspace-barney/SOUL.md)
- `USER.md`
- `TOOLS.md`

Wrapper after migration:

- replace local `SKILL.md` with a thin pointer to `flutter-code-review`

### Manfred

Current source:

- [workspace-manfred/SKILL.md](/Users/robinbeyer/GitMapletics/openclaw-infra/tmp/server-export-20260325-101438/unpacked/workspace-manfred/SKILL.md)

Observations:

- This is already partly designed around handbook skills
- It references `~/dev-handbook/skills/` for review subflows

Target shared skill:

- `~/dev-handbook/skills/flutter-issue-implementation/SKILL.md`

Related shared dependencies:

- `~/dev-handbook/skills/flutter-code-review/SKILL.md`
- `~/dev-handbook/skills/architecture-review/SKILL.md`
- `~/dev-handbook/skills/_shared/tool-compat.md`

Keep local:

- [workspace-manfred/SOUL.md](/Users/robinbeyer/GitMapletics/openclaw-infra/tmp/server-export-20260325-101438/unpacked/workspace-manfred/SOUL.md)
- `USER.md`
- `TOOLS.md`

Wrapper after migration:

- reduce local `SKILL.md` to a thin pointer to `flutter-issue-implementation`

### Gordon

Current source:

- [agents/team-agent/workspace/skills/create-issue/SKILL.md](/Users/robinbeyer/GitMapletics/openclaw-infra/tmp/server-export-20260325-101438/unpacked/agents/team-agent/workspace/skills/create-issue/SKILL.md)

Target shared skill:

- `~/dev-handbook/skills/slack-create-issue/SKILL.md`

Keep local:

- `SOUL.md`
- `USER.md`
- `TOOLS.md`
- Slack-account-specific binding context

After migration:

- remove reliance on workspace-local `skills/create-issue/`
- point Gordon to the shared handbook skill

## Implementation Checklist

### Phase 1: Build the Registry

- [ ] Create `Claw_Memory_Skills/skills/registry.yml`
- [ ] Create `meta.yml` for each shared skill
- [ ] Create `_shared/tool-compat.md`
- [ ] Create `_shared/conventions.md`

### Phase 2: Extract Shared Skill Bodies

- [ ] Copy Claudia’s current `SKILL.md` into `skills/architecture-review/SKILL.md`
- [ ] Copy Barney’s current `SKILL.md` into `skills/flutter-code-review/SKILL.md`
- [ ] Copy Manfred’s current `SKILL.md` into `skills/flutter-issue-implementation/SKILL.md`
- [ ] Copy Gordon’s `skills/create-issue/SKILL.md` into `skills/slack-create-issue/SKILL.md`

### Phase 3: Normalize Naming

- [ ] Rename skill folders to stable lowercase IDs
- [ ] Ensure each skill has `SKILL.md` and `meta.yml`
- [ ] Remove agent names from shared skill names unless the skill is truly agent-specific

### Phase 4: Convert Workspaces to Thin Wrappers

- [ ] Replace Claudia local `SKILL.md` with a pointer to `architecture-review`
- [ ] Replace Barney local `SKILL.md` with a pointer to `flutter-code-review`
- [ ] Replace Manfred local `SKILL.md` with a pointer to `flutter-issue-implementation`
- [ ] Replace Gordon local `skills/create-issue/SKILL.md` usage with a pointer to `slack-create-issue`

### Phase 5: Provisioning

- [ ] Ensure `~/repos/Claw_Memory_Skills/` exists on the VPS
- [ ] Ensure `~/dev-handbook` points to `~/repos/Claw_Memory_Skills/`
- [ ] Ensure `~/repos/Claw_Memory_Skills/skills/` is updated before agents run
- [ ] Add an Ansible validation step that fails if required shared skills are missing

### Phase 6: Mission Control Readiness

- [ ] Make Mission Control read `registry.yml`
- [ ] Render `meta.yml` fields in UI
- [ ] Show which agents map to which shared skills
- [ ] Distinguish shared skills from local workspace-only wrappers

## What Can Be Deleted Later

After successful migration and validation:

- duplicated long-form workspace `SKILL.md` bodies
- Gordon’s duplicated workspace-local shared skill folder if replaced by handbook skill
- stale references to multiple skill lookup paths

Do not delete:

- `SOUL.md`
- `USER.md`
- `TOOLS.md`
- memory files
- other agent-local context files

## Recommended Order

1. `architecture-review`
2. `flutter-code-review`
3. `flutter-issue-implementation`
4. `slack-create-issue`
5. provisioning validation
6. Mission Control integration

This order minimizes breakage because Manfred already conceptually depends on the review skills.
