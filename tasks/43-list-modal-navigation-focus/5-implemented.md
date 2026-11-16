# Implemented

- [Changes](#changes)
- [Safety and compatibility](#safety-and-compatibility)
- [Verification](#verification)
- [Limits](#limits)
- [Delivery](#delivery)

## Changes

Cancel, Escape, and backdrop dismissal from Add/Remove list now return to the retained originating picker, preserving selection and unsaved task fields. Covered local Add/Edit creation, staged/global removal from add/filter selectors, and HA create/delete prompts, including compact options. Successful creation still selects/stages the new list and closes its picker; global removal retains its explicit result/recovery handling.

Extended `SelectField` with explicit retained action choices and a scope key. Single-use selector sessions restore focus to the Add/Remove action, retain revision-aware rename focus, and cannot close/focus/resurrect a newer or detached picker. Layout/destination changes and edit suspension invalidate child ownership. Review update closes retained picker/options stacks before approval.

Picker scroll surfaces now reserve 4px for the 2px blue outline plus 2px offset. Focused rows use local stacking priority so adjacent backgrounds cannot cover their outlines. Scrolling, selected/danger states, and native top-layer ordering are preserved; no focus indicator is hidden.

Removed `Changes this draft only.` from draft rename reached through the add-list picker. Local list removal displays `Remove <name>` with the literal selected name and no syntax prefix/old explanatory paragraph. Progress, errors, partial-operation warnings, and HA deletion safeguards remain. The generic context-removal copy is unchanged.

Prepared app `0.15.37` with exact version mirrors, new notes, and README/topic documentation updates. Server version/commit, dependencies, signing identity, and data formats are unchanged.

## Safety and compatibility

Cancellation performs no task, label, or HA writes. Busy operations still reject dismissal; destination/catalog checks, sequential write/retry authority, uncertain-write handling, and explicit recovery remain intact. Native/API/serializer/write/recovery implementations are unchanged. Filter rename retains its prior stack-closing behavior; existing retained rename behavior from the add selector remains revision-aware.

## Verification

- Targeted selector, Add/Edit, removal, HA, lifecycle, retained-operation, and appearance suites passed before the full run. Existing assertions were updated for intentionally retained pickers/minimal copy, without removing no-write, draft-preservation, or busy/recovery assertions.
- `NODE_OPTIONS=--no-experimental-webstorage npm test`: all 833 tests across 49 files passed, including 44 added regressions. Coverage includes local/HA cancellation matrices, literal selection/draft preservation, no writes, single-use/stale sessions, destination/layout invalidation, edit suspension, delayed close delivery, busy local/HA removal, filter-stack approval handoff, and outline-clearance/stacking rules.
- `npm run build`: TypeScript and production bundling passed.
- `./scripts/release.sh --validate`: passed offline version/configuration checks. `npm run test:release`: all 52 tests passed; simulated publication output was hermetic fixture behavior.
- `/tmp/opencode/task43-check.py`: passed 19 maintained/task pages, 130 local links, 11 shell blocks, TOCs/anchors, unchanged native/server/API/write/recovery code, exact dependency/signing preservation, protected release/vendor/prior-task content, original `todo.md`/`command.md` hashes, and whitespace.

## Limits

No real browser executable was available in PATH/cache. DOM/focus/CSS-policy tests do not prove actual browser outline geometry, native top-layer focus restoration, Android rendering, or virtual-keyboard behavior. No screenshots, device checks, native/server suites, serializer contract reruns, live HA operations, publication, deployment, merge, or push were performed. No native/server/serializer/write implementations changed.

## Delivery

Work uses fresh parent/app `43-list-modal-navigation-focus` branches, preserving tasks 41/42. Commit app first, then parent README/report and app pointer. Server, `todo.md`, and `command.md` remain unstaged and unchanged. No unrelated user work was discarded.
