Please analyze and fix the GitHub issue: $ARGUMENTS.

Follow these steps:

# PLAN

1. Use `gh issue view $ARGUMENTS` to get the issue details and labels
2. Identify the agent type from labels:
   - `backend` label → follow backend-expert conventions (FastAPI, pytest, SQLAlchemy)
   - `ios` label → follow ios-expert conventions (TCA, SwiftUI, XCTest)
3. Understand the problem and search the codebase for relevant existing files
4. Check open/merged PRs for any prior art: `gh pr list --state all`
5. Break the issue into small, sequential tasks

# CREATE

- Create a branch: `git checkout -b feature/issue-$ARGUMENTS-short-description`
- Solve in small steps, committing after each logical unit of work
- Commit messages: present tense, imperative ("Add migration for trackers table")

# TEST

**Backend issues:**
- Write `pytest` tests (async, against a real test DB — no mocking the DB)
- Run: `pytest` from `Backend/`
- Lint: `ruff check .` and `mypy .`

**iOS issues:**
- Write `XCTest` / TCA `TestStore` tests
- Run: `xcodebuild test -scheme TrackPriceApp -destination 'platform=iOS Simulator,name=iPhone 16'` from `iOS/`

Fix all failures before opening the PR.

# DEPLOY

- Push branch and open a PR: `gh pr create --title "Fix #$ARGUMENTS: <short description>" --body "Closes #$ARGUMENTS"`
- Ensure the PR description explains what changed and why

Remember to use the GitHub CLI (`gh`) for all GitHub-related tasks.
