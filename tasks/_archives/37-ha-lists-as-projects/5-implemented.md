# Implemented

- [Changes](#changes)
- [Safety and compatibility](#safety-and-compatibility)
- [Verification](#verification)
- [Usage](#usage)

## Changes

- Completed planning, plan review, plan update, and implementation on fresh `37-ha-lists-as-projects` branches in parent, server, and app. Accepted suggestions and all three behavior decisions are recorded in `1-goal.md`.
- Discover all visible HA to-do entities as projects, including empty lists; retain `HA_TODO_ENTITY` as the default. Use entity IDs internally and friendly names in selectors, disambiguating duplicates. Task DTOs and mutations carry explicit list routing; literal summary `+tokens` remain lossless. Omitted update routing preserves the source for older clients.
- Add schema 2 entity-qualified identity and durable move journals. Atomically migrate a matching schema 1 map without changing IDs, lifecycle metadata, or its counter. One global counter prevents duplicate UIDs in different lists from aliasing.
- Add opt-in admin-token Local To-do creation, registry display-name renaming, and confirmed empty-only deletion with default/provider/config-entry ownership checks. WSS transport uses verified hostname/private CA trust, bounded messages, deadlines, and server-only credentials. List actions no longer rewrite task tokens or remembered labels in HA mode.
- Add explicitly confirmed copy/verify/delete moves preserving numeric identity, native description/status/due, and ntr dates. Persist intent before copying and the identified target UID before follow-up writes. Partial/uncertain outcomes block writes to both involved lists. Restart recovery never replays HA writes: reconcile repairs proven completion; abandon retains copies with separate IDs. A durable monotonic operation ID prevents stale recovery confirmations from clearing a newer move.
- Refresh catalog-only events separately from task approval; list-only task changes now participate in remote-update identity and diffs. Existing add/edit drafts, datetime offset preservation, local/file-backed project actions, note handling, and authoritative-HA reconnect remain intact.
- Update relevant READMEs, API/configuration/HA/project/development docs and release notes. Server version is `0.2.12`; app version is `0.15.32`, with existing mirrors and release-note pointers updated.

Implementation commits: server `db752b8`, app `337a457`. Parent records both submodule pointers and this task report.

## Safety and compatibility

List administration defaults off through `HA_MANAGE_LISTS=false`. Enabling it with an admin token broadens the privileges available through ntr's unauthenticated API; use a trusted connection or an authenticating proxy. Unsupported actions remain unavailable without disabling ordinary supported task operations.

HA does not offer atomic cross-list moves, conditional item deletion, or empty-check-and-delete. Confirmations and docs require exclusive external-writer access for moves/deletion; ntr cannot eliminate the final HA/external-writer race. It never deletes a source before verifying its target copy. One pending move is allowed at a time; conservatively block both involved lists rather than only their participant tasks. A canceled/uncertain copy without a known target UID requires inspection and abandonment, not guessed recovery.

The catalog is rediscovered from HA, not used as a writable client label store. An unavailable visible list fails the task snapshot; a removed entity disappears from authoritative discovery while its identity tombstones remain. Schema 2 binds the normalized HA URL and records list identity in qualified item keys. Back up the sidecar before migration; older servers require a matching pre-upgrade backup for rollback. Pending journals can contain task content, so keep metadata private. Raw/local fallback files are not list/native-description backups and never upload automatically to HA.

## Verification

| Check | Result |
| --- | --- |
| Server `cargo test --locked` | Passed: 74 tests (52 unit, 22 integration), including multi-list CRUD/restart, migration, duplicate UIDs, WSS/admin/provider guards, confirmed moves, seven failure modes, cancellation, metadata failures, and reconcile/abandon without replay. |
| Server strict locked Clippy and formatting | Passed. |
| App frontend tests | Passed: 762 tests across 48 files, including HA selectors/routing, explicit move confirmation, literal-token preservation, catalog invalidation, destination ownership, and recovery. |
| App `npm run build` | TypeScript and Vite production build passed. |
| App `npm run test:release` | Passed: 52 hermetic release-tool tests; simulated publication logs are fixture behavior, not a real release. |
| App `npm run test:ha-contract` | Passed with actual client serializer, trusted loopback HTTPS/WSS fixture, routing/defaults, confirmed move, native fields, restart IDs, raw-write guard, and public list-management routes. |
| Compose rendering test | Passed; environment injection/private read-only mounts remain intact. No container started. |
| Version mirrors and whitespace checks | Passed. |
| Native `cargo check --locked` | Blocked by missing `pkg-config`/DBus development dependencies in the container. No native build/test pass is claimed; no root installation attempted. |

Tests use generated certificates, disposable tokens, private temporary files, and loopback services. No live HA writes, deployment credential access, Docker startup, publication, or push was performed. Native installation prerequisites remain an operator task; Debian/Ubuntu examples are `pkg-config`, `libdbus-1-dev`, `libglib2.0-dev`, `libgtk-3-dev`, and `libwebkit2gtk-4.1-dev`.

## Usage

Upgrade server and app together. Keep the existing `.env`/token/CA settings and metadata path; `HA_TODO_ENTITY` now selects the default and all visible HA lists appear as projects. Back up metadata before first startup. Set `HA_MANAGE_LISTS=true` only when opting into secured administrative actions with an HA admin token. Use Project selectors for lists, Edit for confirmed moves, and the pending-move notice for explicit recovery. See `server/docs/home-assistant.md` for permissions, migration, concurrency, and rollback limits. Local commits do not update published images or app packages.
