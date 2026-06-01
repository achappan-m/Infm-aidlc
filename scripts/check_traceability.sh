#!/usr/bin/env bash
# check_traceability.sh
#
# Traceability gate: fails if production source files were changed in this PR
# without a corresponding spec reference.
#
# A spec reference is satisfied by either:
#   (a) A line matching "Spec: ..." in the PR description, OR
#   (b) At least one file under docs/specs/*.md added or modified in this PR.
#
# Required env vars (all set automatically by aidlc.yml):
#   GH_TOKEN            — GitHub token
#   PR_NUMBER           — pull request number
#   BASE_REF            — base branch name (e.g. main)
#   GITHUB_REPOSITORY   — owner/repo

set -euo pipefail

: "${GH_TOKEN:?GH_TOKEN is required}"
: "${PR_NUMBER:?PR_NUMBER is required}"
: "${BASE_REF:?BASE_REF is required}"
: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"

# ── Helpers ───────────────────────────────────────────────────────────────────

pass() { echo "✅ Traceability gate PASSED: $*"; exit 0; }

fail() {
  echo ""
  echo "::error title=Traceability Gate Failed::$*"
  echo ""
  echo "How to fix — choose one:"
  echo "  Option A: Add a spec reference to the PR description:"
  echo "            Spec: <title of the approved spec>"
  echo "  Option B: Include a modified or new docs/specs/*.md file in this PR."
  echo ""
  echo "Every code change must trace back to an approved spec (AI-DLC rule)."
  exit 1
}

# ── 1. Collect changed files ──────────────────────────────────────────────────

echo "=== OrderFlow AI-DLC: Traceability Gate (PR #${PR_NUMBER}) ==="
echo "Collecting changed files against origin/${BASE_REF}..."

changed_files=$(git diff --name-only "origin/${BASE_REF}...HEAD")

if [[ -z "$changed_files" ]]; then
  pass "No changed files detected."
fi

# ── 2. Detect production source changes ───────────────────────────────────────
# Matches backend (*/src/main/java/) and Angular frontend (*/src/app/) paths.
# Test-only changes (*/src/test/) do not require a spec reference.

src_changed=false
src_files_list=""

while IFS= read -r f; do
  if [[ "$f" =~ ^[a-z-]+-service/src/main/ ]] || \
     [[ "$f" =~ ^[a-z-]+-service/src/app/ ]]; then
    src_changed=true
    src_files_list="${src_files_list}    ${f}\n"
  fi
done <<< "$changed_files"

if [[ "$src_changed" == "false" ]]; then
  pass "No production source changes — traceability check not required."
fi

echo "Production source changes detected:"
printf "%b" "$src_files_list"
echo ""
echo "Checking for spec reference..."

# ── 3a. PR description contains "Spec: <title>" ───────────────────────────────

pr_body=$(gh pr view "$PR_NUMBER" \
  --repo "$GITHUB_REPOSITORY" \
  --json body \
  --jq '.body // ""')

if echo "$pr_body" | grep -qiE "^[[:space:]]*(spec|specification)[[:space:]]*:"; then
  matched=$(echo "$pr_body" \
    | grep -iE "^[[:space:]]*(spec|specification)[[:space:]]*:" \
    | head -1 \
    | sed 's/^[[:space:]]*//')
  pass "Spec reference found in PR description: \"${matched}\""
fi

# ── 3b. A docs/specs/*.md file was modified in this PR ───────────────────────

spec_files=$(echo "$changed_files" | grep -E "^docs/specs/[^/]+\.md$" || true)

if [[ -n "$spec_files" ]]; then
  pass "Spec file modified in this PR:$(echo "$spec_files" | sed 's/^/  /')"
fi

# ── 4. Nothing satisfied — fail ───────────────────────────────────────────────

fail "Production source files changed but no spec reference was found.
Changed source files:
$(printf "%b" "$src_files_list")"
