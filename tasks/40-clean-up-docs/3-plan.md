# Plan

- [Scope](#scope)
- [Documentation changes](#documentation-changes)
- [Verification](#verification)
- [Delivery](#delivery)

## Scope

Use the existing task 40 goal and accepted suggestions. Clean maintained parent/app/server READMEs and topic docs. Exclude historical task archives, existing release records, vendored docs, private files, `command.md`, and user-edited `todo.md`. Do not change runtime behavior, data, Compose configuration, API routes, source comments, or tests. Version/release metadata updates required by the implementation workflow are the only non-documentation edits. No UI design is needed.

## Documentation changes

1. Keep READMEs to purpose, quick start, current version/release link, and topic links. Remove old feature/version narratives and duplicate setup/safety explanations. Use `npm ci` and the existing single server Compose setup.
2. Remove format branding, external-format links, filename examples, and legacy priority tutorials from maintained documentation. Describe tasks through the current ntr UI/API and HA list workflow instead. Replace the old server format guide's body with a minimal current-API navigation stub so unchanged historical release links still resolve; no maintained guide will link to that legacy path. Rewrite `app/docs/task-text.md` as short current editing/date guidance rather than an old format/compatibility tutorial.
3. Shorten app feature/run/project/connection/live-sync/development/build/signing/publication/stack pages. Give each topic one home. Keep remote approval, local fallback versus HA authority, draft ownership, nontransactional writes, explicit recovery, signing-key identity/loss consequences, supported tooling, and publication prerequisites/refusal rules. Keep exact commands and essential timing/permission constraints accurate.
4. Shorten server configuration/Compose/HA/API/task-ID/note/live-update/development/release pages. Preserve single-file Compose prerequisites, loopback/no-auth warnings, private token/CA paths, verified HTTPS/WSS, admin opt-in, empty/default-list deletion guards, no-replay moves, external-writer races, Unix fsync limits, metadata backup/migration, and API contracts. Remove duplicate prose and obsolete version-specific narratives without presenting unchanged backends as removed.
5. Keep dedicated package-association contract/recovery pages. Remove redundant narrative but retain supported-version gates, trusted pin requirements, scoped write/readback rules, credential protection, exclusivity, and refusal/no-rollback limits. Replace stale prepared-version claims in the image-release entry point with links to current release/deployment guidance.
6. Keep headings and tables of contents consistent, repair maintained local links/anchors, and preserve historical link destinations with minimal navigation stubs where necessary. Do not edit historical release bodies or archived task records merely to satisfy text searches.
7. Bump app `0.15.33` to `0.15.34` and server `0.2.14` to `0.2.15` using their existing mirrors and release-notes pointers. Add concise documentation-only notes; do not change the user's Android certificate setting or regenerate dependency versions.

## Verification

- Check local links, anchors, and table-of-contents targets throughout maintained docs and the new release notes. Verify old release links still reach existing files, without rewriting their records. Record any pre-existing unrelated documentation issue separately.
- Search maintained documentation for removed format branding, external format links, and literal old task-filename examples. Only excluded history, this task's quoted request, and the unlinked legacy compatibility path may retain historical names. Check that current API examples remain valid and no backend removal is claimed.
- Compare protected safety details against the inspected code/configuration, not only earlier prose. Validate shell snippets syntactically where useful; do not run publication, recovery, deployment, or live API commands.
- Run app/server offline release validation, app release-tool tests (including signing-document guidance checks), server Python tests, and version/whitespace checks. Runtime tests need not be rerun for unchanged implementation; record this limitation explicitly.
- Verify all pre-existing release records, archived task content, vendor files, and `todo.md` remain byte-identical. Preserve app's existing signing commit `7e32ad2` and server's existing Compose commit `a0b02a8` as branch ancestors; do not discard or amend user work.

## Delivery

Review and update this plan, then create fresh `40-clean-up-docs` branches in parent, app, and server. Implement the reviewed documentation changes, write `5-implemented.md` with validation and content-reduction results, commit submodules, then commit the parent README/results and updated pointers. Do not push, publish, or deploy. Notify after each workflow stage.
