# Plan

- [Scope](#scope)
- [Dependency changes](#dependency-changes)
- [Verification](#verification)
- [Delivery](#delivery)

## Scope

Update the app npm dependency stack, compatible app-native Rust dependencies, and server Rust dependencies. Preserve HA trust/no-replay guarantees, local/native behavior, release tooling, and the user's existing audit-fix lockfile changes. No UI redesign or `2-design.md` is needed. No live HA operations, deployment, publication, push, root installation, or changes to `todo.md`.

## Dependency changes

1. Create fresh `39-update-packages` branches in parent, app, and server at implementation. Retain the existing npm audit-fix improvements as part of the requested dependency update; do not reset the lockfile or use `npm audit fix --force`.
2. Upgrade to current stable npm releases compatible with the selected stack: React/DOM `19.3.1`, Tauri API/CLI `2.12.5`, opener `2.7.3`, testing-library `16.3.3`, React type packages `19.3.0`, Vite `8.3.8`, React plugin `6.3.0`, Vitest `5.1.0`, jsdom `31.0.1`, and TypeScript `7.0.2`. Validate peer dependencies instead of bypassing them. Regenerate the lockfile and run clean `npm ci` to validate reproducibility.
3. Make only required build/test compatibility changes for the major tool upgrades. Preserve assertions and test intent; do not hide failures by skipping tests or weakening security checks. Preserve real-serializer contract entry points. Declare/document the supported Node versions required by these tools: `^22.22.2 || ^24.15.0 || >=26.0.0`; the current container uses Node `26.13.0`.
4. Refresh the app native Cargo lockfile within existing compatible ranges, including current Tauri 2, opener/dialog, reqwest 0.13, Tokio, Serde, and transitive dependencies. Retain patched vendored `tauri-plugin-window-state =2.4.0` and Android filesystem plugin 28.4.x: replacing the local patch or taking the Android-only major 30 requires separate platform validation. Do not replace patched vendor code. Correct dependency documentation if upstream TLS backend defaults changed.
5. Update the server to tower-http `0.7.1`, reqwest `0.13.5`, and tokio-tungstenite `0.30.0`; refresh compatible dependencies and lockfile. Keep `default-features=false`, verified HTTPS/WSS, custom CA handling, explicit no redirects, bounded messages/requests, and the durable journal. Review reqwest 0.13's renamed Rustls features and select a consistent crypto provider/trust configuration; adapt code only where the new APIs require it.
6. Update READMEs, dependency/toolchain development guidance, and release notes for both components. Bump app `0.15.32` to `0.15.33` and server `0.2.13` to `0.2.14`, including package/Cargo/Tauri mirrors, lockfiles, and release-notes pointers. Document intentionally retained pins and any remaining advisories rather than claiming every package is latest.

## Verification

- App: clean install, `npm audit` and production-only audit, full frontend tests, TypeScript/Vite build, release-tool tests/validation, and both real serializer contracts where native prerequisites permit. Inspect `npm outdated` and document deliberate exceptions. Aim for zero npm advisories, not merely removal of high-severity entries.
- Native app: attempt locked tests and strict Clippy with available system libraries; report missing packages/targets rather than installing them. Preserve vendor/native-platform limitations and do not claim Android/Windows/macOS validation from a Linux build.
- Server: locked tests, formatting, strict Clippy, Compose rendering, release validation, and generated-CA HA contract covering trust, origin filtering, list management, moves, and persistence faults. Keep security-related tests unchanged except API compatibility changes.
- Inspect Cargo update output and resolved TLS features. Run Rust security tooling only if already available; otherwise report the audit limitation and avoid a Rust vulnerability-free claim. Check version mirrors and Git whitespace.

## Delivery

Review and update this plan before implementation. Record actual version selections, compatibility changes, retained pins, audits, passed/blocked checks, and no-publication status in `5-implemented.md`. Commit app/server changes first, then the parent results and submodule pointers. Notify after each workflow stage.
