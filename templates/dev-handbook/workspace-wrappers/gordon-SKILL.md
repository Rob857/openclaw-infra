# Gordon Shared Skill Binding

For Slack intake and issue creation, use the shared skill from:

`~/dev-handbook/skills/slack-create-issue/SKILL.md`

For Mapletics dashboard Postgres questions, use the shared read-only skill from:

`~/dev-handbook/skills/shared/mapletics-postgres-readonly/SKILL.md`

Postgres access rules:

- Use the existing shared read-only credential file described by the skill.
- Never print passwords, connection strings, or credential file contents.
- Never attempt writes, migrations, schema changes, or destructive queries.
- If the credential file, SSH tunnel, or DB login cannot be verified in the current runtime, report the setup as partially verified instead of claiming direct access.

Before using any shared skill, also read:

- local `SOUL.md`
- local `TOOLS.md`
- `~/dev-handbook/skills/_shared/tool-compat.md`
