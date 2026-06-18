# OpenClaw Codex Account Switch

This runbook documents how to switch the Codex account used by OpenClaw and how to fix the Discord-facing gateway when it still uses the old account.

## Summary

- Local desktop OpenClaw and Discord/OpenClaw gateway are separate states.
- Updating `~/.openclaw/.../auth-profiles.json` locally is not enough for Discord.
- Discord uses the remote gateway state on the VPS.
- The effective fix was updating the remote `main` agent auth profile and restarting `openclaw-gateway`.

## When To Use This

Use this runbook if:

- OpenClaw should stop using one Codex account and start using another one
- the auth JSON for the target account already exists locally in `~/.codex`
- Discord still shows the old account after a local switch

## Target Files

Local desktop state:

- `~/.openclaw/agents/main/agent/auth-profiles.json`
- `~/.codex/auth-<email>.json`

Remote gateway state:

- `/home/ubuntu/.openclaw/agents/main/agent/auth-profiles.json`

## Example Migration

This was used to switch:

- from: `selenka`
- to: `rbeyer1`

Verified target identity:

- `accountId`: `9ff478ed-9dc1-462b-8c87-0b1ca58dc017`
- `email`: `rbeyer1@smail.uni-koeln.de`

## Procedure

### 1. Update local OpenClaw auth

Copy the target Codex auth from `~/.codex/auth-<email>.json` into the local OpenClaw profile store and set `openai-codex:default` to the target account.

Recommended safety step:

- create a backup of `~/.openclaw/agents/main/agent/auth-profiles.json` first

Why:

- this fixes local OpenClaw usage
- it does not fix Discord by itself

### 2. Verify whether Discord is actually remote

If Discord still shows the old account, inspect the VPS directly instead of assuming the local file is authoritative.

Check the remote auth file:

```bash
ssh ubuntu@100.110.146.36 \
  'sed -n "1,220p" ~/.openclaw/agents/main/agent/auth-profiles.json'
```

If `openai-codex:default` still points to the old account on the VPS, Discord is still running against stale remote auth.

### 3. Update the remote `main` agent auth profile

Set the remote `openai-codex:default` entry to the target account. In this incident, that meant replacing the old `selenka` profile on the VPS with the `rbeyer1` profile.

Important:

- update the remote file for `main`
- preserve the rest of the JSON structure
- do not assume provisioning already applied the change

### 4. Restart the gateway

After changing the remote auth file, restart the user service:

```bash
ssh ubuntu@100.110.146.36 \
  'XDG_RUNTIME_DIR=/run/user/1000 systemctl --user restart openclaw-gateway'
```

Confirm the service is healthy:

```bash
ssh ubuntu@100.110.146.36 \
  'XDG_RUNTIME_DIR=/run/user/1000 systemctl --user is-active openclaw-gateway'
```

Expected output:

```text
active
```

### 5. Verify the remote account identity

After restart, verify the effective remote profile:

```bash
ssh ubuntu@100.110.146.36 'python3 - <<'"'"'PY'"'"'
import json
from pathlib import Path

data = json.loads(Path("/home/ubuntu/.openclaw/agents/main/agent/auth-profiles.json").read_text())
profile = data["profiles"]["openai-codex:default"]
print(profile.get("accountId"))
print(profile.get("emailAddress"))
PY'
```

Expected values for the example migration:

```text
9ff478ed-9dc1-462b-8c87-0b1ca58dc017
rbeyer1@smail.uni-koeln.de
```

## Root Cause In This Incident

The local switch succeeded, but Discord did not change because:

- Discord traffic was handled by the remote OpenClaw gateway on `100.110.146.36`
- the remote `main` agent still had `openai-codex:default` pointing at `selenka`

So the local fix was correct but incomplete.

## Expected Outcome

After the remote auth update and gateway restart:

- local OpenClaw uses the target account
- Discord uses the same target account
- new Discord requests resolve under the updated remote `main` profile

## Common Failure Modes

### Local file updated, Discord still wrong

Most likely cause:

- only the local file changed
- the remote gateway still has the old auth profile

### Provisioning did not apply the change

If `./scripts/provision.sh --tags config` does not complete cleanly, verify the VPS file directly and patch the remote state manually if necessary.

### Service restarted but old behavior persists

Possible causes:

- a long-lived Discord session was still being reused
- the gateway restart did not actually succeed
- the wrong agent profile was edited

First checks:

```bash
ssh ubuntu@100.110.146.36 \
  'XDG_RUNTIME_DIR=/run/user/1000 systemctl --user is-active openclaw-gateway'

ssh ubuntu@100.110.146.36 \
  'sed -n "1,220p" ~/.openclaw/agents/main/agent/auth-profiles.json'
```

## Minimal Recovery Checklist

1. Verify local `~/.openclaw/agents/main/agent/auth-profiles.json`
2. Verify remote `/home/ubuntu/.openclaw/agents/main/agent/auth-profiles.json`
3. Ensure remote `openai-codex:default` points to the target account
4. Restart `openclaw-gateway`
5. Re-check remote `accountId` and `emailAddress`
6. Test with a fresh Discord message

## Related Docs

- [AGENT-ROUTING-AND-DISCORD-STATUS.md](/Users/robinbeyer/GitMapletics/Mapletics_Organization/openclaw-infra/docs/AGENT-ROUTING-AND-DISCORD-STATUS.md)
- [TROUBLESHOOTING.md](/Users/robinbeyer/GitMapletics/Mapletics_Organization/openclaw-infra/docs/TROUBLESHOOTING.md)
