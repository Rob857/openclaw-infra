# Agent Routing And Discord Status

This document records the current intended routing model, the live adjustments made on 2026-04-01, and the Discord recovery that was completed the same day.

## Target Structure

- `main` is the personal frontdoor agent.
- `gordon` is the team-facing Slack agent.
- `manfred`, `claudia`, `barney`, `corby`, and `deepseek-agent` keep their own workspaces and memory.
- `main` remains the technical default agent ID in OpenClaw.
- `main` carries the Sanji identity; there is no separate routed `sanji` agent anymore.

## Current Intended Routing

- Discord `default` account -> `main`
- Slack `gordon` account -> `gordon`
- Gordon Slack team group `C0ANMR9Q59V` -> `gordon`

The generic Slack `default` account is intentionally disabled. Team Slack traffic should only go through `gordon`.

Configured in:

- [openclaw.yml](/Users/robinbeyer/GitMapletics/Mapletics_Organization/openclaw-infra/ansible/group_vars/openclaw.yml)

## Current Sanji Delegation Model

`main` is allowed to delegate to:

- `manfred`
- `claudia`
- `barney`
- `corby`
- `gordon`
- `deepseek-agent`

This is managed declaratively through `subagent_allow_agents` and written to `subagents.allowAgents` by:

- [main.yml](/Users/robinbeyer/GitMapletics/Mapletics_Organization/openclaw-infra/ansible/roles/agents/tasks/main.yml)

## Memory Model

The specialist agents already have separate workspaces and therefore separate session and memory state.

Examples from live config:

- `manfred` -> `/home/ubuntu/.openclaw/workspace-manfred`
- `claudia` -> `/home/ubuntu/.openclaw/workspace-claudia`
- `barney` -> `/home/ubuntu/.openclaw/workspace-barney`
- `main` -> `/home/ubuntu/.openclaw/workspace`
- `gordon` -> `/home/ubuntu/.openclaw/agents/gordon/workspace`

Implication:

- Delegation from `main` does not merge memory across agents.
- Each agent keeps its own `memory/YYYY-MM-DD.md` and session history.

## Live Changes Applied On 2026-04-01

### Routing

- Added declarative `openclaw_bindings` in `openclaw.yml`
- Moved binding application into the `agents` role so it no longer depends on the `telegram` role running
- Bound Slack `default` and Discord `default` to `main`
- Preserved Slack `gordon` routing to `gordon`

### Delegation

- Added declarative `subagent_allow_agents` for `main`
- Added Ansible tasks to write `subagents.allowAgents` for default and non-default agents

### Slack Stability

- Added cleanup of stale Slack sessions that carry model/auth overrides
- Kept the runtime monkeypatch that prevents sticky Slack session overrides from re-pinning model/auth state across turns

Relevant files:

- [openclaw.yml](/Users/robinbeyer/GitMapletics/Mapletics_Organization/openclaw-infra/ansible/group_vars/openclaw.yml)
- [main.yml](/Users/robinbeyer/GitMapletics/Mapletics_Organization/openclaw-infra/ansible/roles/agents/tasks/main.yml)
- [bindings.yml](/Users/robinbeyer/GitMapletics/Mapletics_Organization/openclaw-infra/ansible/roles/telegram/tasks/bindings.yml)
- [patch-slack-session-overrides.yml](/Users/robinbeyer/GitMapletics/Mapletics_Organization/openclaw-infra/ansible/roles/openclaw/tasks/patch-slack-session-overrides.yml)

## Discord Status

### What Is Configured

- `discordBotToken`, `discordGuildId`, and `discordUserId` are now present again in Pulumi `prod`
- `channels.discord` is present in live gateway config
- `main` has the default/frontdoor routing for Slack and the target heartbeat delivery for Discord

### What Was Broken

The gateway initially did not start a Discord provider even though:

- `discordBotToken`, `discordGuildId`, and `discordUserId` were restored
- `channels.discord` existed in live config
- `main` already had the Discord binding

### Root Cause

Discord was present in the bundled extensions, but the plugin was blocked by the gateway plugin allowlist.

Observed on 2026-04-01:

- `openclaw plugins list` showed `discord` as `disabled`
- `openclaw plugins inspect discord` reported `Error: not in allowlist`
- `plugins.allow` in the infra did not include `"discord"`

### Resolution

- Added `"discord"` to `plugins.allow` in:
  - [main.yml](/Users/robinbeyer/GitMapletics/Mapletics_Organization/openclaw-infra/ansible/roles/config/tasks/main.yml)
- Re-ran `./scripts/provision.sh --tags config`
- Restarted the gateway

### Current Live State

- `openclaw plugins list` shows `discord` as `loaded`
- `openclaw channels status --probe` shows:
  - `Discord default: enabled, configured, running, connected, bot:@DiscoClaw, works`
- `journalctl --user -u openclaw-gateway` now includes:
  - `[discord] [default] starting provider`
  - `[discord] logged in to discord as ... (DiscoClaw)`

## Gordon Status

Gordon remains reachable over Slack and should stay there for now.

Live expectations:

- Slack account `gordon` routes to agent `gordon`
- Gordon Slack channels currently require mention in the configured team channels

Important:

- do not use Discord migration work as a reason to change Gordon routing
- keep Gordon stable on Slack until Discord is independently working
- keep `main` as the only personal frontdoor agent ID

## Known Operational Risks

- the Slack sticky-session monkeypatch is version-sensitive and must be revalidated after every OpenClaw upgrade

## Current Recovery Commands

Check installed version:

```bash
ssh ubuntu@100.110.146.36 'npm list -g --depth=0 | grep openclaw'
```

Check live bindings:

```bash
ssh ubuntu@100.110.146.36 'XDG_RUNTIME_DIR=/run/user/1000 openclaw agents list --json --bindings'
```

Check channel status:

```bash
ssh ubuntu@100.110.146.36 'XDG_RUNTIME_DIR=/run/user/1000 openclaw channels status --probe'
```

Check Discord config:

```bash
ssh ubuntu@100.110.146.36 'XDG_RUNTIME_DIR=/run/user/1000 openclaw config get channels.discord'
```

Check gateway logs:

```bash
ssh ubuntu@100.110.146.36 'XDG_RUNTIME_DIR=/run/user/1000 journalctl --user -u openclaw-gateway -n 120 --no-pager | grep -Ei "discord|slack|starting provider|error|warn"'
```

## Next Recommended Work

1. Keep `plugins.allow` aligned with any bundled channel/provider plugins you expect to run; otherwise bundled plugins can remain silently disabled.
2. Revalidate the Slack sticky-session monkeypatch after every OpenClaw upgrade.
3. Extend Discord routing only after deciding whether you want more than one Discord-facing agent.
