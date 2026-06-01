---
name: review
description: Stage 5 — pre-vet the diff before a human reviewer sees it
---
Read .claude/agents/review-agent.md and CLAUDE.md.
Run: git diff origin/main...HEAD
Review the diff and produce a report grouped as Blocking / Should-fix / Nits.
Be specific with file and line. Do not approve — flag only.
