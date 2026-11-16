# Plan

- [Scope](#scope)
- [Implementation](#implementation)
- [Verification](#verification)
- [Delivery](#delivery)

## Scope

Rename the task-grouping concept from Project to List in app/server code, tests, UI, accessibility labels, CSS/DOM identifiers, and maintained docs. Do not rename unrelated software-project references or task projection operations. No layout or workflow change is intended, so no design is required. Preserve task content, HA routing/recovery guarantees, signing identity, historical records, vendor content, and the user's `todo.md` edit.

## Implementation

1. Create fresh `41-rename-project-to-list` branches in parent/app/server. Rename grouping types, fields, functions, component/helper/test filenames, imports, and label-kind/sort keys to List/list/lists. Preserve existing native HA list catalog operations and their meaning.
2. Keep existing HTTP task JSON `projects`, labels JSON/storage `project`, and HTTP query `project` as explicit compatibility boundaries. Rename Rust domain fields to `lists`/`list` with serde mappings where needed; centralize frontend wire conversion so components use only new domain names. The native task DTO and command argument names may follow the new app-internal contract. Contract tests must still prove old HTTP clients and stored labels work. No raw task syntax or metadata migration is needed.
3. Rename the frontend sort key to `lists`; map stored `ntr.sort=projects` on read without losing direction or mutating unrelated settings. Keep persistent keys stable. Add focused regressions for old sort preferences, existing labels storage, old HTTP task/label payloads, filters, and task mutation readbacks/approval.
   Cover create/update/complete/reopen task responses and local label backups at the adapter boundary, not only task-list GETs. Keep literal legacy-wire fixtures independent of renamed domain fixtures.
4. Update grouping labels/messages across desktop/compact controls, add/edit forms, selectors, rename/remove/recovery, sort/filter, and HA management. Update corresponding tests, including real transport contract scripts, without weakening behavior assertions. Keep literal task text lossless, even when it contains the word project.
5. Update maintained README/topic docs to List terminology. Keep existing document paths/anchors where historical links rely on them; remaining old words at documented compatibility boundaries are intentional. Bump app to `0.15.35` and server to `0.2.16`, update mirrors/release pointers, and add concise release notes. Preserve dependencies and signing configuration.

## Verification

- Run frontend tests with `NODE_OPTIONS=--no-experimental-webstorage`, production build, app native tests/clippy, server tests/fmt/clippy, task/HA transport contracts, release validators, and relevant release-tool tests. Record unavailable tools and pre-existing failures accurately; the server Python release suite already contains a stale `0.2.9` assertion and is not to be silently fixed as part of this task.
- Check remaining Project/project references: only explicit wire/storage/backward-compatibility names, legacy preference tests, unchanged task-data fixtures, historical/vendor material, or unrelated software/projection meanings may remain. Verify renamed imports and selectors, maintained local links/anchors/TOCs, and whitespace.
- Confirm no data files, archived tasks/releases, vendor code, dependencies, or unrelated user work changed. Validate existing wire keys and stored labels independently of newly renamed fixtures. No live HA operations, publication, deployment, or push.

## Delivery

Record implementation and exact test outcomes in `5-implemented.md`. Commit app/server first, then parent docs/report/submodule pointers. Keep `todo.md` unstaged. Notify after each workflow stage; do not merge or push without a separate request.
