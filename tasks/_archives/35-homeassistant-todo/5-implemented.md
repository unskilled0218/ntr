# Implemented

- [Changes](#changes)
- [Verification](#verification)
- [Remaining Checks](#remaining-checks)

## Changes

- Implemented client → ntr server → Home Assistant tasks on branch `35-homeassistant-todo` in the parent and both submodule repositories. File-backed deployments remain the default; Markdown notes and remembered labels keep their existing stores.
- Added server-only URL/list/token-file/CA configuration, verified HTTPS without redirects, bounded upstream requests, and a persistent UID/numeric-ID/lifecycle sidecar. HA mode never opens or modifies the old task file and never migrates it automatically.
- Added task CRUD, completion/reopening, date/datetime mapping, due clearing, HA-description preservation, safe unknown-completion-date projection, and conservative lifecycle invalidation after restart/outage.
- Added one asynchronous HA coordinator for reads, polling, and writes. External or uncertain deltas produce unfiltered rescans; proven self-only deltas retain origin filtering. Client-facing work has bounded queue/operation deadlines below the native transport timeout. Uncertain writes are not replayed.
- Added non-secret server capabilities and guarded raw-task replacement on both sides. HA reconnect always adopts authoritative server tasks instead of uploading local files; note reconciliation and existing local fallback/draft ownership remain unchanged.
- Updated the date-only editor to preserve datetime time/fixed offset, display retained-time guidance, and explicitly clear due. Kept per-task project actions and remote-change approval; added concurrency regression coverage for both.
- Added disposable HTTPS HA fixtures and `npm run test:ha-contract`, which runs the actual client serializer through the Rust HA adapter. Updated relevant READMEs, configuration/API/connection/task-ID/lifecycle documentation, container examples, and release notes.
- Updated server to `0.2.10` and app to `0.15.31`, including their version mirrors and lockfiles. No publication, push, deployment, or live HA mutation was performed.

## Verification

| Check | Result |
| --- | --- |
| Server `cargo test --locked` | Passed: 37 unit tests and 17 integration tests, including trusted/untrusted CA, wrong hostname, auth, redirects, malformed data, CRUD, stable IDs, lifecycle projection, uncertain writes, metadata failure, real SSE origin filtering, and coordinated concurrency. |
| Server `cargo clippy --all-targets -- -D warnings` | Passed without warnings. |
| Server `cargo fmt --check` | Passed. |
| App `NODE_OPTIONS=--no-experimental-webstorage npm test` | Passed: 748 tests across 46 files. Node 26's experimental web storage must be disabled so jsdom owns localStorage. |
| App `npm run build` | Passed: TypeScript and production Vite build. |
| App `npm run test:ha-contract` | Passed against a generated-CA loopback HTTPS fixture; covers the real serializer, external completion/edit/reopen, private creation restoration, restart IDs, datetime/description preservation, and raw-upload rejection. |
| App release-model/version validation and server version mirrors | Passed. |
| Git whitespace checks | Passed. |

Initial Rust checks were blocked by the missing toolchain; the user installed Rust and server verification then completed. Initial fixture TLS checks correctly rejected a CA certificate used as a server leaf; the fixture now generates a separate CA-signed leaf without weakening verification.

## Remaining Checks

- Native app `cargo test --locked` and `npm run test:task-contract` were attempted but remain blocked by missing system development libraries (`pkg-config`, DBus/GLib/WebKitGTK and related Tauri dependencies). Native app implementation code was not changed, apart from version mirrors. Install the dependencies below, then rerun those checks; native verification is not claimed as passed.

```sh
sudo apt-get update
sudo apt-get install -y pkg-config libdbus-1-dev libwebkit2gtk-4.1-dev libayatana-appindicator3-dev librsvg2-dev libssl-dev libxdo-dev
```

- The operator-approved smoke test against a real disposable HA list was not run because deployment URL, list, token, and certificate were not supplied. Configure the server using `server/docs/home-assistant.md`, then validate the installed HA version before selecting a production list.
- `npm ci` reported 11 existing dependency audit advisories (4 moderate, 5 high, 2 critical). Frontend dependency versions were not changed; dependency remediation was outside this task.
