# plan

- [scope](#scope)
- [Implementation Plan](#implementation-plan)
  - [1. Isolate the release tag push](#1-isolate-the-release-tag-push)
  - [2. Prove the remote mutation boundary](#2-prove-the-remote-mutation-boundary)
  - [3. Update release metadata and documentation](#3-update-release-metadata-and-documentation)
  - [4. Verify and record implementation](#4-verify-and-record-implementation)
- [Acceptance Criteria](#acceptance-criteria)
- [Risks And Decisions](#risks-and-decisions)

## scope

Fix only critical finding F1 from `tasks/18-server-container-release-template/5-code-review.md`: ambient `push.followTags=true` can cause the server publisher's explicit release-tag push to publish additional reachable annotated tags. Change the push command, add real-Git fixture coverage, and update relevant release metadata/documentation. Preserve the existing transaction, immutable identity, non-force behavior, source destination checks, and accepted-but-lost response reconciliation. Do not fix warning F2, change application code or the app pointer, access real credentials, publish remotely, clean up existing tags, or edit `todo.md`.

## Implementation Plan

### 1. Isolate the release tag push

- During implementation, create fresh parent and server branches named `19-release-tag-push-isolation` from their current task-18-derived revisions; do not recreate or rewrite task 18. This planning stage changes only this document.
- In `server/scripts/release.sh`, add `--no-follow-tags` to the existing `git -C "$root" push origin "$oid:refs/tags/$tag"` invocation. Keep the exact object-to-fully-qualified-tag refspec, `origin`, bounded command wrapper, and `attempt` handling unchanged.
- Do not write Git configuration or replace the explicit refspec with `--tags`, `--mirror`, force flags, source pushes, or broader refspecs. Preserve all surrounding guards, read-back confirmation, and subsequent promotion/release/package authority.

### 2. Prove the remote mutation boundary

- Extend `server/tests/test_bash_release.py` using its existing `Fixture`, real `/usr/bin/git`, disposable bare remote, synthetic token, and fake Docker/curl ports. The existing Git wrapper forwards push arguments to real Git, so do not simulate successful tag isolation or require an exact flag in the fake as a substitute for observing remote refs.
- Add an entry-point regression that completes fixture source setup first, then enables repository-local `push.followTags=true` and creates a reachable annotated `unrequested-tag` on the pushed source commit. Assert the setting is effectively true and the unrelated tag is initially absent remotely. Do not call `Fixture.commit()` after creating that tag, since its setup source push could itself follow tags.
- Capture initial bare-remote refs, the local unrelated-tag object ID, source `main`, and local Git configuration bytes. Run the actual Bash publisher and require success. Inspect real remote refs: the only additions must be the intended release tag and its peeled advertisement; source `main` and all pre-existing refs must remain unchanged, and the unrelated annotated tag must remain local with its original object ID. Verify `push.followTags` and configuration bytes remain unchanged.
- Exercise both ordinary tag-push completion and `lose_tag=True`, which the existing wrapper injects only after real Git accepts the push. Require exactly one `tag-push` event and one normal publication sequence per case, successful exact-evidence reconciliation, and no unrelated remote tags. Keep the existing all-lost-writes test unchanged unless a narrowly necessary assertion is added.
- After a completed publication, clear events and rerun with the same enabled setting and unrelated local tag. Require a successful read-only completed retry, no publication writes, and the same remote ref set.
- Demonstrate regression sensitivity: run the new ordinary case against the original command before applying the fix, or remove only `--no-follow-tags` in an owned disposable fixture. Require evidence of the extra remote tag and failure of the intended isolation assertion, not an unrelated early refusal. Never mutate production checkout scripts for a negative control. Restore/use the actual fixed implementation for final verification.

### 3. Update release metadata and documentation

- Follow the existing patch-version convention for this implementation: prepare `0.2.6` in `server/VERSION`, mirror it in `Cargo.toml` and only the `my-ntr-server` package entry of `Cargo.lock`, and point `scripts/release.json` at new committed `docs/releases/0.2.6.md`. Keep dependencies unchanged. Notes begin `# Release v0.2.6` and describe the tag-isolation fix, not a live publication.
- Update the server README's prepared version/link, active release-entry links/version text, and consumer-contract test expectations to `0.2.6`. Keep historical `docs/releases/0.2.5.md` and task records intact. Do not perform blind repository-wide version replacement; the Compose `latest` reference and template pin/version remain unchanged.
- Add a concise statement in `server/docs/release-publication.md` explaining that the tag push disables follow-tags only for that invocation and leaves caller configuration intact. Update `server/docs/release-verification.md` with the real-Git isolation and lost-response regressions. Describe this as a local hardening change, without claiming upstream was fixed or F2 was addressed.
- Keep README short, use the existing dedicated documents, and include tables of contents for newly created Markdown files. Keep metadata and notes consistent with credential-free `--validate` checks.

### 4. Verify and record implementation

- Run the new regression first, including the ordinary/lost-response/read-only cases and its red/green evidence. Rerun existing successful publication, accepted-but-lost writes, startup partial-state refusal, source destination validation, and confirmed-tag-loss tests. Use only disposable fixtures; no no-argument publisher invocation against the real checkout is authorized.
- From `server/`, run `python3 -B -m unittest discover -s tests -p 'test*.py' -v`, `bash -n scripts/release.sh`, `bash -n scripts/release-common.sh`, `./scripts/release.sh --help`, and `./scripts/release.sh --validate`. Run local version/notes/documentation-link checks, `docker compose config` when available, and parent/server `git diff --check`, including staged changes before commits.
- Attempt `cargo test --locked`, `cargo clippy --all-targets --locked`, and `cargo fmt --check`. Cargo/rustc were absent during task 18; record exact failures if still unavailable and tell the operator Rust with Cargo, Clippy, and rustfmt is needed. Do not install tools, run privileged preparation, or reformat unrelated code.
- No real image build, daemon changes, registry login, source push, release/tag/package mutation, deployment, or live cleanup is needed to verify this CLI flag fix. Keep previous native/runtime/live-service verification limits explicit; fake-port success is not live publication approval.
- Write `tasks/19-release-tag-push-isolation/4-implemented.md` with changed files, exact commands/results, red/green evidence, limits, and server commit ID. Commit the server changes first, then commit its pointer and the report in the parent. Exclude the existing unrelated `todo.md` modification and keep the app pointer unchanged.

## Acceptance Criteria

- With effective `push.followTags=true` and a reachable unpublished annotated local tag, a successful release adds only its intended remote release tag; unrelated tags remain local and source/pre-existing refs remain unchanged.
- The regression demonstrably fails against the unfixed command because an extra remote tag appears, then passes with the explicit override. Assertions observe real bare-remote refs, not only emitted arguments or exit status.
- An accepted-but-lost tag push reconciles successfully with exactly one push attempt and the same isolated mutation set. Completed retries remain read-only.
- User Git configuration remains byte-for-byte unchanged, the configured setting stays true, and no force, all-tags, mirror, source-push, deletion, or rollback behavior is introduced.
- Version `0.2.6`, Cargo mirrors, committed notes, README, settings, and consumer tests agree. Relevant documentation describes the fix without implying publication or resolving F2.
- Relevant tests and local validation pass, or exact environment blockers are recorded. Implementation changes remain confined to server release tooling/tests/metadata/docs and the parent pointer/report; no app or `todo.md` edits occur.

## Risks And Decisions

- An explicit refspec alone does not suppress Git's follow-tags preference. Use the documented per-invocation `--no-follow-tags` override rather than changing persistent configuration, disabling all Git configuration, or attempting to detect and delete extra remote tags afterward.
- The fixture must create the unrelated tag after its source setup push and keep the original argument-forwarding Git seam. Otherwise setup side effects or an over-specified fake could conceal the regression or produce a false pass.
- This task hardens future pushes only. Previously published unintended tags, if any, are outside scope and must not be automatically removed. The fix does not claim to defend against arbitrary malicious hooks or every possible ambient Git setting.
- Updating a release script changes the annotation-bound script identity. Prepare a new patch version rather than claiming ownership of an older publication; do not rewrite historical tags, notes, or transactions. Version preparation and commits do not authorize source pushes or publication.
- ARM64 v8 compatibility warning F2 remains intentionally unresolved. Rust, native container, deployment compatibility, and distributed-writer limits remain independent of F1's regression result.
