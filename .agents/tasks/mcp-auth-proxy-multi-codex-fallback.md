# Task — Multi-account Codex fallback in MCP Auth Proxy

## Goal
Extend the MCP auth proxy so each agent can use multiple Codex auth profiles with ordered fallback instead of exactly one auth file.

## Hard requirement
- `main` / Sanji must always prefer `beyer@mapletics.com` first.

## Account pool
- A = `beyer@mapletics.com`
- B = second ChatGPT/Codex account
- C = third ChatGPT/Codex account

## Desired routing
- `main` -> A -> B -> C
- `manfred` -> B -> C -> A
- `barney` -> C -> A -> B
- `gordon` stays separate for now

## Source of truth
Do **not** patch only the live server copy.
Change the Ansible-managed source:
- `ansible/roles/plugins/templates/mcp-auth-proxy.js.j2`
- `ansible/roles/plugins/templates/mcp-auth-proxy.service.j2`
- `ansible/roles/plugins/tasks/main.yml`

## Current config format
```json
{
  "default": "/home/ubuntu/.codex/auth.json",
  "agents": {
    "gordon": "/home/ubuntu/.codex/auth-gordon.json"
  }
}
```

## Target config format (backward-compatible)
Accept both `string` and `string[]`.

Example:
```json
{
  "default": [
    "/home/ubuntu/.codex/auth-codex-a.json",
    "/home/ubuntu/.codex/auth-codex-b.json",
    "/home/ubuntu/.codex/auth-codex-c.json"
  ],
  "agents": {
    "main": [
      "/home/ubuntu/.codex/auth-codex-a.json",
      "/home/ubuntu/.codex/auth-codex-b.json",
      "/home/ubuntu/.codex/auth-codex-c.json"
    ],
    "manfred": [
      "/home/ubuntu/.codex/auth-codex-b.json",
      "/home/ubuntu/.codex/auth-codex-c.json",
      "/home/ubuntu/.codex/auth-codex-a.json"
    ],
    "barney": [
      "/home/ubuntu/.codex/auth-codex-c.json",
      "/home/ubuntu/.codex/auth-codex-a.json",
      "/home/ubuntu/.codex/auth-codex-b.json"
    ],
    "gordon": [
      "/home/ubuntu/.codex/auth-gordon.json"
    ]
  }
}
```

## Required implementation changes

### 1. Parser / normalization
- Extend `normalizeCodexAuthMap()` to accept `string` and `string[]`
- Normalize internally to arrays only
- Preserve backward compatibility

### 2. Candidate resolution
Replace single-auth resolution with ordered candidate resolution.

Current concept:
- `resolveCodexAuth(agentId)`

Target concept:
- `resolveCodexCandidates(agentId)`

Return structure should include:
- `agentId`
- ordered list of candidates
- unique `authKey` per candidate, e.g. `main#0`, `main#1`

### 3. Candidate selection
Add logic to:
- iterate candidates in priority order
- skip candidates with open circuit / cooldown
- choose the first healthy candidate
- fail cleanly if none are available

### 4. Error classification
Fallback should happen on:
- `429` / rate limit
- upstream timeout
- upstream `5xx`
- temporary auth / refresh failures

Fallback should **not** happen on:
- malformed request
- content / policy errors
- other non-account-specific request failures

### 5. Cooldown / circuit handling
Track state per candidate, not just per agent.

Suggested cooldowns:
- rate limit -> 15 min
- timeout / `5xx` -> 3 min
- temporary auth failure -> 5 min
- permanent auth failure -> 12 h

### 6. Structured logging
Log:
- selected candidate
- fallback event
- fallback reason
- cooldown open / clear

No token leakage in logs.

### 7. `/health` endpoint
Expose candidate-level health, not just one auth path per agent.

## Suggested helper functions
- `normalizeAuthEntry(value, fallback = [])`
- `resolveCodexCandidates(agentId)`
- `selectCodexCandidate(agentId)`
- `classifyCodexFailure(...)`
- `getCooldownDuration(reason)`
- `openCircuit(authKey, reason, durationMs)`

## Rollout plan
1. Implement parser + candidate selection
2. Deploy with `main` only
3. Verify health + fallback behavior
4. Enable `manfred`
5. Enable `barney`
6. Leave `gordon` separate until stable

## Test plan
- parser accepts old and new config formats
- `main` always prefers account A first
- fallback occurs when A is rate-limited
- cooldown prevents immediate reuse of exhausted account
- health endpoint shows candidate state clearly
- restart path works via systemd after Ansible deploy

## Acceptance criteria
- multiple ordered Codex auth paths per agent supported
- old config format still works unchanged
- `main` prefers `beyer@mapletics.com`
- automatic fallback works on rate limits / temp failures
- no token leakage in logs
- rollout can be enabled gradually per agent

---

## 2026-04-08 — current live special state on VPS

This is the pragmatic live setup Rob currently wants preserved. It is **not** the broad multi-account rollout for every agent.

### Effective live account routing
- `main` / Sanji
  - model: `openai-codex/gpt-5.4`
  - account chain: `selenka@mapletics.com` only
- `manfred`
  - model: `openai-codex/gpt-5.4`
  - account chain: `rbeyer1@smail.uni-koeln.de` only
- `barney`
  - model: `openai-codex/gpt-5.4`
  - account chain: `selenka@mapletics.com` only
- `claudia`
  - model: `openai-codex/gpt-5.4`
  - account chain: `selenka@mapletics.com` only
- `gordon`
  - model: `openai-codex/gpt-5.4-mini`
  - model fallbacks: `openrouter/free`
  - account chain:
    1. `rbeyer1@smail.uni-koeln.de`
    2. `sanjicook803@gmail.com`
    3. `info@mapletics.com`

### Auth file handling
Keep human-readable aliases under `~/.codex/profiles/` so Rob can switch accounts manually without hunting through per-agent files.

Expected alias files:
- `auth-selenka.json`
- `auth-rbeyer1.json`
- `auth-sanjicook803.json`
- `auth-info.json`

Also keep a deduplicated catalog of unique snapshots under:
- `~/.codex/profile-catalog/`

### Important note
The repo source-of-truth was previously moved toward broad per-agent 5-slot multi-account fallback. The live VPS was later simplified for stability. Future deploys should not blindly restore the old broad fallback layout without checking Rob first.
