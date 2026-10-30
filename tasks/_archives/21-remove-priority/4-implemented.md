# Implementation

- [Implementation](#implementation)
- [Changes](#changes)
- [Verification](#verification)
- [Limits and retained plan policy](#limits-and-retained-plan-policy)
- [Repositories and versions](#repositories-and-versions)

## Changes

Removed priority controls and state from add/edit forms, dedicated row rendering and styles, picker configuration, frontend task/filter fields, transport arguments, and priority sorting. Stored priority sorting falls back to file order without changing direction. Project picker cancellation and handoff coverage remains.

Both Rust task models now retain only a compatibility-only leading legacy token, before lifecycle dates on active or completed lines. Completion and reopening never move that token or interpret ordinary `pri:` text. Removed priority fields from DTOs and stores. HTTP listing explicitly rejects any decoded priority query key, including bare, empty, invalid, repeated, and encoded keys, before validating supported filters. Tauri listing accepts omitted/null compatibility arguments but rejects every non-null value before locking or querying the store.

The client edit serializer recovers hidden tokens exclusively from raw text, ignoring older JSON priority fields. It validates raw completion state, lifecycle dates, and description against the DTO and fails visibly without writing when reconstruction is unsafe. Submitted descriptions beginning with a complete uppercase token are rejected inline without clearing form state. The editable description retains every `pri:` occurrence and order; the serializer never resurrects deleted values from the collapsed tags map. Other metadata handling remains intact.

Added equivalent Rust lifecycle and whole-store persistence fixtures, UI/serializer/filter/transport/settings regression tests, and a headless local-store example plus `npm run test:task-contract`. The integration runner bundles the real client serializer and exercises real local files and HTTP servers, including old/new DTO shapes, repeated and deleted text tokens, unsafe raw data, malformed and embedded tokens, lifecycle dates, unrelated writes, and old-server conversions. Updated relevant READMEs and dedicated compatibility/API/todo.txt/development documentation without migrating task files or modifying historical task records.

## Verification

- `npm test` in `app`: passed 501 tests across 33 files. Expected stderr from existing intentional failure-path tests remains.
- `npm run build` in `app`: passed TypeScript checking and the Vite production build.
- `cargo test --locked` in `app/src-tauri`: passed 59 tests; the existing real-server restart test is ignored by default. Ran that test separately with `MY_NTR_SERVER_BIN=/home/container/workdir/ntr/server/target/debug/my-ntr-server cargo test --locked two_clients_sync_and_recover_missed_files_after_real_server_restart -- --ignored`; it passed, covering all 60 local tests across the two commands.
- `cargo test --locked` in `server`: passed 40 tests: 25 unit, 12 API integration, and 3 task-date integration tests.
- `TMPDIR=/tmp/opencode OLD_NTR_SERVER_BIN=/tmp/opencode/ntr-21-old-server-bin npm run test:task-contract`: passed local, new-server, and real old-server checks. The old server was built from committed pre-change source `55ded61a057caa390dd6a8e465b0e50a905e8961` in a separate temporary source/target directory. Assertions verify old-server edits preserve legacy tokens but completion/reopening can convert or consume them; they do not claim the new-server lifecycle guarantee.
- `cargo clippy --all-targets --locked -- -D warnings` in `server`: passed without warnings.
- `python3 -B -m unittest test_bash_release.DataTests -v` and the targeted `BashReleaseTests.test_consumer_settings_version_notes_and_runtime_contract` in `server/tests`: passed 12 tests in total. The complete unrelated release-publication Python suite was not rerun.
- Version mirror checks, matching local/server task-model checks, changed documentation file-link checks, and parent/submodule `git diff --check`: passed.

## Limits and retained plan policy

The latest plan-review warning about existing visible descriptions beginning with `(A)` after lifecycle dates remains a deliberate limitation of the unchanged plan's unconditional submitted-description guard. For example, unchanged form submissions for `2026-06-01 (A) call` and `x 2026-06-02 2026-06-01 (A) call` are rejected rather than saved; tests assert no persisted changes. Users must move the visible token later before saving. This differs from a hidden leading legacy token, which unchanged edits preserve. The limitation is documented in `app/docs/task-text.md`; no safe exception or data migration was introduced beyond the plan.

The first final-version local Rust test attempt hit a cached `dbus` linker artifact error (`invalid symbol name offset`). Rebuilding only that generated package with `cargo clean -p dbus` resolved it, and the required local tests passed afterward. Optional app Clippy could not complete: Rust 1.99.1 crashed in dependency compilation, first with SIGSEGV in `regex-automata`, then with `Missing SyntaxContext 17018 for crate "icu_normalizer_data"` while compiling `icu_normalizer` after retrying with `RUST_MIN_STACK=33554432` and two jobs. App Clippy is not reported as passing.

No native desktop/Android interactive smoke test, release publication, remote push, production data migration, or production server mutation was performed. Exact lifecycle preservation requires the new local backend or upgraded server; old clients remain unsupported for priority-dependent behavior.

## Repositories and versions

Created fresh branches named exactly `21-remove-priority` in the parent, app, and server repositories. Prepared app `0.15.18` across package, lockfile, Cargo, and Tauri mirrors. Prepared server `0.2.8` across VERSION, Cargo, release configuration, current links, consumer expectations, and new release notes. These versions are prepared locally, not published. Implementation is committed separately in each submodule, and the parent commit records their new pointers, this report, and its README update. `todo.md` remains untouched.

App implementation commit: `4f4f871` (`Remove priority features while preserving legacy task data`). Server implementation commit: `9a635f1` (`Remove priority contracts and preserve legacy tokens in server 0.2.8`).
