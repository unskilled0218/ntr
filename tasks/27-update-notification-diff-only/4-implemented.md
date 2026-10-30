# Diff-only update notification implementation

- [Diff-only update notification implementation](#diff-only-update-notification-implementation)
  - [Outcome](#outcome)
  - [Changes](#changes)
  - [Verification](#verification)
  - [Limits](#limits)
  - [Version and commits](#version-and-commits)

## Outcome

Implemented the task plan on new parent/app branches named `27-update-notification-diff-only`. Remote-update notifications now display the diff and compact functional controls without visible notification headings, explanations, summaries, legends, error paragraphs, empty-state sentences, or verbose page messages. Existing explicit approval, immutable offer evidence, draft protection, and bounded inspection remain unchanged.

## Changes

- Named the native dialog through resource-specific Task update/Note update accessibility labels instead of a visible heading. Retained its existing ID, modal surface, busy refusal, event ownership, exact-offer callbacks, and Update/Not now actions.
- Converted preparation/application errors to a visible Retry update action with the exact diagnostic in an associated visually hidden accessible alert. Busy state still shows Checking… and disables choices. Errors remain in existing coordinator state; retry still revalidates explicitly.
- Removed preview prose and summary formatting. Kept Diff/Accepted/Incoming controls, escaped text, accessible marker descriptions, and keyboard-scrollable content. User text resembling former notification copy remains intact rather than being filtered.
- Replaced verbose page sentences with Previous/Next controls and a numeric indicator. Navigation is omitted for complete single-page views; multi-page inspection retains continuation/end/remaining-character details in accessible descriptions. Pages replace rather than accumulate content, and offer/view changes reset inspection as before.
- Replaced empty-state prose with an accessibly labelled `∅` marker. Preserved task IDs, raw text, lifecycle state, and dates. Replaced context-omission instructions with typed `@@ … N … @@` metadata and retained trailing-newline distinctions through compact accepted/incoming EOF metadata when those states differ. Metadata participates in the same paging budgets and keeps its accessible labels across fragments.
- Removed the now-unused summary field, counts, and sentence generation from the pure diff helper. Kept comparison budgets, large-input fallback blocks, and full snapshot inspection. Adjusted only remote-specific spacing/metadata color, without modifying rename dialogs or coordinator/native/server behavior.
- Updated root/app README summaries and `app/docs/live-sync.md` for the diff-only presentation, compact controls, accessible retry diagnostics, omission/EOF notation, and paging. Synchronized all existing app patch-version entries to `0.15.23`.

## Verification

- Final `npm test -- --maxWorkers=2 --minWorkers=1` passed in `app/`: **668 tests across 42 files**, with no unhandled errors. Existing intentional backup/read-failure fixtures emitted their expected warnings. Added nine tests overall: six component presentation/accessibility/retry cases, two helper metadata/budget cases, and one real-pane note-preparation retry regression. Updated old heading/summary/page/action expectations without changing unrelated rename assertions or stale-offer validation.
- An earlier default-worker run passed 667 tests before the final note-retry regression was added. A subsequent default-worker run stopped with `Worker exited unexpectedly`, reporting 41 completed files and one unhandled worker error; that run was not treated as a pass, and its chained build did not execute. The final complete run used the explicit worker limits above without altering test configuration or disabling any tests. No assertion failure was reported in the interrupted run; its underlying worker-exit cause was not established.
- Final `npm run build` passed after the complete test rerun, including TypeScript checking and Vite production build at version `0.15.23`.
- `RUST_MIN_STACK=33554432 cargo test -j 1` passed in `app/src-tauri/`: **60 passed, one opt-in real-server restart test ignored**, with no failures. `RUST_MIN_STACK=33554432 cargo clippy --all-targets -j 1` passed without warnings. These command-only settings follow the preceding task's compiler-stack workaround; no native implementation, toolchain, or persistent build configuration was changed.
- Coverage includes named dialogs without visible headings/prose, preserved user copy, empty note/task inspection, metadata-only task changes, compact EOF/omission evidence, bounded paging including metadata and giant lines, all inspection views, navigation hiding/reset, associated hidden errors, explicit same-offer retry, unchanged panes/drafts after failed reads, and existing coordinator/queue/deferred-note safety regressions.
- All six version entries agree at `0.15.23`; updated documentation links resolve. App and parent changed paths passed `git diff --check`. The app working tree was clean after its implementation commit.

## Limits

Manual desktop/mobile appearance, native dialog behavior, actual screen-reader announcements, touch/keyboard acceptance, and visual focus/contrast checks were not performed in this headless container. Tests verify DOM naming, description associations, visually hidden class usage, and behavior through the existing jsdom dialog shim; they do not certify device rendering or assistive-technology acceptance.

The opt-in real-server restart test was not run. No dependencies, protocol changes, server tooling, tags, pushes, releases, deployment, or live data migration were performed. Existing `todo.md` changes and unrelated server work remain untouched and unstaged. The goal, plan, plan review, and review history were not changed during implementation.

## Version and commits

- App version: `0.15.22` → `0.15.23`, synchronized across npm manifests/lock metadata, Cargo manifest/lock, and Tauri configuration.
- App implementation commit: `2c35fb5b069b30767011b2f0ba011ac39bd69d92` (`feat: simplify remote update notifications to diffs only`).
- The parent implementation commit records the app pointer, root README update, and this report. Both implementation branches are named `27-update-notification-diff-only`; the server submodule pointer remains unchanged.
