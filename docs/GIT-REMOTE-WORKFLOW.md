# Git Remote Workflow

This repo is set up with two remotes:

- `origin` = your writable fork
- `upstream` = the original source repo

Current intended layout:

```bash
git remote -v
```

Expected shape:

```bash
origin   https://github.com/<your-user>/openclaw-infra.git (fetch)
origin   https://github.com/<your-user>/openclaw-infra.git (push)
upstream https://github.com/pandysp/openclaw-infra.git (fetch)
upstream https://github.com/pandysp/openclaw-infra.git (push)
```

## Daily Flow

Commit and push your own work to your fork:

```bash
git add ...
git commit -m "your change"
git push origin main
```

Fetch updates from the original repo:

```bash
git fetch upstream
```

See what `upstream` has that your local `main` does not:

```bash
git log --oneline main..upstream/main
```

## Bringing In Upstream Changes

Before merging or rebasing, make sure your working tree is clean:

```bash
git status
```

If you have local uncommitted work, either commit it first or stash it:

```bash
git stash push -u -m "temp before upstream sync"
```

Merge upstream into your branch:

```bash
git fetch upstream
git merge upstream/main
```

Or rebase for a linear history:

```bash
git fetch upstream
git rebase upstream/main
```

Then push the result back to your fork:

```bash
git push origin main
```

## Recommended Rules

- Push your own work only to `origin`.
- Treat `upstream` as read-only.
- Do not merge or rebase while the working tree is dirty unless you are doing it intentionally and know which changes are in play.
- If the fork and local branch drift in a confusing way, inspect first:

```bash
git status -sb
git branch -vv
git log --oneline --decorate --graph --max-count=20 --all
```

## One-Time Setup

If `upstream` is missing:

```bash
git remote add upstream https://github.com/pandysp/openclaw-infra.git
git fetch upstream
```

If `origin` should point to your fork:

```bash
git remote set-url origin https://github.com/<your-user>/openclaw-infra.git
```
