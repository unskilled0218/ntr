# goal

## command

- script to push files(apk, aab, dev, etc...) to forgejo page releases

## goal

Provide a documented script workflow for publishing the app's built Android and desktop files as downloadable assets on its Forgejo Releases page. Cover APK, AAB, and the desktop packages produced by this project, including DEB, AppImage, and RPM. The request says `dev`; the current desktop build produces `.deb` packages, so use those existing outputs as the initial desktop scope and clarify any separate development-build requirement during planning.

The target is the app submodule at `app/`, whose origin is `ssh://git@git.lan/ntr/ntr-app.git`. Its existing `scripts/build-release.sh` collects artifacts in `release/<version>/{desktop,android}/`, and `scripts/release.sh` already creates Forgejo releases and uploads artifacts with SHA-256 files. Inspect and verify this existing workflow, then address concrete gaps needed to satisfy the request rather than introducing a parallel publisher.

The intended result is a command that publishes the selected desktop, Android, or combined artifact set to the corresponding `v<version>` release at `https://git.lan/ntr/ntr-app`. Reuse already-built artifacts when appropriate, keep version/tag/artifact identity consistent, and make failures and rerun behavior clear. Document the command, required tools, externally supplied `FORGEJO_TOKEN`, and optional `FORGEJO_API_URL` override.

## acceptance criteria

- The release command supports Android-only, desktop-only, and combined publishing using the project's existing artifact layout.
- APK, AAB, and available desktop package files appear as downloadable release attachments with their corresponding SHA-256 files.
- The release version, Git tag, and uploaded artifacts refer to the intended build; existing artifacts are not silently attributed to a different revision.
- Missing requested artifacts, authentication/API failures, and duplicate attachments produce clear outcomes. Interrupted uploads and reruns have documented behavior that preserves previously published assets.
- Verification covers artifact discovery, release lookup/creation, upload requests, and failure/rerun behavior using disposable fixtures or a controlled API seam. Record any unavailable live Forgejo verification separately.
- The app README provides working examples for the supported publishing commands and configuration.

This stage records a fresh goal only. Implementation and release execution belong to later workflow stages.
