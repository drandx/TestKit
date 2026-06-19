#!/usr/bin/env bash
# Install TestKit (Copilot CLI agents + .testkit scaffold) into a project.
#
# Two modes, auto-detected:
#   LOCAL  : run from a TestKit clone -> copies files from this checkout.
#   REMOTE : run via `curl -fsSL <raw>/install.sh | bash` -> downloads from GitHub.
#
# Usage:
#   ./install.sh [--target DIR] [--ref BRANCH] [--force]
#   curl -fsSL https://raw.githubusercontent.com/drandx/testkit/main/install.sh | bash
set -euo pipefail

REPO="drandx/testkit"
TARGET="$(pwd)"
REF="main"
FORCE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --ref)    REF="$2"; shift 2 ;;
    --force)  FORCE=1; shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

RAW_BASE="https://raw.githubusercontent.com/${REPO}/${REF}"

# Detect mode from this script's own location.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [ -n "${SCRIPT_DIR:-}" ] && [ -f "${SCRIPT_DIR}/.testkit/manifest.txt" ]; then
  MODE="LOCAL"
else
  MODE="REMOTE"
fi

echo "TestKit installer (${MODE} mode) -> ${TARGET}"

# Load manifest.
if [ "$MODE" = "LOCAL" ]; then
  MANIFEST="$(cat "${SCRIPT_DIR}/.testkit/manifest.txt")"
else
  MANIFEST="$(curl -fsSL "${RAW_BASE}/.testkit/manifest.txt")"
fi

installed=0; skipped=0
while IFS= read -r rel; do
  rel="$(echo "$rel" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  [ -z "$rel" ] && continue
  case "$rel" in \#*) continue ;; esac

  dest="${TARGET}/${rel}"
  mkdir -p "$(dirname "$dest")"

  if [ -f "$dest" ] && [ "$FORCE" -ne 1 ]; then
    echo "  skip   $rel (exists; use --force to overwrite)"
    skipped=$((skipped+1))
    continue
  fi

  if [ "$MODE" = "LOCAL" ]; then
    cp "${SCRIPT_DIR}/${rel}" "$dest"
  else
    curl -fsSL "${RAW_BASE}/${rel}" -o "$dest"
  fi
  echo "  add    $rel"
  installed=$((installed+1))
done <<< "$MANIFEST"

echo ""
echo "Done. ${installed} installed, ${skipped} skipped."
echo "Next: open this project in GitHub Copilot CLI and run:"
echo "  /testkit.scenarios <spec-dir>"
