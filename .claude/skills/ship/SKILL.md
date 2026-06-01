---
name: ship
description: Run the full AI-DLC feature lifecycle from request to delivery
---

Run the full AI-DLC feature lifecycle for the request below.

Work through each stage in order, using the specialist agent for that stage.
After each stage, STOP and wait for my explicit approval before proceeding.
Do not skip any human checkpoint.

Stages:
1. SPEC — read .claude/agents/spec-agent.md, generate the spec, STOP for approval
2. DESIGN — read .claude/agents/design-agent.md, generate the design, STOP for approval
3. IMPLEMENT — read .claude/agents/impl-agent.md, write the code, STOP for review
4. TEST — read .claude/agents/test-agent.md, write the tests, run them, STOP for review
5. REVIEW — read .claude/agents/review-agent.md, review the diff, report Blocking/Should-fix/Nits, STOP
6. DOCS — read .claude/agents/docs-agent.md, update docs/ADR/changelog, STOP for confirmation

Request: $ARGUMENTS
