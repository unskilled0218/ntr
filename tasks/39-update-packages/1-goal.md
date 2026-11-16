# Goal

- [Command](#command)
- [Goal](#goal-1)
- [Suggestions](#suggestions)

## Command

- Update app and server packages

## Goal

Update app JavaScript/native Rust and server Rust dependencies to supported stable releases, addressing the remaining npm audit findings while preserving existing app behavior, HA security/recovery, and release tooling. Retain the user's existing npm audit-fix improvements.

## Suggestions

Review major upgrades explicitly instead of using forced audit fixes. Preserve deliberate native/vendor pins unless their compatibility can be established. Refresh lockfiles, run relevant tests/builds/audits, and report unavailable native checks or remaining advisories honestly. No deployment, publication, push, or live HA operations.
