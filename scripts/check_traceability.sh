#!/usr/bin/env bash
# Traceability gate: a behaviour change (src/) must have a matching spec.
set -euo pipefail
CHANGED_SRC="$(git diff --name-only origin/main...HEAD | grep -E 'src/main' || true)"
if [ -n "$CHANGED_SRC" ]; then
  if [ -z "$(git diff --name-only origin/main...HEAD | grep -E 'docs/specs/' || true)" ]; then
    echo "::error::Source changed but no spec found under docs/specs/."
    exit 1
  fi
fi
echo "Traceability OK."
