# Plan

- [Scope](#scope)
- [Implementation Plan](#implementation-plan)
- [Validation](#validation)
- [Acceptance Criteria](#acceptance-criteria)

## Scope

Load server-side HA connection settings from `.env`, with the accepted example, Git exclusions, environment precedence, protected token-file authentication, and documented direct/Compose setup. Keep the client, certificate policy, existing task backends, Markdown notes, and base file-backed Compose deployment unchanged. No UI design is required.

## Implementation Plan

1. Add an explicit fallible startup configuration loader in `server/src/config.rs` and use it from `server/src/main.rs`. Parse only `.env` in the process working directory with `dotenvy`; do not search ancestor directories or mutate the process environment. Preserve the existing `Config::from_env()` entry point for programmatic callers and tests.
2. Share configuration construction through an environment-value lookup. Snapshot existing process variables, load missing values from the file, and keep existing variables authoritative even when empty. Preserve current defaults and path resolution relative to the working directory. Missing `.env` is valid; unreadable or malformed files fail startup before stores are opened, with sanitized errors that do not echo file values or token contents.
3. Add `server/.env.example` for `TASK_BACKEND`, `HA_URL`, `HA_TOKEN_FILE`, `HA_TODO_ENTITY`, `HA_CA_FILE`, `HA_METADATA_FILE`, and `HA_POLL_SECONDS`. Keep the token itself outside `.env`. Use relative token/certificate paths under `./secrets` and `./certificates`, and `./ha-metadata.json` for metadata. Ignore `.env`, local `.env` variants, and private setup directories without ignoring `.env.example`.
4. Add an opt-in `server/docker-compose.ha.yml` override using service `env_file: .env`. Mount `./secrets` and `./certificates` read-only under the container working directory `/data`, so example paths work in both direct and container runs. Keep the existing persistent data volume, listener binding, image selection, and unmodified base Compose workflow. Document that Compose's interpolation-only `.env` behavior does not itself inject service environment, and that explicit service `environment` values override `env_file` values.
5. Update server README, configuration, HA setup, Docker Compose documentation, and parent README with copy/edit/run instructions, file permissions, host/container path rules, precedence, and no-publication status. Update server version from `0.2.10` to `0.2.11` and its existing mirrors/release notes. Do not change the app version or run real HA operations.

## Validation

- Add parser/configuration tests using explicit temporary files and environment maps, without global environment mutation. Cover missing file, valid quoted values/comments, process overrides including empty values, defaults, malformed input, unreadable paths, and sanitized errors containing no sentinel secret values.
- Add child-process startup tests with an isolated working directory/environment: `.env` selects HA without manual exports, process variables win, a parent `.env` is not searched, malformed/unreadable files fail before resource writes, and no `.env` preserves file-backed startup. Use fixture paths and loopback ports, never deployment credentials.
- Check example keys and Git-ignore rules, and verify the Compose override wiring and path mounts. Run `docker compose ... config` only when Compose is available; do not start containers or publish images. Record unavailable tooling explicitly.
- Run server `cargo test --locked`, `cargo fmt --check`, and `cargo clippy --all-targets -- -D warnings`; rerun the existing disposable-TLS HA serializer contract. Validate version mirrors and Git whitespace checks.

## Acceptance Criteria

- `cp .env.example .env`, local edits, and `cargo run` configure the HA backend without shell exports.
- Existing process environment values override `.env`; startup errors do not reveal secrets or partially apply file values.
- The documented HA Compose override explicitly passes `.env` settings and preserves private token/certificate paths and persistent metadata.
- HA settings remain server-only, TLS verification remains enabled, and existing file-backed/no-file startup and Markdown notes remain compatible.
