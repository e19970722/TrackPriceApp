Please analyze and fix the GitHub issue: $ARGUMENTS.

Follow these steps:

# PLAN

1. Use `gh issue view $ARGUMENTS` to get the issue details and labels
2. Identify the agent type from labels:
   - `backend` label only → dispatch to **backend-expert** agent
   - `ios` label only → dispatch to **ios-expert** agent
   - both labels → dispatch to **backend-expert** and **ios-expert** agents in parallel
   - no label → handle directly, routing each file change to the correct agent by path (`Backend/` → backend-expert, `iOS/` → ios-expert)
3. Check open/merged PRs for any prior art: `gh pr list --state all`
4. Create a branch: `git checkout -b feature/issue-$ARGUMENTS-short-description`

# AGENT RULES

Each agent must stay strictly within its domain:

**backend-expert** — only touches files under `Backend/`. Must not read or write any file under `iOS/`.

**ios-expert** — only touches files under `iOS/`. Must not read or write any file under `Backend/`.

When dispatching to a subagent, include in the prompt:
- The issue number and full issue text
- The branch name already created
- Explicit instruction: "You are the [backend/iOS] expert. Only modify files under [Backend/iOS]/. Do not touch any files outside this directory."
- Relevant files to look at (from your prior art check)
- Commit message convention: prefix with `[Backend]` or `[iOS]`, active verb form — e.g. `[Backend] Add migration for trackers table`, `[iOS] Show OG image in TrackerDetailView`
- Never mix backend and iOS changes in a single commit

# TEST

**backend-expert must:**
- Write `pytest` tests (async, against a real test DB — no mocking the DB)
- Run: `pytest` from `Backend/`
- Lint: `ruff check .` and `mypy .`
- Fix all failures before finishing

**ios-expert must:**
- Write Swift Testing (`@Test`, `@Suite`) / TCA `TestStore` tests — do not use XCTest
- Run: `xcodebuild test -scheme TrackPriceApp -destination 'platform=iOS Simulator,name=iPhone 16'` from `iOS/`
- Fix all failures before finishing

# DEPLOY

After all agents are done:
- Push branch and open a PR: `gh pr create --title "Fix #$ARGUMENTS: <short description>" --body "Closes #$ARGUMENTS"`
- Ensure the PR description explains what changed and why

Remember to use the GitHub CLI (`gh`) for all GitHub-related tasks.
