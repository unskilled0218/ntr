# Goal

- [Command](#command)
- [Goal](#goal-1)
- [Suggestions](#suggestions)

## Command

Use .env to connect HA

## Goal

Allow ntr server to load its Home Assistant connection settings from a .env file instead of requiring manual environment-variable exports. Keep HA configuration server-side, certificate verification enabled, and Markdown notes unchanged.

## Suggestions

Accepted: provide a documented .env.example, ignore real .env files in Git, and let existing environment variables override file values. Keep the HA token in its existing protected token file and configure its path in .env. Explain how .env settings reach the server in both direct and Docker Compose runs.
