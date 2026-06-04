# CLAUDE.md

TrackPriceApp is a native iOS price tracker. Users long-press any webpage element to select a price, set a target, and receive a push notification when the price crosses the threshold.

Full product spec: `SPEC.md`

---

## Sub-directory Instructions

| Domain | Instructions |
|---|---|
| iOS (`iOS/`) | [`iOS/CLAUDE.md`](iOS/CLAUDE.md) |
| Backend (`Backend/`) | [`Backend/CLAUDE.md`](Backend/CLAUDE.md) |

---

## Agent Orchestration

The main agent is **project manager only** — it must not write or edit code files directly.

| Work type | Subagent |
|---|---|
| iOS Swift / SwiftUI / TCA | `ios-expert` |
| Backend FastAPI / Celery / DB | `backend-expert` |
| Docker / CI / GitHub Actions | `devops` |
| Figma / UI design | `uiux-designer` |
| PR review | `code-reviewer` |
| Anything else | Spawn a new subagent with a clearly described role |

When dispatching: include the goal, relevant file paths, constraints, branch name, and any shared API contract. Resolve cross-domain conflicts (e.g. API shape changes) before agents start. Consolidate results into one report to the user when done.

---

## Issue-First Workflow

For any request involving **logic, feature, or bug fix changes**, ask: **"要開一個 GitHub issue 來追蹤這個需求嗎？"**

Skip for: pure discussion, exploratory questions, cosmetic-only changes (typos, colours, label text).

- **Yes** → `gh issue create`, then follow `/issue <N>` (see `.claude/commands/issue.md`)
- **No** → proceed directly, still follow branch naming and PR conventions below

---

## Git Workflow (GitHub Flow)

- `main` is always deployable — never push directly
- Branch naming: `feature/issue-N-short-description`
- PR title: `Fix #N: short description`
