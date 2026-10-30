# Project selector actions implementation

- [Project selector actions implementation](#project-selector-actions-implementation)
  - [Outcome](#outcome)
  - [Changes](#changes)
  - [Verification](#verification)
  - [Limits](#limits)
  - [Version and commits](#version-and-commits)

## Outcome

Implemented accessible pencil/trash project actions in the Project filter and create-task Project selectors, including compact layouts. Removed the standalone `Review rename progress` control; unfinished rename and removal results remain reachable through related project actions or separate recovery entries inside the selectors. Created new `25-project-selector-actions` branches in the parent repository and app submodule. The goal, plan, review, `todo.md`, and unrelated server work were not changed.

## Changes

- Added small inline SVG pencil/trash icons with project-specific accessible names, tooltips, decorative/non-focusable SVG markup, visible focus styles, and touch-sized controls. Project names remain separate selectable buttons. Sentinel choices, sort controls, context controls, edit-task selectors, and task-row Edit/Delete buttons do not gain project management actions.
- Extended selector contracts with ordinary known/staged scope plus retained-operation identity and destination. TodoPane resolves same-destination recovery before ordinary scope, so a staged-only old source can reopen its global rename rather than starting a separate local mutation. Related removal/rename actions expose the existing result instead of overwriting it. Unrelated staged renames cannot take a retained operation's reserved source/target name.
- Routed known-project actions from the create-task selector through the existing global task/label APIs and coordinator validation. Staged-only actions remain in AddForm: confirmation changes only selected/staged/exact inline project references in that draft. Scope, destination, and draft changes are checked again at confirmation; a staged source becoming globally known requires a new scope confirmation rather than expanded write authority.
- Closed selectors and enclosing compact Options dialogs before action handoff. Action dialogs remain outside the task form's submission ancestry, and focus returns to the actual create-task/filter trigger. Added owned close/cancel handling for removal so one dismissal does not invoke its callback twice. Confirming an action does not submit or reset the create-task draft.
- Added a concrete removal operation helper with explicit phases, acknowledged task responses, remaining work, uncertain-write evidence, label verification, and completed/partial/failed outcomes. Successful task responses alone update the accepted projection. Partial removal keeps its source draft guard and result after dialog closure; fresh explicit retry handles remaining task work or labels alone. Failed label reads never become empty replacements, and a verified uncertain label write does not issue another PUT.
- Retained at most one unfinished global operation per destination, with one active write attempt at a time. Opening a related icon or in-selector fallback is read-only; approval never resumes a job. Missing source/target rows have separate recovery entries rather than fake selectable projects. Older destinations' results remain separately labelled and read-only while a legitimate same-name action runs on the current destination.
- Added explicit stop-retry handling for removal, matching rename's existing resolution semantics: completed writes remain, no rollback or success mapping is claimed, and only that record's draft restrictions are released. Close/Escape/backdrop after a stopped attempt retain recovery state. In-dialog Review update releases modal ownership before approval, with no automatic stale-ID replay.
- Added a destination-scoped confirmed removal event. Only observed full task/label completion retires matching selected/staged/inline draft references; unrelated fields and note content remain. Suspended edit drafts rebase only onto matching verified own responses. Own project-write responses also retain task-derived project suggestions without per-task remembered-label write-through.
- Updated the app/root READMEs, feature/live-sync documentation, and dedicated project-action documentation for icons, draft-local/global scope, selector-based recovery, partial removal, and destination ownership. Historical task reports were not rewritten.

## Verification

- `app/`: final `npm test` passed, **40 files and 614 tests**. Existing deliberate backup/read-failure fixtures produced their expected warnings. Added nine removal-helper tests, 21 real-pane selector-action tests, and two focused picker/form regressions; existing rename recovery tests now use selector entry points instead of the removed control.
- `app/`: final `npm run build` passed, including TypeScript checking and Vite production build.
- `app/src-tauri/`: `cargo test` passed, **60 tests** with one opt-in real-server restart test ignored by default. `cargo clippy --all-targets` passed without warnings. Both commands compiled app version `0.15.21`; no native command or HTTP/SSE protocol was changed.
- Integration coverage includes normal/compact create-selector actions, accessible icon metadata and no accidental submission, staged-only changes with no stored writes, changed-scope rejection, cancellation, focus return, global removal without task deletion, retained drafts/due dates, partial retries, label-only/uncertain removal completion, explicit abandonment, missing-row fallbacks, reserved-name blocking, staged-source recovery precedence, foreign-change approval handoff, pending dirty-note save guards, suspended edit rebase, and separate same-name operation ownership across destinations.
- Unit coverage verifies exact project-token removal, unrelated metadata/text preservation, observed task/label completion, partial response retention, remaining-task retry, uncertain label verification, failed reads, foreign divergence, unexpected label mixtures, and destination invalidation. Picker tests inspect keyboard-native button semantics and keyboard-shaped click handling; they do not claim actual device keyboard acceptance.
- All six version entries agree at `0.15.21`: npm manifest, package-lock root/package metadata, Cargo manifest/lock, and Tauri configuration. Updated Markdown documentation links resolve. `git diff --check` passed for the app and the parent paths changed by this task before commits.

## Limits

Manual desktop/mobile checks, screen-reader acceptance, real touch targets/tooltips, and actual-device focus behavior were not performed in this headless container. Automated dialog checks use the existing jsdom shim. The opt-in real-server restart test was not rerun for this task; no server suite or server tooling was run against the unrelated server work.

Task and remembered-label writes remain non-transactional and last-write-wins. Issued requests cannot be recalled; validation narrows but does not eliminate races. Labels-only changes still have no dedicated SSE token, and older writers can restore cached labels. Pending operation records live only in the mounted pane, not a durable journal across app restarts. A project-only task may require meaningful text before removal can succeed without producing an invalid empty task; no task is silently deleted to resolve it.

No dependencies were installed. No tags, pushes, releases, deployment, or live user-data migration were performed. Existing `todo.md` changes and untracked server work were left unstaged and untouched.

## Version and commits

- App version: `0.15.20` → `0.15.21`, synchronized across npm, Cargo, lockfiles, and Tauri configuration.
- App implementation commit: `1a67d99af3333c7912910a0dffdeef0d061d6f3b` (`feat: add icon project actions and selector recovery`).
- The server submodule pointer remains unchanged at `06f28ab31b34c647bca216ced7e988184665ee69`; no server change is part of this implementation.
- The parent implementation commit records the app pointer, root README update, and this report. Both newly created implementation branches are named `25-project-selector-actions`.
