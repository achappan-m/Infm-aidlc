#!/usr/bin/env bash
# Runs the review-agent against a diff via the Anthropic API and posts the
# report to the PR. Fails the build if the Blocking section is non-empty.
set -euo pipefail

DIFF_FILE="${1:?usage: run_review_agent.sh <diff-file>}"
: "${ANTHROPIC_API_KEY:?ANTHROPIC_API_KEY not set}"

SYSTEM="$(cat .claude/agents/review-agent.md) \n\n PROJECT CONTEXT: $(cat CLAUDE.md)"
DIFF="$(cat "$DIFF_FILE")"

REPORT="$(curl -s https://api.anthropic.com/v1/messages \
  -H "x-api-key: ${ANTHROPIC_API_KEY}" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d "$(jq -n --arg sys "$SYSTEM" --arg diff "$DIFF" '{
        model: "claude-sonnet-4-20250514",
        max_tokens: 2000,
        system: $sys,
        messages: [ { role: "user", content: ("Review this diff:\n\n" + $diff) } ]
      }')" | jq -r '.content[0].text')"

echo "$REPORT"

# Fail the gate if the agent flagged anything Blocking.
if echo "$REPORT" | grep -qiE '^\s*#*\s*Blocking' && \
   echo "$REPORT" | grep -A3 -iE 'Blocking' | grep -qE '\S'; then
  echo "::error::Review agent flagged blocking issues."
  exit 1
fi
