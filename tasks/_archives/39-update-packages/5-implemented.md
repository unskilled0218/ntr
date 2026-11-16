# Implemented

- [Changes](#changes)
- [Dependency versions](#dependency-versions)
- [Verification](#verification)
- [Limits](#limits)

## Changes

- Completed goal, plan, plan review, plan update, and implementation on fresh `39-update-packages` branches in parent, app, and server. The task follows `command.md`: update app and server packages.
- Incorporated the user's existing npm audit-fix improvements into the dependency refresh without resetting the lockfile or using forced/legacy peer resolution. Clean `npm ci` succeeds, both npm audits report zero advisories, and `npm outdated` reports no outdated direct npm packages at verification time.
- Upgraded the JavaScript toolchain and compatible native Rust dependency graph. Added the required Node engine range. The stricter generic mock types use a typed fake object plus a spy; existing behavior assertions remain unchanged. Explicit accessible names on remote-review buttons preserve their intended resource-specific names across the upgraded DOM stack.
- Updated server HTTP middleware and HTTPS/WSS dependencies. Reqwest 0.13 uses an explicit ring-based Rustls configuration shared with WSS, preserving web-PKI/custom roots and hostname checks instead of inheriting changed default verifier behavior. Existing no-redirect, bounded-operation, origin-filtering, and durable-journal tests remain intact and pass.
- Updated both READMEs, development/dependency guidance, stack documentation, release notes, versions, lockfiles, and release-notes pointers. App is `0.15.33`, server is `0.2.14`. Component commits: app `6ee4314`, server `4c40699`.

## Dependency versions

| Area | Updated selection |
| --- | --- |
| React / React DOM | 19.3.1 |
| Tauri npm API / CLI | 2.12.5 |
| Tauri npm opener | 2.7.3 |
| React testing library / React type packages | 16.3.3 / 19.3.0 |
| Vite / React plugin | 8.3.8 / 6.3.0 |
| Vitest / jsdom / TypeScript | 5.1.0 / 31.0.1 / 7.0.2 |
| Native Tauri / build / opener / dialog | 2.12.6 / 2.7.5 / 2.7.3 / 2.8.4 |
| Server tower-http / reqwest / tokio-tungstenite | 0.7.1 / 0.13.5 / 0.30.0 |
| Shared compatible Rust refresh | Includes Tokio 1.54.1, Serde 1.0.229, serde_json 1.0.154, and Rustls 0.23.46. |

Intentionally retained: patched vendored window-state `=2.4.0` and Android filesystem 28.4.x. No vendor source changed. Their newer platform-specific releases require patch/Android validation. Reqwest still depends on tower-http 0.6.11 internally; the server's direct middleware uses 0.7.1 without forcing a transitive override.

## Verification

| Check | Result |
| --- | --- |
| `npm ci`, peer graph, `npm ls --depth=0` | Passed without forced overrides. |
| `npm audit` and `npm audit --omit=dev` after clean install | Both zero vulnerabilities. Before the refresh, six dev-tooling entries remained: one high, two critical, three moderate. |
| `npm outdated --json` | Empty result at verification time. |
| App frontend tests | Passed: 762 tests across 48 files, using `NODE_OPTIONS=--no-experimental-webstorage`. |
| App `npm run build` | TypeScript 7 and Vite 8 production build passed. |
| App `npm run test:release` | Passed: 52 hermetic release-tool tests; no real publication. |
| Native locked Rust tests | Passed: 62 default tests; one opt-in test initially ignored by design. |
| Native real-server restart test | The opt-in test was then explicitly run with `MY_NTR_SERVER_BIN`; passed. Total native tests verified: 63. |
| Native locked all-target strict Clippy | Passed without warnings. |
| Server locked Rust tests | Passed: 60 library and 22 separate integration tests, 82 total. |
| Server formatting and locked all-target strict Clippy | Passed. |
| `npm run test:ha-contract` | Passed with the real serializer/server and generated-CA loopback HTTPS/WSS fixture. |
| `npm run test:task-contract` | Passed for disk-backed native local storage and the current HTTP server. |
| Compose rendering | Passed: one configuration test; no container started. |
| App/server offline release validation and version mirrors | Passed without credentials or remote operations. |
| Git whitespace and resolved server TLS-feature inspection | Passed; server selects ring, not an implicit AWS-LC provider. |

Tests used Node 26.13.0, npm 11.20.0, and Rust/Cargo 1.100.0. Cargo targets were isolated under `/tmp/opencode/ntr-task39-server` and `/tmp/opencode/ntr-task39-native`; fixtures used `TMPDIR=/tmp/opencode`. The first frontend attempt exposed a generic mocked-reader typing error and eight accessible-name failures. The narrow typing/accessibility changes resolved them; the full suite and production build were rerun successfully without removing assertions or skipping tests.

## Limits

`cargo-audit` is not installed, so no RustSec audit or Rust vulnerability-free claim is made. If desired, the operator can install it with `cargo install cargo-audit --locked`, then run `cargo audit` in `server/` and `app/src-tauri/`. No system packages or extra audit tools were installed during this task.

Validation covers the current Linux host and Node 26, not Android/Windows/macOS builds or every declared Node version. No signed desktop/Android release artifacts were built. Optional old-server compatibility checks were not run because `OLD_NTR_SERVER_BIN` was not supplied. Existing native system development libraries were available, unlike the earlier task environment.

Npm audit results are a point-in-time registry assessment, not proof of complete security. No live HA operations, deployment credentials, root installation, container startup, publication, deployment, or push occurred. `todo.md` and earlier task records remain untouched.
