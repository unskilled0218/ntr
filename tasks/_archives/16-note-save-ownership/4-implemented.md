# implemented

- [Changes](#changes)
- [Verification](#verification)
- [Limits And Deferred Work](#limits-and-deferred-work)
- [Release And Commits](#release-and-commits)

## Changes

- Created fresh `16-note-save-ownership` branches in the parent and app repositories. Implemented the plan without changing transport APIs, server code, SSE behavior, or independent-client last-write-wins semantics.
- Replaced `NotePane`'s resettable save boolean with a pane-local collection of outstanding attempts keyed by server URL or local-directory generation. Each attempt captures its view context and lifetime; settlement removes only that exact attempt. Context invalidation and unmount no longer clear outstanding ownership prematurely.
- Normal, explicitly authorized, and pagehide saves share the same destination slot. Reconciliation and refresh eligibility check that destination's outstanding ownership. Different destinations can proceed independently, while switching A-to-B-to-A retains A's original slot until settlement.
- A stale same-destination completion cannot update the saved baseline, status, or editor from its obsolete result. Once it releases its slot, it requests reconciliation using the current transport. Pending or failed recovery reads continue blocking automatic saves. Newer drafts survive; a differing remote snapshot uses the existing Keep mine / Use theirs dialog rather than silently adopting old text.
- Pagehide now enters the ordinary owned-save path and retains best-effort rejection handling. Repeated pagehide events cannot issue overlapping writes. Current-generation success/error handling and the existing post-save continuation remain otherwise unchanged.
- Added ten component regression cases, increasing `NotePane.test.tsx` from 37 to 47 tests. Coverage includes deferred modeled storage commits, unchanged settings, recovery GET blocking, both explicit conflict choices, repeated activations, certificate-policy changes, rejected obsolete PUTs, failed GET retries, independent A/B writes, return to A, local-directory generations, pagehide-originated success/failure, and PUT completion after unmount.
- Updated `app/README.md` to link live-sync documentation. Expanded `app/docs/live-sync.md` with destination ownership, recovery ordering, conservative conflicts, focused verification, and the limits of pane-local serialization.

## Verification

- Before implementation, `npm test -- src/components/NotePane.test.tsx -t "serializes saves across unchanged settings"` failed both new variants: expected one outstanding write, observed two. The deferred storage model reproduces the original same-client ordering regression without changing production transport behavior.
- After implementation, `npm test -- src/components/NotePane.test.tsx src/lib/resourceRefresh.test.ts src/lib/noteSync.test.ts` passed: 55 tests across three files. The primary regression holds the first PUT, attempts more save triggers after unchanged settings, then holds recovery GET before allowing a newer write. Both editor text and modeled persisted text are checked.
- Final `npm test` in `app/` passed at version `0.15.16`: 446 tests across 33 files. The existing disk-full backup and failed-reconciliation fixtures emitted their expected diagnostics; Vitest reported no unhandled errors.
- Final `npm run build` in `app/` passed TypeScript checking and Vite production bundling.
- `git diff --check` passed for app changes before committing. A script checked all six release version fields: npm package and lockfile fields, Cargo package and lockfile, and Tauri configuration all agree on `0.15.16`.

## Limits And Deferred Work

- No interactive GUI verification was performed: neither `DISPLAY` nor `WAYLAND_DISPLAY` is set in this container. The component regression models the actual unchanged-settings activation and note-refresh calls with deferred transport promises; it does not claim desktop/mobile, device, network-interruption, or proxy verification.
- Native tests and external-server restart checks were not rerun for this frontend-only behavior change. Native files changed only for the synchronized release version; no Rust implementation or dependency changes were made.
- The previous review's separate warning about unmount during the post-save recovery await remains unresolved and outside this task. The new late-PUT-after-unmount case covers settlement ownership, not that different recovery-await sequence. Passing tests do not retire the deferred warning.
- An obsolete successful write can conservatively produce a conflict with newer input. Keep mine persists the retained draft; Use theirs explicitly replaces it. A stalled PUT retains its destination slot until settlement rather than freeing it on an arbitrary timeout.
- Ownership is scoped to writes from the mounted pane. It does not serialize independent clients, API writers, remounted panes, or different URL aliases for the same storage. Requests already accepted by storage cannot be recalled.
- `todo.md` and the unrelated `tauri.Dockerfile` were left untouched and excluded from these commits. No system packages, host configuration, publication, push, or merge was performed.

## Release And Commits

- Increased the app patch version from `0.15.15` to `0.15.16`, following the existing npm/Cargo/Tauri release convention. Dependency versions remain unchanged.
- App commit: `694c138` — `Preserve note save ownership across transport activations`.
- The parent commit records this report and the updated app submodule pointer. The server submodule remains unchanged.
