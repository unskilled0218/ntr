# plan

## scope

Fix Priority/Project Cancel actions and the Project > `+ Add project...` transition in the shared frontend picker path. Cancel must close the picker once and keep it closed; project creation must become the visible, interactive topmost modal after the picker closes. Preserve underlying form/Options/Edit state and the existing project staging flow.

Primary production files are `usePickerDialog.ts`, `SelectField.tsx`, and `PickerList.tsx`; update shared hook consumers `OptionsModal.tsx` and `SortField.tsx` for consistent explicit dismissal. Inspect AddForm/EditTaskModal/LabelModal handoffs without changing their persistence or submission contracts. No backend, Rust behavior, or task model change is needed.

## Implementation Plan

### 1. Reproduce the actual activation and handoff sequence

- Trace Priority/Project Cancel and `+ Add project...` in compact/noncompact AddForm and Edit task. Record click targets, default prevention, trigger activations, React open state, native `dialog.open`, close events, and `showModal()` ordering. On an available browser/device, use actual pointer clicks/taps rather than only synthetic lifecycle events.
- Check two related hypotheses: native close currently happens in a passive effect after the selection callback; and removing clicked controls from a dialog nested inside a label may let the click's default label activation reactivate its trigger. A reactivated Project picker can be placed above the newly opened LabelModal. These are code-supported paths to investigate, not a reproduced device diagnosis.
- Existing tests batch clicks through Testing Library and approximate native dialogs with `open` flags. They can miss default activation after React removes a clicked button and cannot establish browser top-layer ordering. Add a failing regression for the concrete sequence found, rather than repeating only the already-passing standalone Cancel test.
- Independently add a handoff regression that observes native picker visibility when `onChange`/`onRemove` starts: the picker must already be closed, before a caller can open a replacement modal. This specifies the required boundary even when full device reproduction is unavailable.

### 2. Close native pickers explicitly before handing control to callers

- Add an explicit `closePicker()` operation to `usePickerDialog`. It must close the currently open native dialog synchronously and set React open state to false before returning. Guard missing/already-closed refs, and keep owned close/cancel event handling and the reopened-dialog stale-close check.
- Keep opening state-driven so dialog contents mount before `showModal()` and native focus initialization. Retain the effect as visibility reconciliation; do not rely on that effect as the ordering mechanism for explicit dismissal.
- Use `closePicker()` for SelectField Cancel, selection, and removal. Invoke `onChange(value)` or `onRemove(value)` only after it returns, so LabelSelect's sentinel callback cannot start project creation while the old native picker is still open.
- Route the hook's backdrop dismissal through the same operation, preserving `useBackdropClose` target isolation/default prevention. Update Options and Sort Done buttons to use it; Sort choices still apply live and do not close Sort.
- Keep native cancel behavior separate from pointer/button activation. Preserve `ownDialogEvent` isolation and browser cancellation followed by owned close synchronization; do not prevent native cancellation merely to suppress a click default.
- Cancel must not call selection/removal callbacks. Ordinary choices and the add-project sentinel still invoke their intended callback once. Closing a child must not dismiss Options or Edit task.

### 3. Prevent dismissal clicks from reactivating enclosing labels

- Prevent the closing button's default click behavior before changing state or native visibility: SelectField Cancel and shared picker Done actions should call `event.preventDefault()` before `closePicker()`.
- In `PickerList`, prevent default on choice/removal button clicks before invoking the existing value callbacks. Keep their public signatures and `type="button"`; callers still receive only the value. This absorbs label activation at the actual clicked control without introducing event plumbing through domain callbacks.
- Apply prevention narrowly to those action clicks. Preserve explicit trigger activation, normal focus/keyboard activation, form submission, label input behavior, Sort live selection, and native close/cancel ownership. `stopPropagation()` alone does not cancel label default activation.
- Verify that default prevention and synchronous close resolve the traced sequence in the actual label-wrapped layouts. If a different native path remains, capture its event sequence and add a regression before widening the fix. Do not add arbitrary delays, force React rendering with `flushSync`, raise z-index values, or reopen LabelModal repeatedly to hide an ordering error.
- Preserve AddForm's LabelModal placement outside its task form and EditTaskModal's existing label owner. Label Cancel retains previous selections; label confirmation stages/selects the new name without calling task Add/Save.

### 4. Add regressions and verify the shared consumers

- Extend SelectField tests with callback-entry native visibility, label-wrapped Priority/Project Cancel, repeated reopen cycles, and selection/removal actions. Assert native closure, preserved values, and callback counts rather than only a call to `close()` or `preventDefault()`.
- For default activation regressions, model the browser's relevant discrete update/default-action sequence explicitly or reproduce it in a real browser. If a test dispatches a cancelable click and conditionally models enclosing-label activation, document that approximation and require the failure on the old code. A prevented event alone does not prove native Cancel works.
- Extend AddForm tests across compact and noncompact layouts and EditTaskModal tests with pending description/due/priority/project values. Require one-click picker Cancel, then project-creation handoff, cancel/reopen, and valid creation/selection, with no unintended task submission or edit save.
- During handoff, require the Project picker to be natively closed before the replacement opens. With a real browser, also verify `:modal` state, hit testing/interactivity, and focus on the new-name input; checking that both elements have `open` attributes is insufficient.
- Reuse controlled deferred-close support to deliver an old picker close after LabelModal opens and after the picker explicitly reopens. It must not close the replacement, clear pending values, or reopen a previously dismissed picker. Restore mocks and flush pending events during cleanup.
- Retain regressions for Options/Sort, Settings pickers, and sibling removal confirmation because they share the hook or PickerList. Verify selection remains live for Sort and one-layer backdrop/native cancellation still works.
- From `app`, run `npm test -- src/components/SelectField.test.tsx src/components/PickerList.test.tsx src/components/AddForm.test.tsx src/components/EditTaskModal.test.tsx src/components/OptionsModal.test.tsx src/components/SortField.test.tsx src/components/SettingsModal.test.tsx src/components/ModalLifecycle.test.tsx`, adding any new regression files.
- Run `npm test`, `npm run build`, and `git diff --check` in the app; check the parent task/app diff as well.
- On an available browser/device, test mouse and touch Cancel, keyboard activation, project handoff, creation/cancellation, and repeated cycles in each supported parent layout. Check preserved input, topmost interactivity, focus return, and backdrop/native cancel. Include Android if it is the reported affected platform, recording Android/System WebView and desktop browser versions.
- If native runtime access is unavailable, explicitly record which pointer, top-layer, focus, and device acceptance criteria remain unverified. No system packages are installed automatically; a passing jsdom suite or build is not proof that this runtime report is resolved.

### 5. Record implementation and release metadata

- During implementation, write `4-implemented.md` in this task directory with traced/reproduced failures, changed files, commands/results, browser/device evidence, and unavailable verification.
- Follow the current patch-release convention: bump `0.15.12` to `0.15.13` consistently in `app/package.json`, `app/package-lock.json`, `app/src-tauri/Cargo.toml`, `app/src-tauri/Cargo.lock`, and `app/src-tauri/tauri.conf.json`, without dependency upgrades. Recheck the current version if another release intervenes.
- Commit the app implementation in its task branch, then commit the parent submodule pointer and report through the existing workflow.

## Acceptance Criteria

- One Cancel click/tap closes Priority/Project and leaves it closed until its trigger is explicitly activated. Values and underlying form/modal state remain intact.
- SelectField callbacks run only after native picker closure. `+ Add project...` presents a visible, focused, interactive creation modal above any surviving Options/Edit parent, with no picker reopened above it.
- AddForm compact/noncompact and Edit task support repeated Cancel/reopen and create/cancel/reopen cycles. Cancelling creation preserves the prior selection; confirming a valid name preserves existing staging/selection without task Add/Save side effects.
- Explicit choices, removal handoffs, Options/Sort Done, Sort live selections, Settings pickers, and one-layer backdrop/native cancellation retain their contracts.
- Deferred old close events do not dismiss replacement dialogs or corrupt reopened picker state. Regressions cover native-closure ordering and the actual activation sequence responsible for the report.
- Focused/full frontend tests, TypeScript/Vite build, and diff checks pass. Runtime/platform evidence and unverified native criteria are recorded separately in the implementation report.
- Release metadata agrees on the new patch version and implementation/report commits follow the repository workflow.

## Risks And Decisions

- Default label activation, React discrete updates, and native top-layer ordering are distinct from close-event bubbling. Preserve the existing ownership fix; it is necessary but may not address these click/handoff failures.
- `dialog.close()` removes native modal state synchronously, while its close event can be deferred. Handoff must depend on native closure, not waiting for that event or an arbitrary timeout.
- Opening still requires mounted content for correct initial focus. Avoid making both open and close blindly synchronous before React renders child controls.
- Existing test shims and controlled deferred events provide partial lifecycle evidence. Actual device/browser interactivity must remain unverified if it cannot be exercised.
- Shared hook/list changes affect more than the two reported pickers. Keep changes localized and verify their existing consumers instead of adding per-screen fixes or a new modal manager.
- This planning stage changes documentation only. Implementation and runtime diagnosis happen in the implementation stage.
