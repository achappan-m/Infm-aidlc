#!/usr/bin/env bash
# run_review_agent.sh
#
# Invokes the review-agent via the Anthropic API and posts a structured
# findings report as a PR comment. Fails (exit 1) if blocker-level findings
# are present. Humans still give final PR approval — nothing auto-merges.
#
# Required env vars (all set automatically by aidlc.yml):
#   ANTHROPIC_API_KEY   — Anthropic API key (repository secret)
#   GH_TOKEN            — GitHub token
#   PR_NUMBER           — pull request number
#   BASE_REF            — base branch (e.g. main)
#   GITHUB_REPOSITORY   — owner/repo

set -euo pipefail

: "${ANTHROPIC_API_KEY:?ANTHROPIC_API_KEY secret is required}"
: "${GH_TOKEN:?GH_TOKEN is required}"
: "${PR_NUMBER:?PR_NUMBER is required}"
: "${BASE_REF:?BASE_REF is required}"
: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"

REPO_ROOT="$(git rev-parse --show-toplevel)"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

AGENT_FILE="${REPO_ROOT}/.claude/agents/review-agent.md"
CONTEXT_FILE="${REPO_ROOT}/CLAUDE.md"
DIFF_LIMIT_BYTES=40960   # 40 KB — keeps prompt within context limits
MODEL="claude-sonnet-4-6"
MAX_TOKENS=4096

echo "=== OrderFlow AI-DLC: AI Review Gate (PR #${PR_NUMBER}) ==="

# ── 1. Collect the diff ───────────────────────────────────────────────────────

echo "Collecting diff against origin/${BASE_REF}..."
git diff "origin/${BASE_REF}...HEAD" > "${WORK_DIR}/diff.txt"

diff_size=$(wc -c < "${WORK_DIR}/diff.txt")
if (( diff_size > DIFF_LIMIT_BYTES )); then
  echo "Diff is ${diff_size} bytes — truncating to ${DIFF_LIMIT_BYTES} bytes."
  head -c "$DIFF_LIMIT_BYTES" "${WORK_DIR}/diff.txt" > "${WORK_DIR}/diff_trunc.txt"
  printf '\n\n[... diff truncated at %d bytes — see full diff on GitHub ...]\n' \
    "$DIFF_LIMIT_BYTES" >> "${WORK_DIR}/diff_trunc.txt"
  mv "${WORK_DIR}/diff_trunc.txt" "${WORK_DIR}/diff.txt"
fi

# ── 2. Locate spec and design documents ───────────────────────────────────────
# Prefer the file most recently modified in this PR; fall back to the newest
# file in the directory so the gate still runs even on partial setups.

find_latest_in_pr() {
  local dir="$1" pattern="$2"
  # Files changed in this PR that match the directory and pattern
  local in_pr
  in_pr=$(git diff --name-only "origin/${BASE_REF}...HEAD" \
    | grep -E "^${dir}/.*${pattern}$" || true)
  if [[ -n "$in_pr" ]]; then
    echo "${REPO_ROOT}/$(echo "$in_pr" | head -1)"
    return
  fi
  # Fall back to newest file on disk
  if [[ -d "${REPO_ROOT}/${dir}" ]]; then
    find "${REPO_ROOT}/${dir}" -name "*${pattern}" -printf '%T@ %p\n' 2>/dev/null \
      | sort -rn | head -1 | awk '{print $2}'
  fi
}

spec_file=$(find_latest_in_pr "docs/specs" ".md")
design_file=$(find_latest_in_pr "docs/designs" ".md")

if [[ -n "$spec_file" && -f "$spec_file" ]]; then
  echo "Using spec:   ${spec_file}"
  spec_content=$(cat "$spec_file")
else
  echo "Warning: no spec found in docs/specs/ — review-agent will flag this."
  spec_content="NOT PROVIDED — flag as blocker: no approved spec was supplied to this gate."
fi

if [[ -n "$design_file" && -f "$design_file" ]]; then
  echo "Using design: ${design_file}"
  design_content=$(cat "$design_file")
else
  echo "Warning: no design found in docs/designs/ — review-agent will flag this."
  design_content="NOT PROVIDED — flag as blocker: no approved design was supplied to this gate."
fi

# ── 3. Build the system prompt ────────────────────────────────────────────────
# Strip the YAML frontmatter from the agent file, then append CLAUDE.md so the
# agent is grounded in the project context.

if [[ ! -f "$AGENT_FILE" ]]; then
  echo "::error::${AGENT_FILE} not found. Cannot run review-agent."
  exit 1
fi

awk 'BEGIN{n=0} /^---/{n++; if(n==2){found=1; next}} found{print}' \
  "$AGENT_FILE" > "${WORK_DIR}/agent_body.txt"

{
  cat "${WORK_DIR}/agent_body.txt"
  echo ""
  echo "---"
  echo "## Project context (CLAUDE.md)"
  echo ""
  cat "$CONTEXT_FILE"
} > "${WORK_DIR}/system.txt"

# ── 4. Build the user message ─────────────────────────────────────────────────

pr_body=$(gh pr view "$PR_NUMBER" \
  --repo "$GITHUB_REPOSITORY" \
  --json body,title \
  --jq '"PR #\(.number // "") — \(.title // "")\n\n\(.body // "")"' 2>/dev/null \
  || echo "PR #${PR_NUMBER}")

{
  printf '%s\n\n' "$pr_body"
  echo "## Approved Spec"
  echo ""
  printf '%s\n\n' "$spec_content"
  echo "## Approved Design"
  echo ""
  printf '%s\n\n' "$design_content"
  echo "## Diff"
  echo ""
  cat "${WORK_DIR}/diff.txt"
} > "${WORK_DIR}/user.txt"

# ── 5. Call the Anthropic API ─────────────────────────────────────────────────

echo "Calling Anthropic API (model: ${MODEL})..."

payload=$(jq -n \
  --rawfile system "${WORK_DIR}/system.txt" \
  --rawfile user   "${WORK_DIR}/user.txt" \
  --arg     model  "$MODEL" \
  --argjson tokens "$MAX_TOKENS" \
  '{
    model:      $model,
    max_tokens: $tokens,
    system:     $system,
    messages:   [{ role: "user", content: $user }]
  }')

http_response=$(curl -s -w "\n__STATUS__%{http_code}" \
  "https://api.anthropic.com/v1/messages" \
  -H "x-api-key: ${ANTHROPIC_API_KEY}" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d "$payload")

http_body=$(echo "$http_response" | sed '$d')
http_status=$(echo "$http_response" | tail -1 | sed 's/__STATUS__//')

if [[ "$http_status" != "200" ]]; then
  err_msg=$(echo "$http_body" | jq -r '.error.message // "unknown error"' 2>/dev/null \
    || echo "$http_body")
  echo "::error::Anthropic API returned HTTP ${http_status}: ${err_msg}"
  exit 1
fi

review_output=$(echo "$http_body" | jq -r '.content[0].text')

if [[ -z "$review_output" ]]; then
  echo "::error::Empty response from Anthropic API."
  exit 1
fi

# ── 6. Post findings as a PR comment ─────────────────────────────────────────

echo "Posting findings as PR comment..."

{
  echo "## AI-DLC — review-agent pre-vet report"
  echo ""
  echo "> **Automated pre-vet only.** This report surfaces findings for the human reviewer."
  echo "> Humans give final PR approval — this gate does not merge anything."
  echo ""
  echo "$review_output"
  echo ""
  echo "---"
  echo "*Generated by [\`review-agent\`](.claude/agents/review-agent.md) · Model: \`${MODEL}\`*"
} > "${WORK_DIR}/comment.txt"

gh pr comment "$PR_NUMBER" \
  --repo "$GITHUB_REPOSITORY" \
  --body-file "${WORK_DIR}/comment.txt"

echo "Comment posted to PR #${PR_NUMBER}."

# ── 7. Determine exit code ────────────────────────────────────────────────────
# The review-agent formats blocker rows as "| B-N | ..." in a markdown table.

blocker_count=$(echo "$review_output" | grep -cE "^\| B-[0-9]+" || true)

if (( blocker_count > 0 )); then
  echo ""
  echo "::error title=AI Review Gate Failed::review-agent found ${blocker_count} blocker(s)."
  echo "::error::Resolve all blockers before requesting human review."
  echo "::error::Full findings are in the PR comment."
  exit 1
fi

echo ""
echo "✅ review-agent found no blockers. Human review can proceed."
exit 0
