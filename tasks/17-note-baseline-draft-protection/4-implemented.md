# implemented

- [Changes](#changes)
- [Verification](#verification)
- [Limits And Deferred Work](#limits-and-deferred-work)
- [Release And Commits](#release-and-commits)

## Changes

- Created fresh `17-note-baseline-draft-protection` branches in the parent and app repositories. Implemented the plan without changing transport APIs, the server, SSE behavior, or independent-client last-write-wins semantics. `todo.md` was left untouched.
- Added a committed local-edit revision to `NotePane.tsx`, separate from saved-text equality and read-invalidating baseline revisions. Ordinary input, chunk operations, committed IME input, and successful undo advance this revision; remote painting and transport activation do not.
- Save attempts now capture their submitted text and edit revision. A single pane-local unresolved-save record retains the current editor's destination/lifetime-scoped evidence after the PUT releases its destination slot. Same-target activation, failed or canceled reads, and conflict-producing reads do not erase that evidence.
- Reconciliation checks editing intent when applying the current GET result, including edits made after PUT settlement while that GET was pending. An apparent clean `adopt` becomes an existing conflict when it would discard newer editing that restored the old baseline. Keep mine persists the current draft, including an empty string; Use theirs explicitly adopts the fetched text.
- Authoritative convergence, a successful current save, and a valid explicit conflict choice retire resolved evidence. Retirement is identity-checked for read/save continuations. An authoritative editor replacement or unmount clears the previous editor's evidence. Existing `noop` behavior and ordinary no-activation automatic saving remain intact.
- Target changes recognize a protected baseline-return edit as a draft even when it equals the old saved text. After an explicit remote replacement, returning cleanly to a target with an old pending PUT seeds evidence at the current editor's revision, preventing unrelated edits from leaking across targets while protecting new edits made during that return. Existing per-destination slot ownership and independent A/B writes remain unchanged.
- Added 39 permanent component cases, increasing `NotePane.test.tsx` from 47 to 86 tests. A shared deferred-storage fixture models commits independently from response success. Coverage includes both baseline values, undo and ordinary input at three timing points, both conflict choices, no-activation controls, committed IME, canceled/retried reads, repeated settings activation with an open conflict, response failure after a commit, safe convergence, target isolation, pagehide, and settlement-first detection of activation. Existing boundary tests were retained without expectation changes.
- Updated `app/README.md` and `app/docs/live-sync.md` to explain baseline-return editing safety, conservative conflict choices, provenance retirement, and response-failure uncertainty. No new synchronization framework, classifier API, or conflict UI was introduced.

## Verification

- Before production changes, `npm test -- src/components/NotePane.test.tsx -t baseline-return` failed all 24 new activation cases and passed all four no-activation controls; 47 unrelated cases were skipped. Each failure silently changed the newer editor baseline back to the older submitted snapshot. Cases covered nonempty/empty baselines, undo/input, editing before activation/during PUT/during GET, and both eventual conflict choices.
- After implementation, `npm test -- src/components/NotePane.test.tsx src/lib/resourceRefresh.test.ts src/lib/noteSync.test.ts` passed: 94 tests across three files. Tests assert retained editor text, explicit conflict behavior, eventual modeled storage contents, blocked writes during deferred PUT/GET work, and later clean-update adoption after resolution. These permanent cases do not depend on temporary review probes.
- Final `npm test` in `app/` passed at version `0.15.17`: 485 tests across 33 files. All existing 446 tests remain passing. The existing disk-full backup and failed-reconciliation fixtures emitted their expected diagnostics; Vitest reported no unhandled errors.
- Final `npm run build` in `app/` passed TypeScript checking and Vite production bundling.
- `git diff --check` passed for the app changes. A script verified all six release version fields: npm package and both lockfile fields, Cargo package and lockfile, and Tauri configuration agree on `0.15.17`. Dependencies were not upgraded.

## Limits And Deferred Work

- No interactive GUI or device check was performed: neither `DISPLAY` nor `WAYLAND_DISPLAY` is configured. The regression suite models unchanged-settings activation, DOM editing, history, composition, conflict choices, and deferred transport; it does not claim physical-device, proxy/TLS, network-interruption, or two-window verification.
- Native tests and real-server restart integration were not rerun for this frontend-only behavior change. Rust implementation and dependencies are unchanged; native metadata changed only for the synchronized patch version.
- The separate inherited warning about unmount during the post-save recovery await remains unresolved and outside this task. The existing continuation after that await was not changed, and this task does not claim its lifetime-safety sequence was verified.
- A conservative conflict can still be appropriate when a differing fetched snapshot may be the pane's own obsolete write. Editing evidence protects the current draft; it does not prove which client last changed storage or provide collaborative merging or server-side conditional writes.
- Ownership and editing evidence remain local to the mounted pane. They do not serialize independent clients, unrelated API writers, remounted panes, or URL aliases sharing storage. An indefinitely pending PUT retains its destination slot; accepted server writes cannot be recalled.
- No system packages, host configuration, publication, push, merge, or unrelated user changes were included.

## Release And Commits

- Increased the app patch version from `0.15.16` to `0.15.17` across npm, Cargo, and Tauri release metadata, following the existing convention.
- App commit: `0f634d3` — `Protect baseline-return note drafts during save recovery`.
- The parent commit records this report and the updated app submodule pointer. The server submodule remains unchanged.
