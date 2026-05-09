#!/usr/bin/env bash
set -euo pipefail

REPO_SLUG="milo2048/claude-plugins-marketplace"
MARKETPLACE_NAME="milo2048-plugins"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="${SCRIPT_DIR}/.claude-plugin/marketplace.json"

if ! command -v claude >/dev/null 2>&1; then
  echo "error: 'claude' CLI not found on PATH" >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "error: 'jq' is required to parse ${MANIFEST}" >&2
  exit 1
fi
if [[ ! -f "${MANIFEST}" ]]; then
  echo "error: marketplace manifest not found at ${MANIFEST}" >&2
  exit 1
fi

echo "==> Adding marketplace: ${REPO_SLUG}"
if claude plugin marketplace list 2>/dev/null | grep -qw "${MARKETPLACE_NAME}"; then
  echo "    already registered — skipping add"
else
  claude plugin marketplace add "${REPO_SLUG}"
fi

echo "==> Installing plugins from ${MARKETPLACE_NAME}"
while IFS= read -r plugin; do
  echo "    -> ${plugin}@${MARKETPLACE_NAME}"
  claude plugin install "${plugin}@${MARKETPLACE_NAME}"
done < <(jq -r '.plugins[].name' "${MANIFEST}")

echo "==> Done. Restart Claude Code to load the new plugins."
