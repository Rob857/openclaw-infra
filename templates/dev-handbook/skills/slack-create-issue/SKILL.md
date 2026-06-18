---
name: create-issue
description: "Create GitHub issues from natural language. Auto-triggers when a user describes a bug, feature request, or improvement — keywords: bug, issue, feature, fix, problem, crash, fehler, kaputt, request, vorschlag, idee. Guides a smart interview: if enough info is provided upfront, create the issue immediately. Only ask follow-up questions for genuinely missing critical info. NOT for: listing issues, closing issues, PR reviews."
---

# Create Issue

Smart GitHub issue creation from Slack conversations.

## Trigger

Activate when a message describes a bug, problem, feature request, or improvement idea. Look for intent, not just keywords — "the map doesn't load when I switch tabs" is clearly a bug report even without the word "bug".

## Flow

### 1. Analyze the message

Extract what's provided:
- **Type**: Bug or Feature? (infer from context)
- **Repo**: Which repo? (infer from context if possible — UI/App issues -> `App_frontend`, Dashboard -> `mapletics-dashboard`, Website -> `mapletics-website`, Cloud Functions -> `App_frontend`)
- **Title**: Short, clear summary
- **Description**: What happens / what's requested
- **Steps to reproduce**: (bugs only) How to trigger it
- **Expected vs actual**: (bugs only) What should happen vs what does happen
- **Priority/Labels**: Infer from severity (crash = `priority: high`, nice-to-have = `enhancement`)

### 2. Decide: create or ask

**Create immediately** when you have at least:
- Clear understanding of what the issue is
- Which repo it belongs to (inferred or stated)

**Ask follow-up** only when:
- You genuinely can't tell which repo it belongs to
- The description is too vague to write a useful issue (e.g., "something is broken")
- Max 1-2 targeted questions, not a checklist

### 3. Create the issue

Use `gh` CLI:

```bash
gh issue create --repo Mapletics/<repo> \
  --title "<title>" \
  --body "<body>" \
  --label "<labels>"
```

Body format:
```markdown
## Description
<clear description>

## Steps to Reproduce (bugs only)
1. ...
2. ...

## Expected Behavior
<what should happen>

## Actual Behavior
<what happens instead>

## Context
- Reported by: <slack user>
- Source: Slack
```

### 4. Confirm

Post the GitHub issue link back in Slack. Keep it short:
"✅ Issue erstellt: <link>"

## Rules

- **Speed over perfection** — a good-enough issue now beats a perfect issue after 5 questions
- **German or English** — match the user's language for conversation, but write issue title and body in **English**
- **Don't over-label** — only add labels you're confident about
- **One issue per problem** — if someone describes multiple things, create separate issues
- **Default repo:** `App_frontend` if context is unclear and it sounds like an app issue

## Available Repos

| Repo | Context |
|------|---------|
| `App_frontend` | Flutter mobile app, UI, features, Cloud Functions |
| `mapletics-dashboard` | Admin dashboard, backend API |
| `mapletics-website` | Marketing website (mapletics.com) |
| `Data` | Data pipeline scripts |
