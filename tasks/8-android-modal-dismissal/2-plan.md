# plan

## scope

Fix dismissal isolation across all app modals on Android, with desktop regression coverage. A backdrop tap, Cancel/Done action, or supported native cancel must dismiss only the topmost modal. `Options > Project` is a reproduction example, not a scope limit. Preserve underlying state and each modal's existing selection, confirmation, and cancellation semantics.

Production work belongs in `app/src/components`: the shared dialog event handling and all ten native-dialog components, plus their behavioral tests. Keep existing native dialogs and state ownership. No storage, server, or Rust behavior change is needed.

## Implementation Plan

### 1. Establish the event failure and modal inventory

- Add a failing regression for an actual `OptionsModal` containing `SelectField`. Open both, dismiss the child by Cancel and backdrop independently, and assert that Options stays open and the child can reopen. Include choosing a project, which also closes the picker.
- Trace `close`, `cancel`, and click events separately. `useBackdropClose` already checks native click target identity, but `OptionsModal`, `SelectField`, and `SortField` currently accept any React `onClose` event. Installed React DOM accumulates close/cancel listeners along the React ancestor tree even for non-bubbling native events. This explains a plausible route from a child close to closing Options; reproduce it in regression tests before treating it as the complete Android cause.
- Inventory every `<dialog>` and classify its owner: self-owned `OptionsModal`, `SelectField`, `SortField`; externally controlled `SettingsModal`, `EditTaskModal`, `LabelModal`, `RemoveLabelDialog`, `ConflictDialog`, `NoteConflictDialog`, `OpenLinkDialog`.
- Inspect supported DOM-nested and sibling stacks: filter/task Options > picker; Settings > startup/conflict-strategy picker; Edit task > priority/project picker or LabelModal; task Options > project picker > replacement LabelModal; filter Options > project picker > replacement removal confirmation. Label creation/removal closes the picker first and opens a different modal over the remaining parent; preserve that handoff.
- Include asynchronous sibling overlays such as server/local or note conflicts appearing while another modal is open. Browser modal top-layer ordering, not DOM ancestry, determines the interactive topmost dialog. Do not invent new nesting just to satisfy a test.

### 2. Isolate close and cancel events consistently

- Introduce a small typed dialog-event helper in `app/src/components/dialogEvents.ts` to accept only events with `event.target === event.currentTarget` and stop propagation of accepted dialog lifecycle events. Reuse this ownership check rather than duplicating subtly different rules across modal families.
- Apply the helper before any callback, state update, or `preventDefault()` in React close/cancel handlers. Ancestors must ignore descendant events, and a handled child lifecycle event must not invoke ancestor handlers.
- Return shared guarded close/cancel handlers from `usePickerDialog` and wire them into Options, Select, and Sort. Own close synchronizes `open` to false; own cancel isolates the event while retaining native cancellation and its resulting close event. Keep Select choice/Cancel, Sort Done/live selections, and Options Done behavior unchanged.
- Wrap the existing close callbacks in `LabelModal`, `RemoveLabelDialog`, `ConflictDialog`, `NoteConflictDialog`, and `OpenLinkDialog`. Add cancel isolation without introducing a second dismissal callback: those dialogs currently rely on native cancellation followed by close. Preserve label cancellation, non-destructive server conflict dismissal, note keep-mine dismissal, and link/removal cancellation.
- Guard `SettingsModal` and `EditTaskModal` native cancel handlers before their existing `preventDefault()` and owner callback. Preserve their state-driven backdrop overrides and button paths; child cancellation must not call the owner's close callback or cancel the child's default behavior. If native close synchronization is added, avoid calling the owner again when a prop-driven effect closes an already-dismissed dialog.
- Ensure a user dismissal produces one effective owner transition. A later programmatic close caused by a prop change must not repeat semantic actions, clear a newly opened replacement modal, consume another queued conflict, or dismiss a parent. Keep successful confirmation callbacks distinct from cancellation and add a narrow lifecycle guard only where tests demonstrate it is needed.
- Retain the native backdrop target check in `useBackdropClose`. Update its misleading claim that nesting works automatically to distinguish native click targeting from React close/cancel propagation. If device tracing reveals click-through after child removal, handle that gesture at the shared boundary with a failing regression rather than adding unrelated timers or per-modal Android workarounds.
- Keep native focus trapping, inert background behavior, and focus return. Do not portal or flatten all dialogs as a substitute for event ownership, add a global Escape/Back listener, or replace existing state owners with a new modal manager.

### 3. Add behavior-based coverage for every modal family

- Extend Options tests with real Select and Sort children. Assert child-only dismissal by backdrop, Cancel/Done, and native cancellation; selection closes Select only, while changing Sort retains its live-update behavior. Assert the remaining parent can be dismissed by a second action and the child can reopen.
- Extend Settings and EditTask tests with stateful owner harnesses that actually update `open`/`task` when closed. Dismissing a child must retain typed Server URL or task description/due/project fields, leave the parent open, and avoid settings reconnect/reload or task save side effects.
- Cover Edit task > LabelModal, plus the sibling label-add/removal handoffs from task/filter Options. Cancelling the new label or removal confirmation must leave the surviving parent usable, preserve existing values, and perform no task creation or label deletion.
- Cover standalone dismissal and callback semantics for all ten components. For conflict and link/removal dialogs, assert that cancel/backdrop performs no confirmation write or browser open; preserve NoteConflictDialog's keep-mine contract. Exercise an overlapping sibling dialog setup and require one action to close only the current top layer.
- Dispatch native `cancel` as a non-bubbling, cancelable event. jsdom does not implement its default close action: in test support, perform the default close only when cancellation was not prevented. Assert native `close` and React propagation without setting artificial `bubbles: true` just to create the failure.
- Keep jsdom support faithful: `close()` on a closed dialog should not dispatch another close event. Current shared `src/test/setup.ts` always dispatches one, and `NotePane.test.tsx` overrides that implementation locally. Align these shims if required for lifecycle tests, and account for browser close-event task timing in focused tests rather than assuming the synchronous shim proves replacement-modal safety.
- Prefer observable open state, preserved inputs, callback side effects, and reopening over assertions that only verify `stopPropagation` was called. Do not introduce production methods solely for tests.

### 4. Verify Android and desktop behavior

- From `app`, run focused tests with `npm test -- src/components/OptionsModal.test.tsx src/components/SelectField.test.tsx src/components/SortField.test.tsx src/components/SettingsModal.test.tsx src/components/EditTaskModal.test.tsx src/components/RemoveLabelDialog.test.tsx src/components/ConflictDialog.test.tsx`, adding any new dialog test files to that command.
- Run `npm test` and `npm run build` from `app` for the full frontend suite and TypeScript/Vite checks. Run `git diff --check` in both repositories.
- On an available Android device/emulator, exercise backdrop taps, each actual dismissal button, and Back where the WebView delivers native dialog cancellation. Test Options > Project/Sort, Settings > both pickers, Edit task > priority/project/new label, sibling label/removal handoffs, and supported asynchronous conflict overlays. Repeat open/dismiss/reopen cycles and check pending values and focus. Record Android and Android System WebView versions.
- Verify standalone label, removal, server conflict, note conflict, and link dialogs on Android, including non-destructive dismissal and unchanged confirmation behavior. Use disposable task/note fixtures for operations that write data.
- Run representative desktop browser/Tauri checks with real native dialogs, including Escape, Cancel/Done, backdrop dismissal, input preservation, and child-to-parent focus return. Native dialog top-layer behavior cannot be established by jsdom alone.
- Attempt `npm run tauri android build` when the installed environment permits it. Report SDK, NDK, Rust-target, signing, or ADB blockers rather than installing system packages. A build success does not establish correct runtime dismissal; unavailable device checks must remain explicitly unverified.

### 5. Record implementation and release metadata

- During implementation, write `4-implemented.md` in this task directory with changed modal families, reproduced failure, commands/results, device versions, tested flows, and any open verification limits.
- Follow the existing patch-release convention: bump app version from `0.15.10` to `0.15.11` consistently in `app/package.json`, `app/package-lock.json`, `app/src-tauri/Cargo.toml`, `app/src-tauri/Cargo.lock`, and `app/src-tauri/tauri.conf.json`, without dependency upgrades. Confirm the current version before applying the bump if another release intervenes.
- Commit the app implementation in its task branch, then commit the parent submodule pointer and implementation report through the existing workflow.

## Acceptance Criteria

- Every app modal family participates in the same dialog event-ownership rule. One user dismissal closes only the topmost interactive modal, whether dialogs are nested or siblings in a native modal stack.
- Underlying modals remain open and usable, with their selections and pending input preserved. A separate action dismisses each remaining layer, and children can reopen repeatedly.
- Backdrop, Cancel/Done, and native cancel handling where supported do not propagate dismissal into ancestors. Clicking content does not dismiss a parent.
- Select choices, Sort live updates, label creation/removal handoffs, Settings actions, task saves, conflict resolution, and link confirmation retain existing behavior. Cancellation does not trigger unintended writes, browser opens, or duplicate semantic callbacks.
- All ten dialog components are inspected and covered by meaningful lifecycle tests. Actual parent-child and sibling flows include both self-owned and externally controlled state.
- Full frontend tests, TypeScript/Vite build, diff checks, Android build results, and Android/desktop runtime evidence are recorded. Missing platform verification is explicitly marked unverified.
- Implementation report and synchronized patch version are recorded and committed according to the project workflow.

## Risks And Decisions

- React event propagation is a code-supported hypothesis for the Android report, not a reproduced device diagnosis. If isolation fixes tests but Android still dismisses multiple layers, trace the remaining native gesture/event path before declaring success.
- All modals are in scope, but cancellation semantics differ. Do not normalize note keep-mine, server no-write dismissal, settings state ownership, or confirmation actions into one generic callback policy.
- Native close events may arrive after React state changes; replacement dialogs and conflict queues are particularly sensitive to stale callbacks. Regression coverage must distinguish user dismissal from programmatic completion and must not rely only on synchronous jsdom close events.
- Android Back can dismiss a keyboard or be handled outside the DOM. Apply one-layer semantics when it reaches dialog cancellation; do not add native navigation interception without evidence that the existing path requires it.
- Native dialog inertness and top-layer ordering provide stack interaction for sibling overlays. Start with owned lifecycle events and native modal behavior; add explicit stack coordination only if an observed failing supported flow requires it.
- This planning stage changes documentation only. Device prerequisites and runtime access must be checked during implementation; earlier Android environment failures are not proof of current availability.
