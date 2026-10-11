# implemented

## changes

- Created new `8-android-modal-dismissal` branches in the parent repository and app submodule.
- Added typed `dialogEvents.ts` helpers that accept only the receiving dialog's own lifecycle events and stop React ancestor propagation. Queued close events do not dismiss a currently reopened native dialog.
- Applied owned close/cancel handling across all ten modal components: Options, Select, Sort, Settings, Edit task, Label, Remove label, server/local conflict, note conflict, and Open link. Settings/Edit keep their existing state-driven cancellation; other native cancel paths retain the browser's default close behavior.
- Shared picker close handling synchronizes only that picker's state. External close callbacks run only for a still-active presentation whose native dialog has closed, avoiding cancellation callbacks after prop-driven completion.
- Conflict dialog visibility now follows the active conflict rather than its boolean presence, so dismissing one queued prompt reopens the next. A per-entry handled reference prevents a pending choice/dismissal from being applied twice. No App queue change was needed.
- Backdrop handling preserves native target isolation and prevents label activation from re-triggering a picker after dismissal. Updated its explanation of React lifecycle propagation.
- Preserved modal-specific actions: Sort selections remain live; label creation/removal handoffs keep the surviving Options/Edit modal; confirmation does not invoke cancellation after programmatic closure; note dismissal retains the existing keep-mine owner path.
- Added nested, standalone, sibling-overlay, queue, input-preservation, reopening, and deferred-close tests. Updated the shared jsdom close shim to ignore already-closed dialogs and removed conflicting local shims from ConflictDialog and NotePane tests. Native cancel test support dispatches a non-bubbling, cancelable event and applies the close default only when not prevented.
- Bumped app patch version from `0.15.10` to `0.15.11` consistently in npm metadata/lockfile, Cargo metadata/lockfile, and Tauri configuration. No dependency upgrades.

## reproduced failures and regression coverage

- Before production changes, `npm test -- src/components/OptionsModal.test.tsx` failed all four new child-dismissal cases: Cancel, backdrop, native cancel, and project selection each closed the parent Options modal. The existing three tests passed.
- After initial event isolation, a stateful Settings test exposed a second failure: backdrop dismissal could leave picker visibility and state inconsistent, preventing reopening. Preventing the backdrop click's default label activation fixed that regression.
- Real component combinations cover Options > Select/Sort; Settings > picker with typed Server URL preserved; Edit task > Priority/Project/Label with description, due date, and project preserved; compact AddForm's sibling label handoff with unfinished task input preserved; and FilterBar's sibling removal confirmation with Options and the project retained.
- Standalone coverage spans all ten dialog families. Cancellation updates the relevant owner without confirmation side effects, while successful label/removal/note/link confirmation does not subsequently invoke cancellation.
- Stateful two-conflict tests cover backdrop, native cancel, and a version choice, require the next prompt to remain visible with its own content, and then require a separate dismissal. Further cases cover queued old close delivery, final completion, and cancellation while a chosen entry awaits its owner.
- Controlled deferred-close tests cover reopened pickers, replacement conflicts, reopened externally controlled dialogs, and picker-to-label/removal handoffs. A sibling link overlay can close without closing underlying Options. These verify React/native state handling in jsdom, not real browser hit testing or inertness.

## checks

- Focused command from `2-plan.md`, extended with `src/components/ModalLifecycle.test.tsx` and `src/components/AddForm.test.tsx`: the first expanded run found the Settings backdrop/reopen regression. After the fix, the affected Settings, Edit task, lifecycle, and AddForm suites passed all 56 tests.
- `npm test` in `app`: passed, 343 tests across 29 files, including all focused suites and the existing note/task/API regressions. Existing API sad-path tests emit expected disk-full/reconciliation diagnostics; all tests passed.
- `npm run build` in `app`: passed TypeScript and Vite production build. An initial build identified two new test typing mistakes (`this` annotation and an unsupported Testing Library option); both were corrected before the passing build.
- `npm run tauri android build`: passed with installed NDK `29.0.13846066`, compiling aarch64, armv7, i686, and x86_64 Android release libraries and packaging the universal APK/AAB. The first invocation exceeded the tool's 120-second timeout; the retry with a longer timeout completed successfully. Gradle reported existing deprecated features for its future 9.0 compatibility.
- APK: `app/src-tauri/gen/android/app/build/outputs/apk/universal/release/app-universal-release.apk`.
- AAB: `app/src-tauri/gen/android/app/build/outputs/bundle/universalRelease/app-universal-release.aab`.
- `git diff --check` in the app and for the parent task/app changes: passed. Generated build outputs are not part of the implementation commit.

## native runtime limits

- `adb devices -l` failed because the configured remote daemon at `tcp:host.docker.internal:5037` refused the connection. Android device/emulator tests were unavailable, so Android and Android System WebView versions are unknown. Back handling, actual touch/backdrop behavior, all-modal device cycles, and Android focus/top-layer behavior remain unverified.
- No X11/Wayland display or installed Chromium/Firefox browser was available. The installed WebKitGTK MiniBrowser failed with `cannot open display`.
- Attempted a temporary native WebKitGTK `2.52.6` / GTK `3.24.52` harness under the installed Broadway backend, entirely under `/tmp/opencode`. GTK aborted before page execution because its SVG icon loader's `bwrap` sandbox process failed. No native desktop modal scenario succeeded; native Escape, focus return, inertness, sibling top-layer ordering, and deferred browser-event behavior remain unverified.
- The Android build establishes compilation/packaging, while jsdom tests establish the covered event and state outcomes. Neither establishes real Android gesture behavior. To finish runtime acceptance, provide a reachable ADB device/emulator and a working desktop display/browser or GTK sandbox environment. No system packages or host configuration were changed.

## release and commits

- Version: `0.15.11`.
- App commit: `b03a4c0` — `Isolate modal dismissal and preserve queued presentations`.
- App implementation is committed in the submodule. The parent commit records its pointer and this report.
