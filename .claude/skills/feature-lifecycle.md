# Skill: feature-lifecycle

Orchestrates the full OrderFlow AI-DLC from a raw requirement through to
published documentation. Chains all six specialist agents in sequence and
enforces a mandatory human checkpoint between every stage.

Invoke with:
```
/feature-lifecycle <brief description of the feature or ticket>
```

---

## The Golden Rule

> **Checkpoints are never skipped, abbreviated, or treated as a formality —
> not to move faster, not to meet a deadline, not because the change "looks
> small". Every stage gate exists because autonomous output has a category of
> failure that only a human can catch. Speed is not a valid reason to remove
> that catch.**

A stage is open when the human explicitly approves the current stage's output.
"Looks good", "approved", "LGTM", or equivalent counts. Silence, time pressure,
or agent confidence do not.

---

## Flow diagram

```
  ┌─────────────────────────────────────────────────────────────────┐
  │                     FEATURE LIFECYCLE                           │
  └─────────────────────────────────────────────────────────────────┘

   Raw requirement / ticket
           │
           ▼
  ┌─────────────────┐
  │   spec-agent    │  Drafts spec, user stories, acceptance criteria
  └────────┬────────┘
           │
           ▼
  ░░░░░░░░░░░░░░░░░░░  CHECKPOINT 1 — Human validates intent
  ░  Approve spec?  ░  Does this capture the right requirement?
  ░░░░░░░░░░░░░░░░░░░  Are all ACs testable and unambiguous?
      │         │
     YES        NO ──► Back to spec-agent with feedback
      │
      ▼
  ┌─────────────────┐
  │  design-agent   │  Proposes architecture, API contract,
  └────────┬────────┘  event schema, data model, ADRs
           │
           ▼
  ░░░░░░░░░░░░░░░░░░░░░  CHECKPOINT 2 — Human approves architecture
  ░  Approve design?  ░  Are bounded contexts respected?
  ░░░░░░░░░░░░░░░░░░░░░  Are ADR trade-offs acceptable?
      │         │
     YES        NO ──► Back to design-agent with feedback
      │
      ▼
  ┌─────────────────┐
  │   impl-agent    │  Generates domain model, migrations,
  └────────┬────────┘  services, Kafka wiring, REST controllers,
           │           DTOs, observability, Angular (if applicable)
           ▼
  ░░░░░░░░░░░░░░░░░░░░░░░  CHECKPOINT 3 — Human reviews code
  ░  Approve impl?      ░  Is the code correct and complete?
  ░░░░░░░░░░░░░░░░░░░░░░░  Does it match the approved design?
      │         │
     YES        NO ──► Back to impl-agent with feedback
      │
      ▼
  ┌─────────────────┐
  │   test-agent    │  Generates unit, slice, and integration
  └────────┬────────┘  tests mapped to every AC in the spec
           │
           ▼
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░  CHECKPOINT 4 — Human verifies tests
  ░  Approve tests?          ░  Do tests assert the right behaviour?
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░  Is every AC covered?
      │         │
     YES        NO ──► Back to test-agent with feedback
      │
      ▼
  ┌─────────────────┐
  │  review-agent   │  Pre-vets the full diff: correctness,
  └────────┬────────┘  security, conventions, AC coverage,
           │           observability, test quality
           ▼
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░  CHECKPOINT 5 — Human merge decision
  ░  Merge?                  ░  Are all blockers resolved?
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░  Is the recommendation acceptable?
      │         │
     YES        NO ──► Fix blockers, re-run review-agent, repeat
      │
      ▼
   [ Merge to main ]
      │
      ▼
  ┌─────────────────┐
  │   docs-agent    │  Drafts OpenAPI annotations, ADR, runbook,
  └────────┬────────┘  developer guide, event catalog, changelog
           │           (human selects which doc types are needed)
           ▼
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░  CHECKPOINT 6 — Human confirms accuracy
  ░  Confirm docs?           ░  Do docs reflect what was built?
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░  Are deviations from design resolved?
      │         │
     YES        NO ──► Back to docs-agent with corrections
      │
      ▼
   [ Publish docs ]
      │
      ▼
  ┌─────────────────────────────────────────────────────────────────┐
  │                        DONE                                     │
  └─────────────────────────────────────────────────────────────────┘
```

---

## Stage reference

| # | Stage | Agent | Human checkpoint question |
|---|-------|-------|---------------------------|
| 1 | Requirements | `spec-agent` | Does this spec capture the right intent? Are all ACs testable? |
| 2 | Design | `design-agent` | Is the architecture sound? Are ADR trade-offs acceptable? |
| 3 | Implementation | `impl-agent` | Is the code correct, complete, and consistent with the design? |
| 4 | Test | `test-agent` | Do the tests assert the right behaviour? Is every AC covered? |
| 5 | Review | `review-agent` | Are all blockers resolved? Safe to merge? |
| 6 | Docs | `docs-agent` | Are the docs accurate? Do they reflect what was actually built? |

---

## How to run a stage

At each stage, provide the agent with its required inputs. Every agent will
refuse to proceed if upstream approvals are missing.

### Stage 1 — Requirements

Inputs: raw requirement, ticket text, or verbal description.

```
Use spec-agent.

Requirement: <paste the raw ask here>
```

Wait for the spec draft. Review it against the original ask. Approve or give
feedback. Do not proceed to Stage 2 until you have explicitly approved the spec.

---

### Stage 2 — Design

Inputs: approved spec (copy the full approved spec text or reference it by title).

```
Use design-agent.

Approved spec: <paste or reference the approved spec>
```

Wait for the design draft. Review the architecture, API contract, event schema,
data model, and ADRs. Approve or give feedback. Do not proceed to Stage 3 until
you have explicitly approved the design.

---

### Stage 3 — Implementation

Inputs: approved design. Answer the impl-agent's clarifying questions before it
generates code (Flyway version, existing base classes, config property names).

```
Use impl-agent.

Approved design: <paste or reference the approved design>
```

Review every generated file. Check that it matches the design and that no
`// IMPL-NOTE:` assumptions are unsafe. Approve or give feedback. Do not proceed
to Stage 4 until you have explicitly approved the implementation.

---

### Stage 4 — Tests

Inputs: approved spec (for ACs) and approved design (for structure).

```
Use test-agent.

Approved spec: <paste or reference>
Approved design: <paste or reference>
```

Review the AC coverage matrix. Verify that each test asserts the *right*
behaviour, not just that it compiles. Approve or give feedback. Do not proceed
to Stage 5 until you have explicitly approved the tests.

---

### Stage 5 — Review

Inputs: approved spec, approved design, and the full diff (`git diff main` or
the PR diff).

```
Use review-agent.

Approved spec: <paste or reference>
Approved design: <paste or reference>
Diff: <paste git diff or PR URL>
```

Read the findings report. Resolve all blockers. Decide on warnings. Merge only
when you are satisfied. Do not proceed to Stage 6 until the code is merged.

---

### Stage 6 — Docs

Inputs: approved spec, approved design, merged implementation. Specify which
document types you need (`openapi`, `adr`, `runbook`, `developer-guide`,
`event-catalog`, `changelog`, or a combination).

```
Use docs-agent.

Document types needed: <list>
Approved spec: <paste or reference>
Approved design: <paste or reference>
Merged branch / commit: <reference>
```

Review the drafts against the merged code. Confirm accuracy. Resolve any
deviation flags before publishing.

---

## Feedback loops

Every stage supports a feedback loop back to the same agent. Pass the draft
output plus your specific objections:

```
Use <agent-name>.

Previous draft: <paste>
Feedback: <your specific objections or corrections>
```

Stages never loop *backwards* across a checkpoint. If a downstream stage
reveals a fundamental problem with an upstream output (e.g., the test agent
finds the spec ACs are untestable), surface it to the human — do not silently
re-open a closed stage. The human decides whether to re-open the earlier stage
and what downstream work is invalidated.

---

## Parallel workstreams

When a feature touches both backend and frontend, the following stages may run
in parallel *within* a stage — but the checkpoint at the end of the stage still
covers both before the next stage opens:

- Stage 3: backend impl and Angular impl may be generated in separate passes
- Stage 4: backend tests and Angular tests may be generated in separate passes
- Stage 5: a single review covers the full diff including both

Never open Stage N+1 for one workstream while Stage N is still open for another.

---

## Lifecycle state tracking

Keep a running status block at the top of your working document or conversation
so the current state is always visible:

```
## Lifecycle status

| Stage | Agent | Status | Approved by | Date |
|-------|-------|--------|-------------|------|
| 1 Requirements | spec-agent    | ✅ Approved | | |
| 2 Design       | design-agent  | ✅ Approved | | |
| 3 Implementation | impl-agent  | 🔄 In review | | |
| 4 Test         | test-agent    | ⏳ Pending | | |
| 5 Review       | review-agent  | ⏳ Pending | | |
| 6 Docs         | docs-agent    | ⏳ Pending | | |
```

Status values: `⏳ Pending` → `🔄 In review` → `✅ Approved` → `🚫 Blocked`
