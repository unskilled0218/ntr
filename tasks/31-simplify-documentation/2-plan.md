# plan

- [scope](#scope)
- [Implementation Plan](#implementation-plan)
  - [Summary](#summary)
  - [1. Inventory and simplify current documentation](#1-inventory-and-simplify-current-documentation)
  - [2. Preserve operational contracts](#2-preserve-operational-contracts)
  - [3. Verify and record changes](#3-verify-and-record-changes)
- [Acceptance Criteria](#acceptance-criteria)
- [Risks And Decisions](#risks-and-decisions)

## scope

Make the current project documentation shorter and simpler while retaining accurate, discoverable information. Review the root README and the app and server READMEs and documentation; edit only documents that benefit from simplification. Do not change implementation, configuration, task semantics, release state, or unrelated `todo.md` work.

## Implementation Plan

### Summary

The root, app, and server each have a README and dedicated topic documents. Repeated feature summaries appear in the root and app READMEs, while `app/docs/live-sync.md` and `app/docs/project-renaming.md` mix user-facing guidance with detailed implementation and recovery behavior. Server publication and package recovery documents contain operator safety constraints that cannot be removed merely to reduce length. Simplify prose and repeated entry points without collapsing the documentation into one guide or claiming behavior that is not verified.

### 1. Inventory and simplify current documentation

- Inventory tracked Markdown in the root, `app/`, and `server/`, excluding task records, `todo.md`, vendored dependencies, and generated build output. Review current README and `docs/` content, including `app/docs/live-sync.md`, `app/docs/project-renaming.md`, `app/docs/server-connection.md`, `server/docs/api.md`, and the release and recovery topic documents. Treat historical `server/docs/releases/` entries as historical records; do not rewrite them merely for brevity.
- Keep each README a concise entry point: what the component does, how to start it, important immediate warnings, and links to relevant topic documents. Replace repeated detailed feature paragraphs with brief descriptions and links where the target document actually covers the behavior. Keep submodule initialization and the server's no-authentication warning discoverable from the root.
- In topic documents, use plain language, short sentences, clear headings, and concise steps. Remove repeated explanations only when an accurate, accessible canonical section remains linked. Retain distinct app/server topics and existing document paths and section anchors where practical; do not consolidate everything into a single guide. Preserve Markdown formatting, applicable tables of contents, runnable commands, examples, and meaningful accessibility information.
- Check changed statements against the current code, configuration, scripts, and existing tests where needed. Distinguish documented current behavior, known limitations, and unverified platform behavior; do not assert that locally prepared release artifacts are published or that untested workflows were validated. Correct stale prose only when supported by repository evidence.

### 2. Preserve operational contracts

- Preserve the user-visible consequences of local fallback, explicit reconnect, approval and autosave pauses, draft handling, last-write-wins, project-operation partial completion/retry, and compatibility limitations. Simplify internal details only when removing them cannot mislead users or operators; link to the authoritative topic where details remain necessary.
- Preserve server API methods, paths, input/output examples, error behavior, authentication warning, and client compatibility limits. Do not change an example's semantics or remove a command needed to perform its documented task.
- Preserve release prerequisites, credentials handling, approval requirements, commands with live side effects, immutable identity and verification checks, refusal/recovery behavior, and concurrency limits. Review `server/docs/release-*`, `package-association-*`, `image-release.md`, and `app/docs/forgejo-publishing.md` with their scripts before shortening. Retain safety-critical detail in its dedicated file when a shorter summary would be ambiguous; do not run publication, recovery, or other live mutation commands.
- Avoid deleting or renaming documents and headings referenced by other tracked files. If a change is unavoidable, update all local references and table-of-contents anchors in the same change and preserve a clear route to the original information. Do not modify task archives to repair historical links; instead preserve their targets.

### 3. Verify and record changes

- Review the complete Markdown diff for accuracy, scope, and lost instructions. Compare each removed operational detail against the retained canonical text, with special attention to overwrite choices, partial/uncertain outcomes, lack of authentication, credentials, and irreversible release effects. Record which documents changed and any deliberately retained long safety sections in `4-implemented.md`.
- Check relative Markdown links and heading anchors in all changed files and inbound links from tracked documentation, including root-to-submodule paths. Verify code blocks and commands against their documented working directories and current scripts without executing live publication or destructive operations. Update tables of contents for changed headings and retain each document's existing structure when no edit is needed.
- Run `git diff --check` in each changed repository and perform the project's existing documentation/link checks if available. For any rewritten command examples, use read-only help or local validation only when safe and available; record skipped checks and missing prerequisites. A documentation-only task does not require a full application build unless a documentation check depends on it.
- Commit documentation changes separately in each modified app or server submodule, then commit parent documentation, task results, and only the corresponding gitlink updates. Follow each repository's existing version convention: do not invent a release for prose-only edits; if the workflow explicitly requires a version change, document that decision and update all established mirrors consistently. Do not stage unrelated files.

## Acceptance Criteria

- Current project documentation is clearer and shorter where meaningful, with concise READMEs and navigable dedicated topic files.
- Essential startup, security, API, data safety, recovery, release, and compatibility information remains accurate and discoverable; historical release records remain intact.
- Changed relative links, anchors, tables of contents, commands, and examples are checked. No live publication, recovery, or destructive operation is performed.
- Only documentation and task records change, apart from required submodule gitlinks or an explicitly justified version update. Verification and limitations are recorded in `4-implemented.md`.

## Risks And Decisions

- Shorter is not safer if it omits conditions or failure modes. Keep necessary operational detail even when it prevents a document from becoming much shorter.
- App and server are independent Git submodules; a parent commit must reference committed documentation changes rather than uncommitted submodule work.
- Existing release notes and archived tasks are historical evidence. Keep them unchanged and preserve their referenced paths and anchors.
- Local link and command checks cannot establish external service availability or authorize a live release; report those boundaries explicitly.
