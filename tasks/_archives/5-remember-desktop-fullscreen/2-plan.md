# plan

## scope

Implement `1-goal.md` by persisting the desktop main window's native fullscreen state through the existing Tauri window-state plugin. Closing in fullscreen must restore fullscreen on the next launch; exiting fullscreen before closing must restore windowed mode.

Keep this plan beside the current task's goal. Implementation belongs in the `app` submodule, with task records and the updated app pointer committed in the parent repository.

## Implementation Plan

### 1. Enable fullscreen in the existing desktop persistence policy

- In `app/src-tauri/src/lib.rs`, extend the existing `.with_state_flags(...)` expression to `StateFlags::POSITION | StateFlags::SIZE | StateFlags::FULLSCREEN`.
- Keep the plugin registration and `StateFlags` import under `#[cfg(desktop)]`. Retain the desktop-only dependency on `tauri-plugin-window-state = "=2.4.0"` in `app/src-tauri/Cargo.toml`.
- Use the plugin's existing window-ready restoration, close-request state capture, and exit-time disk save. Do not add a second save/restore listener or frontend preference for the same state.
- Add a concise comment explaining that the selected flags persist desktop geometry and fullscreen across normal restarts.
- Keep the main window's configured default windowed, using the existing 800 × 600 size. A static `fullscreen: true` setting would ignore the user's latest state.
- Native plugin registration performs these operations without frontend IPC, so no new window commands or capability permissions are needed.

### 2. Verify real desktop close/relaunch behavior

- First confirm that a real desktop session and a way to enter/exit native fullscreen are available. On X11, inspect the window manager with `xprop -root _NET_SUPPORTING_WM_CHECK`; a `DISPLAY` value alone does not prove access to a functioning window manager. Record the native toggle or test harness used, and report missing tools/session access if blocked.
- Use `npm run tauri dev` from `app` in that desktop session. Exercise native fullscreen through the window manager or an available native test harness, rather than treating a maximized window as fullscreen.
- Create a disposable fixture root outside the repository. On Linux, set separate `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, and `XDG_CACHE_HOME` beneath that root for every launch in the sequence. Confirm the resolved app configuration/data locations and a fresh webview preference store; use equivalent isolation on other platforms. The plugin saves `.window-state.json` under the Tauri app configuration directory for `com.my.ntr`, while selected task-data configuration and default task files live under the app data directory.
- Use a disposable optional server with `TODO_FILE`, `NOTE_FILE`, and `LABELS_FILE` set to fixture paths. Start with known fixture contents and fresh connection/conflict preferences so server reconciliation cannot read or write unrelated data. Preserve the same fixture roots across each close/relaunch sequence; use a separate fresh fixture for first-launch checks.
- Start windowed, set a recognizable non-default position and size, and close normally. Relaunch and verify the existing geometry restoration still works.
- Enter fullscreen, wait for the native transition to finish, close the app normally, and relaunch. Verify the native fullscreen state and the saved main-window entry's `fullscreen: true` value.
- Exit the restored fullscreen mode and verify the window returns to usable windowed bounds, including its pre-fullscreen size and position. Close and relaunch again; verify `fullscreen: false` and restored windowed geometry.
- Repeat fullscreen → close → relaunch → windowed → close → relaunch at least twice so stale true/false values cannot pass as persistence.
- Run the lifecycle sequence in local mode and with a configured optional server. Fullscreen state must depend on the desktop window, not the selected transport or server availability.
- Check a fresh configuration with no state file and a legacy test state document whose main-window entry lacks `fullscreen`. Both must launch successfully in windowed mode. Use disposable fixtures rather than modifying the user's saved state.
- Record the desktop OS/window manager, close method, observed native state, saved state values, geometry results, and any unavailable checks in `4-implemented.md`.

### 3. Check plugin geometry behavior before declaring completion

- The installed plugin's `update_state` and resize/move handlers exclude maximized/minimized windows from some geometry capture, but do not explicitly exclude fullscreen windows. Check whether the tested platform overwrites saved windowed geometry with fullscreen monitor bounds.
- Treat the goal's windowed-geometry preservation criterion as a verification requirement, not an assumption established by the flags change. If it fails, document the exact transition and saved values, and resolve the native/plugin geometry policy within this task before claiming full acceptance.
- If a native reproduction shows lost windowed bounds, apply a narrow local correction to the pinned plugin instead of adding another persistence owner. Vendor the required published `tauri-plugin-window-state` version `2.4.0` crate files under `app/src-tauri/vendor/tauri-plugin-window-state`, retaining upstream licensing and documenting the upstream version plus local changes. Use the published standalone manifest, not `Cargo.toml.orig` with unresolved workspace dependencies; do not modify the Cargo registry cache.
- Add a `[patch.crates-io]` override in `app/src-tauri/Cargo.toml` pointing `tauri-plugin-window-state` to `vendor/tauri-plugin-window-state`, while retaining its desktop-only dependency declaration. Update the app Cargo lockfile for the local source and verify with `cargo metadata` that the override is selected. This dependency correction is conditional on reproducing the geometry failure; retain the small upstream flags-only solution if native checks pass.
- In the local plugin correction, query native fullscreen state and suppress geometry capture in `WindowExtInternal::update_state`, `WindowEvent::Moved`, and `WindowEvent::Resized` while fullscreen. Continue capturing the fullscreen boolean on close/exit, preserve the last normal bounds, and retain the existing maximized/minimized safeguards and restoration lock. Failed native-state queries must not authorize overwriting cached normal bounds.
- Cover the local geometry-capture policy with focused tests for normal/fullscreen/maximized/minimized states, then repeat enter/exit and restored-fullscreen sequences to check native transition event ordering. Fullscreen transition or restoration events must not replace normal bounds before the native state check settles; if that still fails, keep the geometry acceptance criterion unresolved and record the precise platform/event limitation for a targeted plan adjustment.
- Keep the plugin's existing state file, native lifecycle owner, and restore order. Do not add competing frontend restoration or an additional state file.
- Native Linux/Muffin verification reproduced a second restoration issue: GTK entered fullscreen before its asynchronous saved-size request was applied, so leaving fullscreen used the default 1600 × 1200 physical bounds despite correctly saved 720 × 480 bounds. In the local plugin, defer restored fullscreen until a native resize event confirms the saved physical size. Track that pending transition per cached window using a nonserialized field, suppress geometry capture until it completes, and preserve the existing direct path when the requested size is already applied. Add a serialization test proving the pending marker never enters the state file, and repeat the native lifecycle sequence.

### 4. Run relevant checks and record the implementation

- From `app/src-tauri`, run `cargo fmt --check` and `cargo test --locked` to verify formatting, compilation, and existing native behavior.
- If the conditional plugin correction is used, also run its policy tests explicitly with `cargo test --manifest-path vendor/tauri-plugin-window-state/Cargo.toml` from `app/src-tauri`; the app test command does not run dependency unit tests. Check formatting in the patched crate and review lockfile changes for unintended dependency upgrades.
- Review the diff to confirm mobile builds retain their existing conditional compilation boundaries. If an Android/iOS build target is available, run its existing build check and record the result; otherwise record that it was not executed.
- A flags-only change does not require a unit test that repeats the bitmask expression. Native close/relaunch checks verify the actual behavior. If a geometry correction introduces application-owned logic, add focused tests for that logic and its state transitions.
- Native tests and frontend-only tests do not prove operating-system fullscreen restoration. If the desktop session cannot be exercised, record the runtime checks as unverified rather than passed, with the steps needed to complete them.
- Add a short desktop window-state feature note to `app/README.md` once the behavior is verified.
- During implementation, follow the existing patch-release convention: update `0.15.7` to `0.15.8` consistently in `app/package.json`, `app/package-lock.json`, `app/src-tauri/Cargo.toml`, `app/src-tauri/Cargo.lock`, and `app/src-tauri/tauri.conf.json`. Validate that npm, Tauri, and Cargo versions agree.
- Write `4-implemented.md` with changes and verification results, commit app changes in its submodule, and commit the updated app pointer and task report in the parent repository through the implementation workflow.

## Acceptance Criteria

- Closing the desktop app in native fullscreen causes the next normal launch to restore fullscreen automatically.
- Exiting fullscreen before closing causes the next launch to restore windowed mode.
- Repeated fullscreen/windowed restarts restore the most recently saved state in both local and server modes.
- Existing window position and size restoration continues to work, including usable pre-fullscreen windowed bounds after leaving restored fullscreen.
- Fresh configurations and state documents without fullscreen data launch successfully in windowed mode.
- Desktop-only plugin/dependency boundaries remain valid for mobile builds.
- Native formatting/tests pass, version metadata agrees, and actual desktop runtime results or explicit verification blockers are recorded.

## Risks And Decisions

- Fullscreen and maximized are distinct native states. Enable only the requested fullscreen flag alongside the existing position/size flags, rather than enabling all plugin flags.
- The plugin already captures fullscreen on close and saves on app exit. Normal close/exit is the persistence contract; forced process termination is outside this goal.
- Plugin version `2.4.0` reads the entire state file with Serde and falls back to an empty cache on load failure. An entry missing the required `fullscreen` field may discard saved geometry, but it must not prevent startup. This task does not introduce a legacy-file migration requirement.
- Fullscreen geometry capture varies with the native window manager and needs direct verification. The flags change alone does not demonstrate correct windowed bounds after restoring fullscreen.
- A local plugin override adds maintenance cost and is justified only by a reproduced geometry failure. Keep it confined to fullscreen-aware capture guards and document the patch for eventual replacement by an upstream fix.
- Test isolation includes app data and webview preferences as well as window-state configuration, because connecting a server can reconcile task/note contents during startup.
- No frontend toggle or new fullscreen shortcut is requested. This task remembers the native fullscreen state the user selects.
