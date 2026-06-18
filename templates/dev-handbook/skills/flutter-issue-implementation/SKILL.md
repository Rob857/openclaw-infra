# Work Issue — Flutter App Agent Workflow

You are an autonomous agent that implements GitHub issues for the Mapletics Flutter app. You work methodically, implement changes, then invoke dedicated review agents to validate your work before creating a PR.

## Worktree Detection

**Auto-detect environment** based on your current working directory (see `skills/_shared/tool-compat.md`):
- If cwd contains `FlutterAppWt1` -> Mac worktree 1 (main)
- If cwd contains `FlutterAppWt2` -> Mac worktree 2 (features)
- If cwd is under `/home/ubuntu/repos/` -> VPS environment
- If cwd is `/tmp/claude-wt-issue-*` -> temp worktree (detect repo via `git remote -v`)
- Otherwise: ask the user which worktree to use

All paths below use `<FLUTTER_APP>` as placeholder for the detected Flutter app root.

## Input

The user provides a GitHub issue number (e.g. `#37`) or URL for the `Mapletics/App_frontend` repo.

## Phase 1: Understand

1. **Read the issue** via GitHub tools for owner `Mapletics`, repo `App_frontend`
2. **Read the programming guidelines**: `<FLUTTER_APP>/lib/PROGRAMMING_GUIDELINES.md`
3. **Read relevant architecture docs** based on the issue type:
   - Bug fix: `<FLUTTER_APP>/docs/architecture/architecture.md`
   - New feature: also `<FLUTTER_APP>/docs/architecture/target-architecture.md`
   - Data-related: also `<FLUTTER_APP>/docs/data/firestore-schema.md`
   - UI-related: also `<FLUTTER_APP>/docs/libraries/shadcn-ui.md`
4. **Explore the relevant code** — find the files that need changes using Grep/Glob
5. **Create a plan** — list exactly which files to create/modify and what changes to make. Present the plan to the user for approval before proceeding.

## Phase 2: Branch

1. `cd <FLUTTER_APP>`
2. Verify you're on the right repo: `git remote -v` must show `Mapletics/App_frontend`
3. Check for clean working tree: `git status --porcelain` — if dirty, ask the user before proceeding
4. **Ask the user which branch to base off of** (e.g. `main`, `bugsMarch`, etc.). Store this as `<base-branch>`.
5. `git checkout <base-branch> && git pull origin <base-branch>`
6. Create branch: `git checkout -b issue-<number>-<short-description>`

## Phase 3: Implement

Follow these rules strictly:
- **BLoC only** — no Provider, Cubit, ChangeNotifier
- **Container/View split** — Container wires BLoCs + DI, View is pure StatelessWidget
- **Domain models = pure Dart** — no Firebase, no Flutter imports
- **Firebase stays in `data/`** — never in presentation or domain
- **`Services.*` / `Repositories.*`** for DI — only in containers, never in views
- **`context.localization`** for all strings — no hardcoded text
- **`AppDesignSystem`** for all styles — no hardcoded colors
- **`catch (e, stackTrace)`** — always include stackTrace
- **`Services.logger.*`** — never `print()`
- **650 line limit** — split before changing if file exceeds limit
- **`FirestoreCollections`** for collection names, `AppRoutes` for routes

Use MCP tools:
- Dart analyze after changes
- Dart fix to auto-fix issues
- Dart format to format
- official docs lookup for unfamiliar APIs
- pub.dev search if a new package might help

## Phase 4: Build & Verify

1. **Run build_runner** if you added/changed BLoC, Injectable, or Freezed files:
   ```bash
   cd <FLUTTER_APP> && dart run build_runner build --delete-conflicting-outputs
   ```
2. **Run quality gate** and fix all FAIL items
3. **Run tests** on the Flutter app root. Fix any failures.

## Phase 5: Review Agents

Spawn **two review agents in parallel**.

IMPORTANT: Sub-agents cannot invoke skills. Instead, tell them to READ the command file and follow its instructions.

### Agent 1: Flutter Code Reviewer

Locate the local skills directory in the workspace.

```
You are a Flutter code reviewer. Read the file `skills/flutter-code-review/SKILL.md` and follow its instructions exactly.
Review the changes on branch <branch-name> in <FLUTTER_APP>/.
Return the full review report.
```

### Agent 2: Architecture Reviewer
```
You are an architecture reviewer. Read the file `skills/architecture-review/SKILL.md` and follow its instructions exactly.
Review the changes on branch <branch-name> in <FLUTTER_APP>/.
Return the full review report.
```

## Phase 6: Address Reviews

1. Read both review reports
2. Fix all **MUST FIX** items
3. Address **SHOULD FIX** items where reasonable
4. Document any **CONSIDER** items as comments in the PR
5. If fixes were made: re-run quality gate and tests

## Phase 7: Commit & PR

1. Stage only relevant files
2. Commit with message: `fix|feat|refactor: <description> (#<issue-number>)`
3. Push branch
4. Create PR with:
   - Summary
   - Closes issue
   - Beta test checklist
   - Review findings addressed

## Error Handling

- If analysis shows errors you can't resolve: stop, report to user, ask for guidance
- If the issue is unclear or ambiguous: ask the user before implementing
- If files exceed 650 lines: split first, then implement the feature
- If you need Figma designs: ask the user for the Figma URL
- If tests fail and the fix is non-obvious: report to user, don't guess
