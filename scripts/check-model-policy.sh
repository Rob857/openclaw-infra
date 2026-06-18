#!/bin/bash
#
# Validate the remote OpenClaw model policy against the live model catalog.
#
# Usage:
#   ./scripts/check-model-policy.sh
#   ./scripts/check-model-policy.sh openclaw-vps-1.tail123.ts.net
#
# Exit codes:
#   0 = no hard failures
#   1 = validation failure or connectivity problem

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_pass() {
    echo -e "${GREEN}✓ $1${NC}"
}

check_fail() {
    echo -e "${RED}✗ $1${NC}"
}

check_warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

if [ $# -gt 1 ]; then
    echo "Usage: $0 [full-hostname]"
    exit 1
fi

HOST_ARG="${1:-}"
HOSTNAME_PREFIX="${OPENCLAW_HOSTNAME:-openclaw-vps}"
TAILNET="${TAILNET:-}"

if [ -z "$HOST_ARG" ]; then
    if [ -z "$TAILNET" ]; then
        TAILNET=$(tailscale status --json 2>/dev/null | jq -r '.MagicDNSSuffix // empty' || true)
    fi

    if [ -z "$TAILNET" ]; then
        echo "ERROR: Could not detect tailnet. Set TAILNET or pass the full hostname."
        exit 1
    fi

    DETECTED_HOSTNAME=$(tailscale status 2>/dev/null | grep -E "${HOSTNAME_PREFIX}(-[0-9]+)?" | grep -v "offline" | grep -oE "${HOSTNAME_PREFIX}(-[0-9]+)?" | head -1 || true)
    if [ -z "$DETECTED_HOSTNAME" ]; then
        DETECTED_HOSTNAME=$(tailscale status 2>/dev/null | grep -oE "${HOSTNAME_PREFIX}(-[0-9]+)?" | head -1 || true)
    fi
    if [ -z "$DETECTED_HOSTNAME" ]; then
        echo "ERROR: Could not detect OpenClaw host via Tailscale."
        exit 1
    fi
    FULL_HOSTNAME="${DETECTED_HOSTNAME}.${TAILNET}"
else
    FULL_HOSTNAME="$HOST_ARG"
fi

echo "Checking model policy on ${FULL_HOSTNAME}..."

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

REMOTE_SCRIPT=$(cat <<'EOF'
set -euo pipefail
export XDG_RUNTIME_DIR=/run/user/1000
python3 - <<'PY'
import json
import subprocess

def parse_json_command(cmd):
    raw = subprocess.check_output(cmd, text=True, stderr=subprocess.STDOUT)
    start = raw.find("{")
    if start == -1:
        start = raw.find("[")
    if start == -1:
        raise RuntimeError(f"No JSON found in output for: {' '.join(cmd)}\n{raw}")
    decoder = json.JSONDecoder()
    obj, _ = decoder.raw_decode(raw[start:])
    return obj

status = parse_json_command(["bash", "-lc", "XDG_RUNTIME_DIR=/run/user/1000 openclaw models status --json"])
catalog = parse_json_command(["bash", "-lc", "XDG_RUNTIME_DIR=/run/user/1000 openclaw models list --all --json"])

models = catalog["models"] if isinstance(catalog, dict) else catalog
keys = {m.get("key") for m in models if m.get("key")}
available_keys = {m.get("key") for m in models if m.get("key") and m.get("available") is True}

configured = []
for key_name in ("defaultModel", "resolvedDefault"):
    value = status.get(key_name)
    if value:
        configured.append({"source": key_name, "key": value})

for value in status.get("fallbacks", []):
    configured.append({"source": "fallback", "key": value})

for value in status.get("allowed", []):
    configured.append({"source": "allowed", "key": value})

provider_latest = {}
for model in models:
    key = model.get("key")
    if not key or "/" not in key:
        continue
    provider = key.split("/", 1)[0]
    if provider not in ("anthropic", "openai-codex", "openai", "deepseek"):
        continue
    if not model.get("available"):
        continue
    provider_latest.setdefault(provider, [])
    provider_latest[provider].append({"key": key, "name": model.get("name") or ""})

print(json.dumps({
    "status": status,
    "catalog_count": len(models),
    "configured": configured,
    "known_keys": sorted(keys),
    "available_keys": sorted(available_keys),
    "provider_latest": provider_latest,
}))
PY
EOF
)

REPORT_JSON=$(ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new "ubuntu@$FULL_HOSTNAME" "$REMOTE_SCRIPT")
printf '%s\n' "$REPORT_JSON" > "$TMPDIR/report.json"

VALIDATION=$(REPORT_PATH="$TMPDIR/report.json" python3 - <<'PY'
import json
import os

with open(os.environ["REPORT_PATH"]) as f:
    report = json.load(f)

status = report["status"]
known_keys = set(report["known_keys"])
available_keys = set(report["available_keys"])
provider_latest = report["provider_latest"]

failures = []
warnings = []
notes = []

default_model = status.get("defaultModel")
resolved_default = status.get("resolvedDefault")
fallbacks = status.get("fallbacks", [])
allowed = status.get("allowed", [])
configured = report["configured"]

if not default_model:
    failures.append("No defaultModel configured.")

for entry in configured:
    model = entry["key"]
    source = entry["source"]
    if model not in known_keys:
        failures.append(f"{source}: unknown model id '{model}'")
    elif source in ("defaultModel", "resolvedDefault", "fallback") and model not in available_keys:
        warnings.append(f"{source}: model '{model}' is known but not currently available with configured auth")

if default_model and resolved_default and default_model != resolved_default:
    warnings.append(f"defaultModel '{default_model}' resolves to '{resolved_default}'")

if allowed:
    stale_allowed = [model for model in allowed if model not in available_keys]
    if stale_allowed:
        failures.append("allowed model list contains stale/unavailable ids: " + ", ".join(stale_allowed))
    if default_model and default_model not in allowed:
        warnings.append(f"defaultModel '{default_model}' is not in allowed list")
    missing_fallbacks = [model for model in fallbacks if model not in allowed]
    if missing_fallbacks:
        warnings.append("fallbacks missing from allowed list: " + ", ".join(missing_fallbacks))
else:
    notes.append("No allowlist configured via agents.defaults.models; OpenClaw is not filtering new catalog entries there.")

interesting = []
if default_model:
    interesting.append(default_model)
interesting.extend(fallbacks)
for model in interesting:
    if not model or "/" not in model:
        continue
    provider = model.split("/", 1)[0]
    latest = provider_latest.get(provider) or []
    if not latest:
        continue
    if model in {entry["key"] for entry in latest}:
        continue
    newer = [entry["key"] for entry in latest if entry["key"] != model]
    if newer:
        warnings.append(f"{model} is not among the currently available top entries for provider '{provider}': " + ", ".join(newer[:5]))

auth = status.get("auth", {})
missing = auth.get("missingProvidersInUse", [])
if missing:
    failures.append("providers in use without auth: " + ", ".join(missing))

oauth_profiles = auth.get("oauth", {}).get("profiles", [])
expiring = []
for profile in oauth_profiles:
    state = profile.get("status")
    label = profile.get("label", profile.get("profileId", "unknown"))
    if state == "expiring":
        expiring.append(label)
    if state == "expired":
        failures.append("expired oauth profile: " + label)
if expiring:
    warnings.append("expiring oauth profiles: " + ", ".join(expiring))

print(json.dumps({
    "failures": failures,
    "warnings": warnings,
    "notes": notes,
    "defaultModel": default_model,
    "resolvedDefault": resolved_default,
    "fallbacks": fallbacks,
    "allowed": allowed,
}))
PY
)
printf '%s\n' "$VALIDATION" > "$TMPDIR/validation.json"

DEFAULT_MODEL=$(jq -r '.defaultModel // empty' "$TMPDIR/validation.json")
RESOLVED_DEFAULT=$(jq -r '.resolvedDefault // empty' "$TMPDIR/validation.json")

if [ -n "$DEFAULT_MODEL" ]; then
    check_pass "defaultModel: $DEFAULT_MODEL"
fi
if [ -n "$RESOLVED_DEFAULT" ] && [ "$RESOLVED_DEFAULT" != "$DEFAULT_MODEL" ]; then
    check_warn "resolvedDefault differs: $RESOLVED_DEFAULT"
fi

jq -r '.fallbacks[]? | "fallback: " + .' "$TMPDIR/validation.json" | sed 's/^/   /'
jq -r '.allowed[]? | "allowed: " + .' "$TMPDIR/validation.json" | sed 's/^/   /'

FAIL_COUNT=$(jq '.failures | length' "$TMPDIR/validation.json")
WARN_COUNT=$(jq '.warnings | length' "$TMPDIR/validation.json")

if [ "$FAIL_COUNT" -gt 0 ]; then
    while IFS= read -r line; do
        check_fail "$line"
    done < <(jq -r '.failures[]' "$TMPDIR/validation.json")
fi

if [ "$WARN_COUNT" -gt 0 ]; then
    while IFS= read -r line; do
        check_warn "$line"
    done < <(jq -r '.warnings[]' "$TMPDIR/validation.json")
fi

if [ "$FAIL_COUNT" -eq 0 ] && [ "$WARN_COUNT" -eq 0 ]; then
    check_pass "Model policy looks consistent with the live OpenClaw catalog."
fi

while IFS= read -r line; do
    [ -n "$line" ] && echo "   note: $line"
done < <(jq -r '.notes[]' "$TMPDIR/validation.json")

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
fi
