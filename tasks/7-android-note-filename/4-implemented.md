# implemented

## changes

- Created new `7-android-note-filename` branches in the parent repository and `app` submodule.
- Updated `SafBackend::existing_or_new_file_uri` to infer MIME from the filename for `paths::NOTE_FILE` by passing `None` to `create_new_file`. Other filenames retain `Some("text/plain")`.
- Preserved exact-name discovery and the early return for existing documents. The requested note filename remains `Note.md`.
- Newly created notes must pass the plugin's fallible `get_name` check before content is written. A different display name or metadata error rejects the save.
- Rejected creation removes only the newly created, still-empty document using its returned URI. Cleanup failure reports the original error, cleanup error, and document URI. There is no retry, rename, legacy-file cleanup, or URI cache.
- Confirmed by code inspection that `NoteStore::replace` updates cached content only after backend write succeeds. `move_backend_file` writes the destination before removing the source, and `set_data_dir` propagates a rejected note write and rolls back earlier task-file moves. No separate directory-change workaround is needed.
- Bumped the app patch version from `0.15.9` to `0.15.10` in npm metadata/lockfile, Cargo metadata/lockfile, and Tauri configuration, following previous implementation tasks.

## verification

- `cargo test` in `app/src-tauri`: passed, 42 tests plus binary and documentation targets. Existing tests cover filesystem persistence, note replacement/reload, tasks, labels, successful directory moves, and rollback. They do not compile or exercise the Android-only backend.
- `cargo clippy --all-targets` in `app/src-tauri`: passed without warnings on the desktop target.
- `rustfmt --edition 2021 --check --config-path rustfmt.toml --config skip_children=true src/backend.rs` in `app/src-tauri`: passed. An initial invocation without `--edition 2021` failed because standalone rustfmt defaulted to Rust 2015; the corrected command uses the package's edition.
- `git diff --check` in the app repository: passed.
- Inspected the installed `tauri-plugin-android-fs` `28.4.0` source: `create_new_file` accepts `Option<&str>` and documents extension-based MIME inference for `None`; `get_name` returns a fallible display name; `remove_file` accepts the newly returned URI.
- `npm run tauri android build` in `app`: blocked before compilation with `failed to ensure Android environment: Skipping Android Studio command line tools installation. Please go through the manual setup process described in the documentation: https://tauri.app/start/prerequisites/#android`.
- Retried the same build with `JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 ANDROID_HOME=/home/dev/Android/Sdk`: same setup error. JDK 17 and SDK command-line tools are present, but Tauri did not accept the available setup. The SDK directory has no NDK, and `rustup target list --installed` reports only `x86_64-unknown-linux-gnu`. No Android Rust compilation or APK build succeeded.
- `adb devices -l`: blocked because the configured daemon at `tcp:host.docker.internal:5037` refused the connection. No Android device or emulator was available; Android version and document provider are unknown.

## unverified acceptance criteria

- Actual provider creation of exactly `Note.md`, repeated saves including shorter content, restart/reuse, existing canonical notes alongside untouched legacy copies, data-directory moves, and Android task/label persistence remain unverified.
- Provider name mismatch, metadata failure, and denied cleanup were not exercised. Runtime preservation of cached note content and directory-move sources on those paths remains unverified. The implementation's ordering was inspected, but desktop checks do not establish these Android results.
- The original naming behavior could not be reproduced on the affected provider. MIME inference and validation implement the planned fix, but successful canonical creation on that provider still requires device verification.
- To finish Android verification, repair the SDK setup recognized by Tauri, install an Android NDK and the Rust targets required for the selected Android architectures, and provide a reachable ADB device/emulator with the affected document provider. No system packages were installed during this task.

## release and commits

- Version: `0.15.10`.
- App commit: `20ee9e3` — `Preserve and verify Android note filenames`.
- The app implementation is committed in the submodule. The parent commit records the app pointer and this task report.
