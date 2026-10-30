# Modal design and update diff implementation

- [Modal design and update diff implementation](#modal-design-and-update-diff-implementation)
  - [Outcome](#outcome)
  - [Changes](#changes)
  - [Verification](#verification)
  - [Limits](#limits)
  - [Version and commits](#version-and-commits)

## Outcome

Implemented the revised task plan, including both plan-review refinements. Rename and remote-update dialogs use a shared selector-style surface. The simplified rename form shows Original and New project name, dismisses after verified success or an unchanged-name submission, and keeps its originating create-task project selector open underneath. Remote task and note notifications show read-only accepted/incoming diffs before approval. Created new `26-modal-design-update-diff` branches in the parent and app repositories rather than reusing implementation branches.

## Changes

- Added shared action-modal styling for both global/draft rename instances and remote notifications, including viewport constraints, long-name wrapping, visible keyboard focus, preview scrolling, sticky approval actions, and a wider remote-preview modifier. Existing IDs and native modal behavior remain intact.
- Replaced normal rename task-count copy and empty status spacing with Original, a labelled editable name, and actions. Draft-only scope stays explicit. Busy/partial/failed/read-only states retain concise status, validation errors, immutable partial targets, destination warnings, Review update, explicit retry, label completion, and stop-retry controls.
- Added a small selector-session interface passed through SelectField/LabelSelect/AddForm to the actual operation owner. Create-task rename retains the same open picker and compact Task options, while removal and ordinary replacement handoffs still close first. Recovery dispatch follows the resolved operation rather than the clicked icon; removal icons can reopen retained rename overlays and vice versa.
- Picker sessions own close/focus behavior. Focus intents wait for controlled mapping revisions to commit, including global rename events consumed by AddForm effects, before targeting a connected new-name row or a valid fallback. Session generations invalidate obsolete close/focus authority. Closing an obsolete picker session cannot close a newer enclosing Options dialog. Cancellation and deferred native-close events are handled once without canceling parent dialogs or submitting task drafts.
- Global automatic dismissal runs after the awaited rename settles and bulk ownership is released, guarded by mounted/transport/record identity. Unchanged-name completion is handled even though it bypasses the normal completion callback. Draft-local rename returns through the same post-commit selector focus path. Removal completion behavior remains unchanged.
- Review update closes rename plus the retained originating picker and compact Options before requesting approval. The stopped operation record remains recoverable; approval neither resumes writes nor reopens the old dialog stack. Partial-operation guards, verified own-response draft mapping, and destination-scoped operation ownership remain in place.
- Remote offers now carry immutable captured baseline and incoming evidence. Successful own-write settlement rebuilds a pending preview against the new accepted baseline, preserving deferred status for the same incoming identity and invalidating old offer clicks/tokens. Existing rereads, mutation epochs, destination/generation checks, error recovery, and synchronous application-token commit remain authoritative.
- Added a pure diff helper and read-only React preview. Notes compare lines with explicit removed/added/context markers, collapsed long context runs, and trailing-newline disclosure. Tasks match stable IDs and show raw text plus completion/creation/completion-date evidence; ID replacement is removed/added, and reordering alone does not invent changes. HTML/Markdown remains escaped text. Accepted and Incoming views inspect the complete saved snapshots, not unsaved drafts.
- Comparison falls back to paged accepted/incoming blocks above 50,000 combined note characters or a 40,000-cell LCS budget. Every preview view uses replace-in-place pages bounded to 8,000 content characters and 80 newline boundaries; oversized lines can continue across pages. Navigation discloses remaining content and resets when evidence/view changes. It never mounts all prior pages or launches an unrestricted comparison through expansion. This addresses review finding F1; revision-gated focus intents address F2.
- Updated the root/app README summaries and dedicated project-renaming/live-sync documentation. Synchronized the existing npm/Cargo/Tauri patch-version entries. No dependency, server protocol, native command, or task removal/deletion semantics were added.

## Verification

- Final `npm test` in `app/` passed: **659 tests across 42 files**. Existing deliberate API backup/read-failure tests emitted their expected warnings. The suite previously had 614 tests across 40 files; this task adds 45 tests and updates behavior assertions that previously required a completed rename dialog and another Close click.
- Final `npm run build` passed after the final CSS adjustment, including TypeScript checking and Vite production build.
- Native verification initially stopped when `rustc` crashed with SIGSEGV during test compilation. Following the compiler's stack-size suggestion, `RUST_MIN_STACK=33554432 cargo test -j 1` passed: **60 tests passed, one opt-in real-server restart test ignored**, with no failed tests. `RUST_MIN_STACK=33554432 cargo clippy --all-targets -j 1` then passed without warnings. The environment override was used only for verification; no toolchain or project configuration was changed to hide the crash.
- Added coverage for normal/compact retained stacks, child-only Cancel/Escape/backdrop dismissal, no-op auto-dismiss, global and staged post-commit target focus, delayed close events, obsolete session refusal, partial-result abandonment, whole-stack remote review handoff, explicit retry, and unchanged task draft fields. Existing removal, suspended edit, collision, connection, partial-label, and note-save safety regressions continue to pass.
- Diff/coordinator tests cover empty/repeated/blank lines, trailing newlines, deterministic work-budget fallback, huge single lines, repeated bounded paging, Accepted/Incoming views, escaped markup, task raw/lifecycle/date changes, ID replacements, reorder-only equality, immutable snapshot capture, deferred-baseline rebasing, stale offer choices, convergence, preparation failures, and replacement-evidence application. Real-pane approval tests show changed preparation reads require a new explicit approval, task/note queues retain independent baselines, and dirty drafts are not used as preview baselines.
- All six app version entries agree at `0.15.22`; updated README/documentation links resolve. App and parent changed paths pass `git diff --check`. The app working tree was clean after its implementation commit.

## Limits

Manual desktop/mobile rendering, real native dialog top-layer ordering, actual keyboard/touch interaction, screen-reader acceptance, and visual contrast checks were not performed in this headless container. Automated modal tests use the existing jsdom dialog shim and do not establish device acceptance. Long content is paged by UTF-16 character offsets and newline boundaries, not by visual wrapped-line height; preview scrolling and viewport constraints handle wrapping.

The opt-in real-server restart test was not run. No server suite, server tooling, dependency installation, tags, push, release, deployment, or live user-data migration was performed. Existing `todo.md` changes and unrelated server work remain untouched and unstaged. Task/label writes remain non-transactional and last-write-wins; pending operation records are still mounted-pane state rather than a durable journal. Remote diffs compare accepted task/note snapshots, not remembered-label files or unsaved drafts.

## Version and commits

- App version: `0.15.21` → `0.15.22`, synchronized across npm manifests/lock metadata, Cargo manifest/lock, and Tauri configuration.
- App implementation commit: `76d48cc8e25bce19ed1929ba5453fa1ed1355700` (`feat: unify rename modals and preview remote update diffs`).
- The parent implementation commit records the app pointer, root README changes, and this report. The goal, plan, plan review, and review history remain unchanged during implementation.
- Parent and app implementation branches are both named `26-modal-design-update-diff`. The server submodule pointer remains unchanged.
