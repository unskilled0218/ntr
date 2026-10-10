# goal

## command

- remember desktop full screen status
- if user close app when full screen, next open should be full screen

## goal

Remember the desktop window's fullscreen state across app restarts. When the user closes the app in fullscreen, the next launch should restore fullscreen automatically. When the user exits fullscreen before closing, the next launch should open in windowed mode.

Use the existing desktop window-state persistence mechanism so fullscreen restoration works alongside saved window position and size. Fullscreen means the native fullscreen mode, distinct from a maximized window.

## project findings

- `app/src-tauri/src/lib.rs` registers `tauri-plugin-window-state` for desktop builds, but enables only `StateFlags::POSITION | StateFlags::SIZE`.
- `app/src-tauri/Cargo.toml` already pins `tauri-plugin-window-state` to version `2.4.0` for desktop targets.
- The installed plugin supports `StateFlags::FULLSCREEN`, reads native fullscreen state, restores it, and saves window state on close/exit.
- `app/src-tauri/tauri.conf.json` defines the main window with an 800 × 600 default size and no forced fullscreen setting.

## acceptance criteria

- Enter native fullscreen, close the desktop app normally, and relaunch: the main window opens in fullscreen.
- Exit fullscreen, close the app normally, and relaunch: the main window opens in windowed mode.
- Repeat fullscreen/windowed transitions across multiple restarts: each launch reflects the most recently saved state.
- Existing saved window position and size continue to restore, including when returning from fullscreen to windowed mode.
- A fresh installation or existing state file without fullscreen data launches successfully with the normal windowed default.
- The behavior applies in both local and server modes, with persistence kept on the desktop client.
- Relevant native checks pass, and desktop close/relaunch verification results are recorded for available platforms.
