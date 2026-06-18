# Live Agent Recovery

This repo drifted from the live VPS state. On 2026-03-25, the server still contained legacy agents that were not represented in `ansible/group_vars/openclaw.yml`.

## Recovered Live Agents

- `claudia` — planner/architect role
- `barney` — reviewer/quality-gate role
- `manfred` — legacy coding agent workspace
- `team-agent` — separate Slack-bound agent (`identityName: Gordon`)

The checked-in Ansible config has been updated to match the desired active set:

- `main` (`Sanji`)
- `deepseek-agent`
- `claudia`
- `barney`
- `gordon` (`Gordon`)
- `manfred` (`Manfred`)

## Local Snapshot

The server state was exported locally to:

`tmp/server-export-20260325-101438/`

Key files:

- `tmp/server-export-20260325-101438/openclaw.json`
- `tmp/server-export-20260325-101438/legacy-agents.json`
- `tmp/server-export-20260325-101438/full-openclaw-state.tgz`
- `tmp/server-export-20260325-101438/channels-status.json`
- `tmp/server-export-20260325-101438/devices.json`
- `tmp/server-export-20260325-101438/unpacked/workspace-claudia/`
- `tmp/server-export-20260325-101438/unpacked/workspace-barney/`
- `tmp/server-export-20260325-101438/unpacked/workspace-manfred/`
- `tmp/server-export-20260325-101438/unpacked/agents/team-agent/`

## What Was Recovered

### Claudia

Recovered from:

- `tmp/server-export-20260325-101438/unpacked/workspace-claudia/SOUL.md`
- `tmp/server-export-20260325-101438/unpacked/workspace-claudia/SKILL.md`

Inferred role:

- Name: `Claudia`
- Purpose: strategic planning and architecture review
- Model on server: `anthropic/claude-sonnet-4-20250514`
- No explicit delivery bindings on the live server

### Barney

Recovered from:

- `tmp/server-export-20260325-101438/unpacked/workspace-barney/SOUL.md`
- `tmp/server-export-20260325-101438/unpacked/workspace-barney/SKILL.md`

Inferred role:

- Name: `Barney`
- Purpose: code review and quality gate
- Model on server: `anthropic/claude-sonnet-4-20250514`
- No explicit delivery bindings on the live server

### Gordon / team-agent

Recovered from:

- `tmp/server-export-20260325-101438/openclaw.json`
- `tmp/server-export-20260325-101438/unpacked/agents/team-agent/`

Inferred role:

- Agent ID: `team-agent`
- Identity name: `Gordon`
- Emoji: `👨‍🍳`
- Model on server: `anthropic/claude-sonnet-4-20250514`
- Live binding: Slack account `gordon`

Desired repo-managed ID:

- `gordon`

### Manfred / codex-coding-agent

Recovered from:

- `tmp/server-export-20260325-101438/openclaw.json`
- `tmp/server-export-20260325-101438/unpacked/workspace-manfred/`

Observed live state:

- Current managed-style agent ID on server: `codex-coding-agent`
- Separate legacy agent also exists on server as `manfred`
- Desired repo-managed ID: `manfred`

## Additional Live State Recovered

### Full OpenClaw State Archive

The entire `/home/ubuntu/.openclaw` directory was exported as:

- `tmp/server-export-20260325-101438/full-openclaw-state.tgz`

This is the closest local copy of the live server state.

### Live Channels

Recovered from:

- `tmp/server-export-20260325-101438/channels-status.json`
- `tmp/server-export-20260325-101438/openclaw.json`

Observed live state:

- Slack is enabled and running on the server
- There is a default Slack account
- There is a second Slack account for `Gordon`

This repo currently has no Slack provisioning role, variables, or documentation beyond this recovery note.

### Live Cron Jobs

Recovered from:

- `openclaw cron list --json`

Observed live jobs:

- `Abend-Zusammenfassung für Rob`
- `Morgen-Zusammenfassung für Rob`

Both jobs run under `main` in isolated sessions and instruct the agent to send summaries to Slack. They are not represented in `openclaw_cron_jobs` in the repo.

### Live Devices

Recovered from:

- `tmp/server-export-20260325-101438/devices.json`

This captures currently paired devices and can be used for audit/reference, but it should not be treated as declarative infra.

## Important Limitation

Adding agents back to `openclaw_agents` restores them as Ansible-managed agents, but it does not automatically recreate their prior workspace contents unless those workspaces are also restored or synced.

Their specialization lived in workspace files such as `SOUL.md` and `SKILL.md`, not only in the gateway config.

There is also live server state that the current repo cannot reproduce exactly:

- Slack channel/account configuration
- Slack-bound `team-agent`
- Cron jobs that rely on Slack behavior but are not expressed in repo config
- The repo currently defines `gordon` and `manfred` in `ansible/group_vars/openclaw.yml`; `gordon` is already part of the managed agent set. Any remaining references to `team-agent` or `codex-coding-agent` should be treated as legacy live-server state to reconcile explicitly.

## Follow-Up Options

1. Reconcile any remaining live-server IDs from `team-agent` to `gordon` and from `codex-coding-agent` to `manfred` if those legacy IDs still exist on the server.
2. Restore the exported workspace files into managed workspace repos for `claudia` and `gordon` if you want their prior behavior preserved declaratively.
3. Add a Slack provisioning path to Ansible if exact repo-to-server parity is required.
4. Recreate the live cron jobs declaratively once Slack support exists in the repo.
5. Remove stale server-only artifacts after reconciliation, including the orphaned `/home/ubuntu/.openclaw/agents/claude` directory.
