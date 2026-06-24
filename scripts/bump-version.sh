#!/usr/bin/env bash
#
# Bump the plugin version in both manifests so installed clients receive the update.
#
# Usage: ./scripts/bump-version.sh <new-version>   e.g. ./scripts/bump-version.sh 1.0.1
#
# Updates, in lockstep:
#   - .claude-plugin/plugin.json            -> .version
#   - .claude-plugin/marketplace.json       -> .version (the marketplace itself)
#   - .claude-plugin/marketplace.json       -> .plugins[name=="crispa-config"].version
#
set -euo pipefail

NEW_VERSION="${1:-}"
if [ -z "$NEW_VERSION" ]; then
  echo "Usage: $0 <new-version>   (e.g. $0 1.0.1)" >&2
  exit 1
fi
if ! printf '%s' "$NEW_VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+([-+].+)?$'; then
  echo "Error: '$NEW_VERSION' is not valid semver (expected MAJOR.MINOR.PATCH)." >&2
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN="$ROOT/.claude-plugin/plugin.json"
MARKET="$ROOT/.claude-plugin/marketplace.json"
PLUGIN_NAME="crispa-config"

NEW_VERSION="$NEW_VERSION" PLUGIN="$PLUGIN" MARKET="$MARKET" PLUGIN_NAME="$PLUGIN_NAME" python3 - <<'PY'
import json, os

new = os.environ["NEW_VERSION"]
plugin_path = os.environ["PLUGIN"]
market_path = os.environ["MARKET"]
name = os.environ["PLUGIN_NAME"]

with open(plugin_path) as f:
    plugin = json.load(f)
plugin["version"] = new
with open(plugin_path, "w") as f:
    json.dump(plugin, f, indent=2)
    f.write("\n")

with open(market_path) as f:
    market = json.load(f)
market["version"] = new
found = False
for p in market.get("plugins", []):
    if p.get("name") == name:
        p["version"] = new
        found = True
with open(market_path, "w") as f:
    json.dump(market, f, indent=2)
    f.write("\n")

if not found:
    raise SystemExit(f"Error: plugin '{name}' not found in {market_path}")
print(f"Bumped {name} to {new}")
print(f"  - {plugin_path}")
print(f"  - {market_path} (marketplace + plugin entry)")
PY
