# implemented

## changes

- Created new `5-remember-desktop-fullscreen` branches in the parent repository and `app` submodule.
- Enabled `StateFlags::FULLSCREEN` alongside the existing position/size flags in the desktop-only window-state plugin registration.
- Reproduced the planned geometry failure on Linux/Muffin, then selected a local `tauri-plugin-window-state` version `2.4.0` override under `app/src-tauri/vendor/tauri-plugin-window-state`.
- Preserved normal window bounds during fullscreen close/exit capture and move/resize events. Failed fullscreen queries cannot authorize geometry capture.
- Reproduced a separate GTK ordering issue: entering restored fullscreen before the asynchronous saved-size request completed caused fullscreen exit to use default windowed bounds. Updated `2-plan.md` with the verified issue and correction before extending the plugin patch.
- Deferred restored fullscreen until the saved physical size is applied. A per-window, nonserialized pending marker protects saved bounds during that transition; already-applied sizes keep the direct restore path.
- Kept the plugin's existing state file, native lifecycle ownership, and desktop dependency boundaries. Retained published plugin manifests, build/permission assets, and upstream licenses; documented local changes in `PATCH.md`.
- Added tests for the geometry-capture policy and nonserialized pending state. Updated the desktop window-state feature note in `app/README.md`.
- Bumped app version from `0.15.7` to `0.15.8` consistently in npm metadata/lockfile, Cargo metadata/lockfile, and Tauri configuration. The app Cargo lockfile changes only the app version and plugin source; no app dependency versions were upgraded.

## native runtime verification

- Platform: Linux X11 desktop with `Mutter (Muffin)`, confirmed through `_NET_SUPPORTING_WM_CHECK`. Native fullscreen monitor bounds were 3840 × 2160 physical pixels.
- Harness: launched the real app with `npm run tauri dev -- --no-watch`, used a temporary native socket harness to call Tauri `set_fullscreen`, and closed through the window manager's normal `_NET_CLOSE_WINDOW` request. Checked both X11 fullscreen state and the saved main-window entry. The temporary harness and all `/tmp/opencode` references were removed from app source before final checks and commits.
- Isolation: separate `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, and `XDG_CACHE_HOME` under disposable roots. The real optional server used separate fixture task/note/labels files and fresh app preferences.
- Before the patch, closing a 720 × 480 window in fullscreen saved 3840 × 2160 bounds. After adding geometry guards alone, saved bounds were correct, but leaving restored fullscreen still produced 1600 × 1200 default bounds. Deferring fullscreen until native sizing completed resolved both failures.
- Local-mode lifecycle: passed normal geometry restoration, fullscreen close/relaunch, exit-fullscreen close/relaunch, and two additional complete fullscreen/windowed restart cycles.
- Server-mode lifecycle: passed the same sequence and two additional cycles against a real disposable server. Confirmed task/note reconciliation wrote the expected fixture contents only to isolated app data.
- Final results in both modes: the saved fullscreen value alternated true/false correctly; cached normal bounds stayed 720 × 480 at outer position (220, 180); exiting restored fullscreen returned to the original client bounds (220, 254, 720, 480).
- Fresh configuration without a state file launched windowed. A legacy fixture missing the `fullscreen` field also launched windowed without failure, using the plugin's existing load fallback.

## checks

- `cargo test --locked` in `app/src-tauri`: passed, 42 native tests, plus binary and documentation targets.
- `cargo test --manifest-path vendor/tauri-plugin-window-state/Cargo.toml`: passed, two plugin tests and documentation target. The standalone test crate resolved its own ignored lockfile.
- `cargo test --locked -p tauri-plugin-window-state`: passed, the same two tests against the app's exact locked dependency graph.
- `cargo build --locked`: passed after removing the temporary runtime harness.
- `rustfmt --check --config-path rustfmt.toml --config skip_children=true src/lib.rs`: passed for the changed app source.
- `cargo fmt --manifest-path vendor/tauri-plugin-window-state/Cargo.toml --check`: passed for the patched crate, formatted with the project's two-space convention.
- `cargo fmt --check`: failed on existing formatting in `app/src-tauri/build.rs`, `app/src-tauri/src/main.rs`, and `app/src-tauri/src/http.rs`. These files have no changes in this task; checking the base branch's `build.rs` reproduced its mismatch. The project-wide formatting criterion remains blocked by those baseline differences.
- Locked Linux Cargo metadata confirmed the selected plugin is the local version `2.4.0` override. npm, npm lockfile, Cargo, and Tauri versions agree on `0.15.8`.
- An unfiltered offline metadata query initially required an uncached Android dependency; the Linux-filtered locked query passed without changing dependency versions.
- `git diff --check`: passed.

## limits

- Runtime fullscreen transitions were exercised through Tauri's native API. An initial direct X11-only fullscreen request changed the window manager state without updating Tauri's `is_fullscreen` result; that external-only path is not asserted as supported by this patch.
- Runtime results cover Linux/Muffin. Windows, macOS, other window managers, and changed-monitor layouts were not available for verification.
- Only `x86_64-unknown-linux-gnu` is installed, so Android/iOS build checks were not run. Desktop registration/import/dependency guards remain intact.

## release and commits

- Version: `0.15.8`.
- App commit: `e77c512` — `Remember desktop fullscreen and preserve windowed bounds`.
- App changes are committed in the submodule; the parent commit records the app pointer, updated plan, and this report.
