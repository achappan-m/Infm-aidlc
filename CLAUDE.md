# OrderFlow — Project Context (CLAUDE.md)

> This file is the single source of truth that grounds every AI agent in this
> repository. Every agent invocation reads this first. Keep it accurate — a
> wrong context file poisons every downstream stage of the lifecycle.

## What OrderFlow is

OrderFlow is a multi-service order-management platform. Customers place orders
through a web front end; orders are validated, priced, fulfilled, and invoiced
through a set of backend services that communicate over a mix of synchronous
REST and asynchronous events.

This repository is the home of the **AI-DLC (AI-Driven Development Lifecycle)**
configuration for the platform. The agent definitions, skills, and commands here
drive each phase of delivery from requirement through release.

## Tech stack (authoritative)

- **Backend:** Java 21, Spring Boot 3.x, Spring Cloud
- **Frontend:** Angular 17 (standalone components, signals)
- **Messaging:** Kafka (idempotent producers, manual-ack consumers)
- **Persistence:** PostgreSQL per service (database-per-service)
- **Build:** Maven (backend), npm (frontend)
- **Container/CI:** Docker, GitHub Actions
- **Cloud:** AWS (ECS, S3, Lambda, CloudWatch, IAM) — or Azure equivalents
- **Observability:** Prometheus, Grafana, structured JSON logging

## Services (bounded contexts)

- `order-service` — order intake, lifecycle state machine
- `pricing-service` — price calculation, promotions
- `fulfilment-service` — warehouse + shipping coordination
- `invoice-service` — invoicing, document generation
- `notification-service` — email/SMS, event-driven

## Conventions (agents MUST follow)

- **Architecture:** Domain-Driven Design; respect bounded contexts. No service
  reaches directly into another service's database.
- **APIs:** REST, versioned (`/api/v1/...`). Document with OpenAPI.
- **Events:** Kafka topics named `orderflow.<context>.<event>`. Producers are
  idempotent; consumers are manual-ack with a dead-letter topic.
- **Testing:** JUnit 5 + Mockito (unit), Testcontainers (integration).
  Every behaviour change ships with tests asserting the *acceptance criteria*,
  not just coverage.
- **Errors:** Fail fast, never swallow. Use typed exceptions + a global handler.
- **Style:** Google Java Format; ESLint/Prettier for the front end.
- **Security:** No secrets in code. Validate all external input. Log decisions,
  never log PII or secrets.

## AI-DLC operating rules (apply to every agent)

1. **Human owns the decision.** Agents propose; the engineer approves. Never
   present autonomous output as final at a human-checkpoint stage.
2. **Stay grounded.** Reason from this file and the actual repo, not generic
   assumptions. If context is missing, ask rather than invent.
3. **Be traceable.** Every non-trivial decision is captured — in a spec, an ADR,
   a PR description, or a commit message.
4. **Stay in your lane.** Each specialist agent has a single responsibility.
   Don't let the test agent redesign architecture, etc.

## Human checkpoints (non-negotiable)

| Stage | Agent acts | Human decides |
|-------|------------|---------------|
| Requirements | drafts spec | validates intent |
| Design | proposes design | approves architecture |
| Implementation | generates code | reviews correctness |
| Test | generates tests | verifies they assert the right thing |
| Review | pre-vets the diff | final approval |
| Docs | drafts docs/ADR | confirms accuracy |
