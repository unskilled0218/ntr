# implemented

## changes

- Created fresh `10-picker-cancel-project-handoff` branches in the parent repository and app submodule.
- Added `closePicker()` to `usePickerDialog`: it closes an open native dialog immediately and requests React closed state before returning. Opening remains state/effect-driven so contents mount before native focus initialization. Backdrop dismissal uses the same close operation.
- SelectField Cancel, selection, and removal now use explicit closure. Value callbacks run after native closure, so project creation/removal replacement callbacks cannot begin while the old picker is still open.
- SelectField Cancel and Options/Sort Done prevent their click defaults before closing. PickerList choice/removal buttons prevent default before their existing value callbacks, preventing the modeled enclosing-label reactivation path without changing public callback signatures.
- Preserved owned close/cancel handling, native cancel defaults, stale-close handling for reopened dialogs, Sort live selections, and existing AddForm/EditTaskModal/LabelModal staging and submission behavior.
- Added regression coverage in SelectField, AddForm, and EditTaskModal suites, with shared test support for controlled removed-target label activation and observation of picker visibility when LabelModal opens. Added form coverage for compact/noncompact AddForm and Edit task, repeated Cancel/reopen cycles, deferred old close delivery, input preservation, creation/cancellation, and no unintended Add/Save.
- Bumped patch version from `0.15.12` to `0.15.13` in npm metadata/lockfile, Cargo metadata/lockfile, and Tauri configuration. Lockfile changes update only the app version.

## diagnosis and verification

- Before production changes, `npm test -- src/components/SelectField.test.tsx` passed ten existing cases and failed four new regressions. Choice/removal callbacks observed the dialog's `open` property as `true` at entry. Two modeled label-activation cases reopened Priority/Project after Cancel. These tests use jsdom dialog support and do not reproduce the user's actual device gestures.
- The modeled click helper dispatches a cancelable click, lets React updates settle, and then activates the captured enclosing label only if the clicked control was removed and the click was not prevented. This intentionally approximates the suspected browser timing path; it is not proof that a native browser/device follows that sequence. No production `flushSync`, delays, z-index changes, or repeated replacement opening were added.
- Patched choice/removal callback-entry regressions observe `open === false`. In all three form layouts, LabelModal opening observations record closed pickers, and delayed old picker events leave the replacement open. Creation input receives explicit focus in jsdom and accepts text; cancellation retains the previous project and confirmation selects the staged name.
- `npm test -- src/components/SelectField.test.tsx src/components/PickerList.test.tsx src/components/AddForm.test.tsx src/components/EditTaskModal.test.tsx src/components/OptionsModal.test.tsx src/components/SortField.test.tsx src/components/SettingsModal.test.tsx src/components/ModalLifecycle.test.tsx` in `app`: passed, 102 tests across eight files.
- `npm test` in `app`: passed, 360 tests across 29 files, including the existing Options/Sort/Settings and sibling-removal regressions. API error-path fixtures emitted their expected disk-full/reconciliation diagnostics; all tests passed.
- `npm run build` in `app`: passed TypeScript and Vite production build.
- `git diff --check` in the app and for parent app/task changes: passed.
- Release metadata agrees on `0.15.13`.

## native runtime limits

- No X11/Wayland display was configured, and no Chromium/Chrome/Firefox, Xvfb, or WebKitWebDriver executable was available on PATH.
- Retried the temporary `/tmp/opencode/modal-webkit-check` native probe under Broadway display `:42`, using installed WebKitGTK `2.52.6` / GTK `3.24.52`. Even with probe-local sandbox environment overrides, GTK aborted before page execution because its SVG icon loader's `bwrap` process failed. No app scenario or native pointer/keyboard interaction ran.
- `adb devices -l` failed because the remote daemon at `tcp:host.docker.internal:5037` refused the connection. Android/System WebView versions and the affected device/browser remain unknown.
- Actual pointer/touch Cancel behavior, keyboard activation, native `:modal`/hit testing, focus trapping/return, and top-layer replacement ordering remain unverified. Native label reactivation remains a hypothesis; the implementation establishes the tested callback-closure contract and guards the modeled activation path, but successful resolution of the reported device symptom still requires runtime checks.
- To finish runtime acceptance, provide a reachable device/emulator or working desktop browser/display environment. No system packages or host configuration were changed.

## release and commits

- Version: `0.15.13`.
- App commit: `a092b39` — `Close pickers before modal handoff and prevent label reactivation`.
- App implementation is committed in the submodule. The parent commit records its pointer and this report.
