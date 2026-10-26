# Codex Adapter

This file is the Codex-facing adapter for this repository. `CLAUDE.md` remains the canonical source of project knowledge; keep this file concise and use it to tell Codex where to find the detailed guidance rather than copying that guidance here.

Before changing code, read:

1. `CLAUDE.md` for repository-wide product, orchestration, issue, and Git rules.
2. `iOS/CLAUDE.md` for work under `iOS/`.
3. `Backend/CLAUDE.md` for work under `Backend/`.
4. `SPEC.md` when behavior or product intent matters.

If this adapter and a Claude guide drift, preserve Codex-specific mechanics from this file but treat the relevant `CLAUDE.md` as the project-domain source of truth and flag the mismatch.

## Project Map

| Path | Purpose |
|---|---|
| `SPEC.md` | Full product specification for the price-tracking app. |
| `TODO.md` | Current project work and follow-ups. |
| `iOS/` | Native SwiftUI client (iOS 16+) using TCA. |
| `iOS/TrackPriceApp/` | Thin Xcode app target and application entry point. |
| `iOS/Features/Sources/Features/` | Product code: app composition, screens, components, models, services, and resources. |
| `iOS/Features/Tests/FeaturesTests/` | Swift/TCA feature tests. |
| `Backend/` | Python 3.12 FastAPI API, PostgreSQL persistence, Celery jobs, and Playwright scraping. |
| `Backend/app/api/` | HTTP routers; keep them thin. |
| `Backend/app/services/` | Business logic. |
| `Backend/app/repositories/` | Database access. |
| `Backend/tests/` | pytest suite. |
| `.claude/` | Original Claude Code agents, commands, and settings retained as source material. |
| `.codex/agents/` | Codex custom-agent adapters converted from `.claude/agents/`. |
| `.agents/skills/` | Repository-scoped Codex skills. |

## Codex Agent Routing

The primary agent coordinates work and delegates code changes to the project-scoped custom agents below. Give each agent the goal, relevant paths, constraints, branch name, and any shared API contract.

| Work | Codex agent |
|---|---|
| Swift, SwiftUI, TCA, WKWebView, iOS tests | `ios_expert` |
| FastAPI, SQLAlchemy, Alembic, Celery, scraping, backend tests | `backend_expert` |
| Docker, CI/CD, deployment, environment configuration | `devops` |
| Figma and product UI/UX work | `uiux_designer` |
| Pull-request review | `code_reviewer` |

Keep delegated edits inside the agent's domain. Resolve cross-domain API changes before parallel implementation, wait for all delegated work, then provide one consolidated report. For work outside these roles, delegate to a clearly scoped general-purpose agent when delegation is useful.

## Repository Workflow

- For logic, feature, or bug-fix requests, first ask: `要開一個 GitHub issue 來追蹤這個需求嗎？`
- Skip that question for discussion, exploration, typos, colors, and label-only changes.
- If the answer is yes, follow `.claude/commands/issue.md`; it is also the detailed Codex procedure for issue-driven work.
- Keep `main` deployable and do not push changes directly to it.
- Use `feature/issue-N-short-description` for issue branches and `Fix #N: short description` for PR titles.
- Never commit credentials. Keep real environment files and machine-local overrides untracked; update `.env.example` when backend environment variables change.

## Verification

Use the focused commands documented in the applicable domain guide. At minimum, run tests for changed behavior and the domain's lint/type checks when available. Report commands that could not be run and why.
