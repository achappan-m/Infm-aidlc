# OrderFlow — AI-DLC

An **AI-Driven Development Lifecycle** setup for the OrderFlow platform. Instead
of using AI as a code-completion bolt-on inside one phase, AI-DLC applies a
**master-orchestrator + specialist-agent** pattern across the *entire* lifecycle
— requirements, design, implementation, test, review, docs — with a **human
checkpoint** at every stage.

> Framework note: AI-DLC is a methodology popularised by AWS. This repo is *my
> implementation* of it — the agent definitions, skills, orchestration, and CI
> wiring are the engineering here. The principle "agents propose, the human
> decides" is enforced throughout.

## The lifecycle

```
request
   │
   ▼  spec-agent ───────► docs/specs/      ◄── HUMAN: validate intent
   ▼  design-agent ─────► docs/design/      ◄── HUMAN: approve architecture
   ▼  impl-agent ───────► src/             ◄── HUMAN: review correctness
   ▼  test-agent ───────► src/test/         ◄── HUMAN: verify assertions
   ▼  review-agent ─────► PR report         ◄── HUMAN: final approval
   ▼  merge
   ▼  docs-agent ───────► docs / CHANGELOG  ◄── HUMAN: confirm accuracy
```

## How it's built

| Layer | File(s) | Purpose |
|-------|---------|---------|
| Grounding | `CLAUDE.md` | Single source of truth all agents read first |
| Agents | `.claude/agents/*.md` | Six single-responsibility specialists |
| Workflow | `.claude/skills/feature-lifecycle.md` | Chains the agents with checkpoints |
| Commands | `.claude/commands/*.md` | `/spec`, `/design`, `/implement`, `/test`, `/review`, `/ship` |
| Governance | `docs/adr/`, `scripts/check_traceability.sh` | ADRs + traceability gate |
| Automation | `.github/workflows/aidlc.yml`, `scripts/run_review_agent.sh` | Agents as CI gates |

## Using it

- Manual, stage by stage: `/spec`, then `/design`, then `/implement`, ...
- Full run with checkpoints: `/ship Add promo-code support to pricing-service`
- On every PR, CI runs the build, the **review-agent** as a pre-vet gate, and a
  **traceability gate** that fails if source changed without a spec.

## Why this design

- **Single responsibility per agent** → predictable, testable output.
- **Grounding file** → agents reason about *OrderFlow*, not generic Spring Boot.
- **Human checkpoints** → safe in a regulated/auditable context.
- **Versioned in the repo** → the AI config evolves through normal PR review,
  the same as code.
