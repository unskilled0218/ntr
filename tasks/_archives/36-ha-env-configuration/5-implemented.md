# Implemented

- [Changes](#changes)
- [Verification](#verification)
- [Usage](#usage)

## Changes

- Completed the existing task's plan, review, plan update, and implementation workflow. Accepted suggestions are recorded in the goal; the review's deterministic read-failure fixture suggestion is implemented.
- Added `Config::load()` for the working directory's optional `.env`, without ancestor search or process-environment mutation. Existing variables, including empty values, override file values; defaults and relative-path behavior remain unchanged. `Config::from_env()` remains environment-only.
- Startup rejects malformed, non-UTF-8, and unreadable dotenv files before opening stores, without printing private values. Tests use explicit environment maps and isolated child processes, including a directory at `.env` rather than privilege-dependent permission bits.
- Added tracked `server/.env.example`, Git exclusions for local configuration/private setup directories, and opt-in `server/docker-compose.ha.yml`. Compose explicitly injects `.env` and mounts pre-existing token/certificate directories read-only at paths matching the example. The base deployment, token-file authentication, TLS verification, client code, and Markdown notes remain unchanged.
- Updated relevant READMEs and direct/Compose/security/configuration docs. Updated server version and mirrors to `0.2.11`; app version stays `0.15.31`.

## Verification

| Check | Result |
| --- | --- |
| Server `cargo test --locked` | Passed: 64 tests (42 unit, 22 integration), including the existing HA/TLS suite and new parsing/startup/Git-ignore cases. |
| Server `cargo clippy --all-targets -- -D warnings` | Passed without warnings. |
| Server `cargo fmt --check` | Passed. |
| `python3 -B -m unittest discover -s tests -p 'test_env_compose.py' -v` | Passed: rendered base and HA Compose configurations, checked environment injection, path mapping, read-only/no-auto-create mounts, persistent data, and loopback binding. No Docker daemon or container startup used. |
| App `npm run test:ha-contract` against the new server | Passed using disposable loopback HTTPS fixtures and the actual client serializer. |
| Server version mirrors and Git whitespace checks | Passed. |

No real HA connection, private deployment credential, container startup, publication, or push was performed. No app implementation changes or version bump were needed.

## Usage

From `server/`, copy `.env.example` to `.env`, edit the URL/entity settings, and provide `secrets/ha-token` plus `certificates/homeassistant.lanCA.crt`. Keep the token readable only by the server user. Run `cargo run --locked`; no manual exports are required. Existing exports still win, so remove stale overrides when switching to `.env`.

For Docker, use `docker compose -f docker-compose.yml -f docker-compose.ha.yml up -d` after preparing the private directories and selecting an image containing these changes. See `server/docs/home-assistant.md` for permissions, validation, and path rules. Local commits do not update published images.
