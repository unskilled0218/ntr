# plan

## scope

Implement `1-goal.md` by remembering the desktop main window's native maximized state alongside fullscreen, normal size, and normal position. Closing maximized must reopen maximized; restoring to normal before closing must reopen at the saved normal bounds.

Implementation belongs in the `app` submodule. Keep this plan beside the current task's goal, and use the existing locally patched window-state plugin as the persistence owner.

## Implementation Plan

### 1. Enable native maximized-state persistence

- In `app/src-tauri/src/lib.rs`, extend the desktop state flags to `StateFlags::POSITION | StateFlags::SIZE | StateFlags::MAXIMIZED | StateFlags::FULLSCREEN`. Update the nearby comment to mention maximized and fullscreen restoration.
- Keep desktop conditional compilation, the pinned plugin version `2.4.0`, and the existing local Cargo override intact.
- Keep the configured default window normal at 800 × 600. Do not force maximization in `tauri.conf.json`; the saved state must determine each launch.
- Reuse the plugin's close-request capture and exit-time save to `.window-state.json`. No frontend preference, new state file, or new window-control UI is required.

### 2. Coordinate restoration with the existing fullscreen correction

- Inspect and exercise `restore_state` in `app/src-tauri/vendor/tauri-plugin-window-state/src/lib.rs` after enabling the flag. It currently requests normal size, immediately calls `maximize()`, and then may wait for a resize to the normal size before restoring fullscreen. Once maximized, that awaited normal-size event may never occur.
- Extend the existing deferred restoration inside this plugin when native checks reproduce ordering or normal-bounds failures. Apply normal position/size first, confirm the saved physical size when native sizing is asynchronous, then apply the requested maximized state. If fullscreen is also requested, enter fullscreen after maximization is confirmed rather than waiting for normal size after maximization.
- Use one per-window, nonserialized pending transition for the requested modes and restore phase. Reuse the existing cached state and native event handlers; avoid accumulating competing restore callbacks for separate modes.
- Keep immediate restoration when normal geometry is already applied. After each native request, advance immediately if the queried state already matches; otherwise advance on native resize/state observations. Clear pending state on successful completion or a failed native request, and leave a usable window on failure.
- Ensure pending restoration cannot wait indefinitely for an impossible exact-size event after monitor changes or window-manager size constraints. Use a named two-second restoration deadline, with a native main-thread timeout callback that applies the requested modes to usable current bounds, retains saved normal bounds, and clears the pending transition. Identify each pending attempt so an expired callback from a completed/closed window or older attempt cannot alter a newer restore. Store transient deadline/phase information only in memory, never in the JSON document, and record fallback outcomes during verification.
- Preserve normal geometry throughout pending/maximized/fullscreen transitions. Keep close/exit snapshots and resize events from replacing normal width/height with maximized monitor bounds. In the move handler, query maximized state instead of passing a constant false to `can_capture_geometry`, so maximized moves cannot corrupt normal position.
- Keep normal position and its existing `prev_x`/`prev_y` representation consistent when capturing normal geometry or initializing a normal window. Preserve compatibility with existing saved maximized entries whose normal position is held in the previous-position fields. Test the first maximize after fresh startup as well as a window that has already been moved/resized.
- Capture maximized true/false while the window is outside fullscreen, including native transitions, so the cache reflects the mode selected before entering fullscreen. Preserve that underlying maximized mode while fullscreen if the platform reports maximized false there; exiting fullscreen should return to the prior maximized or normal mode. Do not interpret fullscreen bounds as evidence of maximization.
- Keep the persisted boolean/geometry schema compatible. Update `PATCH.md` if the local plugin correction grows, documenting the concrete reproduction and mode/geometry invariants without changing unrelated plugin behavior.

### 3. Verify real maximize/close/relaunch behavior

- Use a real available desktop session and `npm run tauri dev -- --no-watch` from `app`. On X11, check `xprop -root _NET_SUPPORTING_WM_CHECK` first and record the window manager. Use native window controls or a temporary native harness for maximize/unmaximize; verify native state rather than inferring it from dimensions.
- Use disposable config, data, and cache roots, such as separate `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, and `XDG_CACHE_HOME` on Linux. Use a disposable server with fixture `TODO_FILE`, `NOTE_FILE`, and `LABELS_FILE` paths. Reuse the same fixture roots across a restart sequence and fresh roots for first-launch cases.
- Set a recognizable normal size/position, maximize, wait for the native transition, close normally, and relaunch. Verify native maximized state and the saved `main.maximized: true` value.
- Unmaximize the restored window and verify its pre-maximized normal size/position. Close and relaunch again; verify `main.maximized: false` and restored normal geometry. Repeat the complete maximized/normal cycle at least twice.
- Check first-launch maximization before any manual normal resize/move. Its subsequent unmaximize must recover usable default normal bounds and position.
- Repeat fullscreen-only close/relaunch and exit-fullscreen tests from the current app behavior. Verify preserved normal geometry and saved fullscreen true/false values.
- Exercise maximize → fullscreen → close → relaunch → exit fullscreen → unmaximize, and normal → fullscreen → close → relaunch → exit fullscreen. Check both saved mode booleans and the underlying mode on fullscreen exit. Also exercise fullscreen exit followed by explicit unmaximize before closing, proving stale mode flags do not force maximized startup.
- Run the lifecycle cases in local mode and with the disposable server connected. Keep server reconciliation and app data confined to the fixture roots.
- Verify a fresh configuration with no state file and existing valid entries with `maximized: false` and `maximized: true`. Confirm the prior task's legacy-load fallback remains successful when required fields are absent; this task does not add a schema migration.
- Remove temporary native harness hooks before final build/tests. Record OS/window manager, toggle and close methods, saved flags, normal bounds, ordering failures/corrections, fallback behavior, and unavailable platform checks in `4-implemented.md`.

### 4. Add focused regression coverage and run checks

- If deferred restoration or mode capture changes, add plugin tests for normal/maximized/fullscreen/combined requested modes, pending-phase progression, native request failure, and the bounded fallback. Assert observed actions and retained metadata rather than duplicating the flag expression.
- Extend geometry tests to cover maximized move/resize samples, normal capture after unmaximize, and first-startup previous-position initialization. Extend serialization coverage to prove pending modes/phases/deadlines are absent from saved JSON and default correctly on load.
- From `app/src-tauri`, run `cargo test --locked`, `cargo test --locked -p tauri-plugin-window-state`, and `cargo build --locked`. The package-selected plugin test command uses the app's exact dependency versions and avoids resolving a separate dependency graph.
- Run `cargo fmt --check` and `cargo fmt --manifest-path vendor/tauri-plugin-window-state/Cargo.toml --check`. The preceding task recorded baseline formatting mismatches in `build.rs`, `src/main.rs`, and `src/http.rs`; report remaining baseline failures separately and require changed files to pass targeted formatting checks, including `rustfmt --check --config-path rustfmt.toml --config skip_children=true src/lib.rs`.
- Validate the local plugin selection with locked Cargo metadata filtered for the installed desktop target. Review the diff for preserved desktop/mobile dependency guards; run mobile builds only if the targets/toolchain are available and record their status.
- Extend the desktop window-state feature note in `app/README.md` once runtime behavior is verified.
- During implementation, bump the app patch version from `0.15.8` to `0.15.9` in `app/package.json`, `app/package-lock.json`, `app/src-tauri/Cargo.toml`, `app/src-tauri/Cargo.lock`, and `app/src-tauri/tauri.conf.json`, following the existing release convention. Verify all app version values agree and avoid unrelated dependency upgrades.
- Write `4-implemented.md`, commit app implementation in the submodule, and commit its updated pointer plus task results in the parent repository through the implementation workflow.

## Acceptance Criteria

- Closing maximized reopens maximized; closing after unmaximize reopens normal with the latest saved normal geometry.
- Unmaximizing after a maximized restart recovers usable pre-maximized bounds, including the first maximize from fresh startup.
- Repeated restarts preserve the latest mode rather than retaining stale maximized true/false values.
- Fullscreen restoration remains functional, including maximized/fullscreen combinations and the correct underlying mode when leaving fullscreen.
- Maximized/fullscreen geometry samples and pending transitions do not overwrite saved normal bounds. Failed or constrained restoration leaves a usable window and no permanently pending transition.
- Fresh and existing state files launch successfully; native behavior works in both local and server modes.
- App/plugin tests and native build pass, changed files pass formatting checks, version metadata agrees, and native runtime results or explicit verification blockers are recorded.

## Risks And Decisions

- "Full window" means maximized, distinct from native fullscreen. Persist both booleans and normal geometry through the existing plugin.
- The previous fullscreen task demonstrated asynchronous GTK sizing. Enabling MAXIMIZED must not reintroduce that default-size failure or prevent the fullscreen size gate from completing.
- Some platforms report maximized state differently while fullscreen. The saved underlying mode must come from an observed non-fullscreen state, not a fullscreen geometry guess.
- The plugin's previous-position fields are part of the existing state format. Changing geometry capture requires maintaining their meaning for saved maximized entries.
- Native lifecycle tests establish the behavior; unit tests and successful compilation alone do not prove maximized/fullscreen restoration. Record unsupported or unavailable platform checks explicitly.
- This task retains the existing desktop-native persistence owner and normal close/exit contract. No maximized preference is sent to the optional server.
