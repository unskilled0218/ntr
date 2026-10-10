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

- Use `npm run tauri dev` from `app` in an available desktop session. Exercise native fullscreen through the window manager or an available native test harness, rather than treating a maximized window as fullscreen.
- Use an isolated application configuration directory for persistence checks where the platform supports it, such as a separate `XDG_CONFIG_HOME` on Linux. The plugin saves `.window-state.json` under the Tauri app configuration directory for `com.my.ntr`, not the selected task-data directory.
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
- Keep any required geometry correction at the existing native persistence boundary. If the correction requires a dependency patch or a larger persistence redesign, record the concrete limitation and update the implementation plan before expanding the change. Do not silently add a second state file or competing frontend restoration path.

### 4. Run relevant checks and record the implementation

- From `app/src-tauri`, run `cargo fmt --check` and `cargo test --locked` to verify formatting, compilation, and existing native behavior.
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
- No frontend toggle or new fullscreen shortcut is requested. This task remembers the native fullscreen state the user selects.
