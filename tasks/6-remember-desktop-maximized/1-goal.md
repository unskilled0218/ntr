# goal

## command

- remember desktop full window status also

## goal

Remember the desktop main window's maximized state across normal app restarts, alongside the existing fullscreen persistence. Interpret "full window" as the native maximized window state selected through the desktop window controls.

When the user closes the app while maximized, the next launch should restore a maximized window automatically. When the user restores the window to its normal size before closing, the next launch should open at its saved normal size and position.

Use the existing native window-state persistence mechanism and preserve its saved normal bounds. Maximized and fullscreen remain separate states, and the existing fullscreen restart behavior must continue to work.

## project findings

- `app/src-tauri/src/lib.rs` enables `StateFlags::POSITION | StateFlags::SIZE | StateFlags::FULLSCREEN`, but does not enable `StateFlags::MAXIMIZED`.
- The locally patched `tauri-plugin-window-state` version `2.4.0` already exposes `MAXIMIZED`, captures `is_maximized()`, and restores a saved maximized state with `maximize()`.
- `app/src-tauri/vendor/tauri-plugin-window-state/src/lib.rs` contains the fullscreen geometry safeguards and deferred fullscreen restoration added by the preceding task. Maximized persistence needs to work with that restoration sequence.
- `app/src-tauri/tauri.conf.json` defines the normal main window at 800 × 600 and does not force maximized startup.

## acceptance criteria

- Maximize the desktop window, close the app normally, and relaunch: the main window opens maximized.
- Restore the window to normal size, close the app normally, and relaunch: the main window opens windowed at its saved size and position.
- After closing and relaunching while maximized, restoring to normal size recovers usable pre-maximized bounds rather than monitor-sized bounds.
- Repeated maximized/windowed restarts reflect the most recently saved state.
- Existing fullscreen close/relaunch behavior and normal geometry preservation continue to work, including transitions between maximized and fullscreen modes.
- Fresh configurations and existing window-state files launch successfully without forcing every window to be maximized.
- The behavior works in both local and server modes, with state persisted on the desktop client.
- Relevant native checks pass, and real desktop maximize/close/relaunch verification results are recorded for available platforms.
