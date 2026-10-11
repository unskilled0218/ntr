# implemented

## changes

- Created new `6-remember-desktop-maximized` branches in the parent repository and `app` submodule, based on the current fullscreen implementation.
- Enabled `StateFlags::MAXIMIZED` alongside position, size, and fullscreen in the desktop-only plugin registration. The configured default remains a normal 800 × 600 window.
- Reproduced a first-maximize restart position failure with flags alone: normal client bounds began at (140, 214), but unmaximizing after restart returned to (0, 74). Fixed normal/previous-position capture and retained compatibility with existing maximized entries using `prev_x`/`prev_y`.
- Replaced separate fullscreen resize callbacks with one per-window phased restore policy in the local plugin's `src/restore.rs`: apply normal size, confirm requested maximization, then restore fullscreen.
- Added attempt identities, a two-second overall deadline, and a bounded 50 ms native main-thread poll using the same policy as move/resize events. Confirmed stable usable geometry can advance a constrained-size wait after one second without bypassing mode confirmation.
- Native request failures, deadline failure, close, and supersession invalidate pending attempts. Old callbacks cannot issue further requests for a terminated attempt. Native setters run outside the cache mutex.
- Preserved cached normal bounds during pending/maximized/fullscreen transitions. Unknown native mode observations cannot authorize capture or clear cached mode values. After failure, confirmed normal samples must settle before geometry capture resumes.
- Kept the underlying non-fullscreen maximized mode while fullscreen, and updated maximized true/false on native transitions outside fullscreen.
- Kept pending phases, identities, deadlines, and geometry protection out of the existing JSON state schema. Retained the local plugin version/override and desktop/mobile guards.
- Updated the desktop window-state README note and plugin `PATCH.md`. Bumped app version consistently from `0.15.8` to `0.15.9` in npm metadata/lockfile, Cargo metadata/lockfile, and Tauri configuration, without dependency upgrades.

## native runtime verification

- Platform: Linux X11 with `Mutter (Muffin)`; native fullscreen bounds were 3840 × 2160 physical pixels.
- Launched the real app with `npm run tauri dev -- --no-watch`. Used a temporary native harness calling Tauri maximize/unmaximize/fullscreen APIs, checked X11 mode atoms, and closed normally through `_NET_CLOSE_WINDOW`. Temporary harness hooks were removed before final native checks/build.
- Used isolated config/data/cache roots under `/tmp/opencode`, with a disposable real server and fixture task/note/labels paths. Server reconciliation was confirmed against the isolated app data.
- Local and server-mode suites passed first-launch maximize/relaunch/unmaximize, two complete maximized/normal restart cycles, maximized → fullscreen → close → relaunch → exit fullscreen → unmaximize, and normal → fullscreen restart/exit with two additional cycles.
- Maximized restart snapshots contained `maximized: true, fullscreen: false`; unmaximize/close snapshots contained both false. Combined snapshots contained both true and reopened fullscreen, then returned to maximized when fullscreen was exited.
- Normal bounds stayed 720 × 480 at outer position (220, 180), with matching previous-position fields. Unmaximize and fullscreen exit returned to client bounds (220, 254, 720, 480).
- Fresh configuration and a legacy fixture missing the required fullscreen field launched successfully. Valid saved maximized true/false entries were exercised by repeated relaunches; previous-position compatibility also has focused unit coverage.
- No restore failure/timeout/request-failure messages appeared in the successful server-mode lifecycle log.

## checks

- `cargo test --locked` in `app/src-tauri`: passed, 42 app-native tests plus binary/documentation targets.
- `cargo test --locked -p tauri-plugin-window-state`: passed, 12 plugin tests plus documentation target, using the app's exact locked graph.
- Plugin coverage includes all requested mode combinations, dispatched-but-unconfirmed maximization at deadline, stable constrained-size advancement, unknown mode queries, failed requests, close/supersession and late callbacks, protected geometry settlement, first/legacy normal positions, and nonserialized transient state. Time-dependent cases use controlled `Instant` values without sleeps.
- `cargo build --locked`: passed after temporary native harness removal.
- `cargo check --locked --target aarch64-linux-android --lib`: passed with the installed NDK `29.0.13846066` API-24 ARM64 compiler/linker and a separate `/tmp/opencode/android-check-target` directory. This confirms Android conditional compilation, not APK packaging or device runtime.
- `rustfmt --check --config-path rustfmt.toml --config skip_children=true src/lib.rs`: passed.
- `cargo fmt --manifest-path vendor/tauri-plugin-window-state/Cargo.toml --check`: passed.
- `cargo fmt --check`: still reports the known baseline mismatches in `build.rs`, `src/main.rs`, and `src/http.rs`. Those files were not changed; changed Rust files pass targeted formatting checks.
- Locked Linux Cargo metadata confirmed the local plugin override. npm, npm lockfile, Cargo, and Tauri version values agree on `0.15.9`.
- `git diff --check`: passed. No temporary harness paths or environment hooks remain in app source.

## limits

- Native runtime results cover Linux/Muffin in local and server modes. Windows, macOS, iOS, other window managers, and physical monitor-change scenarios were not available for runtime verification.
- Constrained geometry, native request failure, timeout, and stale-callback behavior were verified deterministically in policy/cache tests rather than by forcing desktop-driver failures.
- Fullscreen toggles used the Tauri native API, consistent with the preceding task's tested contract.

## release and commits

- Version: `0.15.9`.
- App commit: `8e927a9` — `Remember maximized windows and coordinate native restore modes`.
- App implementation is committed in the submodule. The parent commit records the app pointer and this task report.
