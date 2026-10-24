# Implementation

- [Changes](#changes)
- [Contract Evidence](#contract-evidence)
- [Verification](#verification)
- [Limits](#limits)
- [Commits And Scope](#commits-and-scope)

## Changes

Added a named package-link contract classifier in `server/scripts/release-data.py`: stable Gitea `1.25.x` remains supported, and only exact stable `28.2.0` is added. Nearby/development/build-suffixed versions remain unsupported. Existing correct links stay read-only; null links require refreshed exact identities, the reviewed server contract, one scoped bodyless POST, empty 201, and exact readback. Conflicts, permission-hidden existing links, malformed evidence, unexpected replies, and failed reconciliation refuse without reassignment, blind replay, or rollback.

Added the explicit CLI `--associate-existing <tag> --expected-tag-oid <oid> --expected-source <commit>` in `release.sh`, with strict effect-free argument validation and lock re-exec forwarding. Recovery requires clean, already-pushed current server main and exact destinations, explicit historical pins, ancestral historical source, complete bounded inventories, historical settings/version/Cargo/README/notes/script blobs, canonical annotation bytes and hashes, matching immutable platform/config labels, literal `latest` equal to the old bound digest, and current/historical stability before and after association. Historical scripts are only read as bounded committed data, never executed or imported. Shared credential preparation supports this path without Docker/Buildx/login; shared association policy permits only the missing-link POST. Correct-link repeats are read-only. Current normal publication remains identity-strict and retains its non-force no-follow-tags push, builder/plugin/auth isolation, and existing transaction guards.

Added flushed elapsed-time phase messages to stderr in the shell/helper and fixed ten-second heartbeat messages inside bounded subprocess capture, including operations that close their pipes before exiting. Child output remains private and bounded; no raw arguments, auth data, API bodies, or child stdout/stderr are relayed. Lost responses are labeled uncertain until readback, and final success remains separate from intermediate publication/link confirmation. Machine-readable helper values and final references remain on stdout.

Prepared server `0.2.7` with canonical `VERSION`, Cargo package mirrors, settings notes path, README, active release links, consumer tests, and committed notes. Added dedicated package-contract and pinned-recovery documentation; updated configuration, publication, verification, and development documents. Retained old `0.2.6` notes, dependency versions, Compose `latest`, Dockerfile/runtime behavior, and template pin. Added `tests/test_release_recovery.py` and narrowly extended existing fixture setup, command-port injections, and version expectations.

## Contract Evidence

Reviewed Gitea `28.2.0` at exact upstream commit `829b49c1ae96015e345f9d2a0eb1ea7acd5f31e1`, including API routes/package middleware, link handler/service, permission-filtered serializer, model update, and relevant upstream API tests. The service rejects owner mismatch and positive existing `RepoID`, requires target package-unit write permission, and the handler returns conflict 400/permission denial 403/empty success 201. The serializer can hide an inaccessible link as null. Compared the earlier supported `1.25.0` link service's equivalent refusal checks. Source links and deployment/provenance assumptions are recorded in `server/docs/package-association-contract.md`. Upstream tests were inspected, not executed.

The model update is not compare-and-set. Exclusive package/association writers, including UI operations and in-flight requests, remain an operator prerequisite. Public planning observations matched official Gitea `28.2.0` and the accepted `v0.2.6` tag/source/digest, but do not attest the installed binary or authorize a live mutation. No production credential was accessed to inspect the package endpoint that returned unauthenticated 401 during planning.

## Verification

- Focused run: `python3 -B -m unittest test_release_recovery test_bash_release.DataTests -v`, from `server/tests/`, passed all 25 methods in 210.258 seconds. Log: `/tmp/opencode/ntr-task20-targeted.log`.
- These tests cover old publication under changed valid committed/pushed tooling, no Docker executable, ordinary and accepted-but-lost link responses, no-write repeats, wrong pins/partial evidence, non-ancestor/noncanonical/foreign bindings, unsafe/missing/oversized committed inputs, an execution sentinel in historical code, hidden/visible conflicts, no replay/rollback, and injected latest/tag/current-tool drift immediately before and after linking. They also cover recovery parser/lock/signal behavior, supported/unsupported contracts, fresh `28.2.0` publication, prompt phase/heartbeat visibility, secret-bearing child output, timeout/signal cleanup, and prior helper bounds/identity invariants.
- Initial ten-method recovery run passed nine methods in 145.212 seconds. One test incorrectly expected a script-hash rejection after advancing the source commit; the unchanged normal publisher correctly refused earlier at conflicting startup source identity. Corrected that expected refusal boundary without changing production guards or weakening the no-write assertion. The expanded focused rerun above passed.
- Full suite: `python3 -B -m unittest discover -s tests -p 'test*.py' -v`, from `server/`, passed all 66 methods in 1022.002 seconds. Log: `/tmp/opencode/ntr-task20-unittest.log`.
- `"$HOME/.cargo/bin/cargo" test --locked` passed all 37 Rust tests: 23 unit tests, 11 API integration tests, and 3 task-date integration tests. `"$HOME/.cargo/bin/cargo" clippy --all-targets --locked` passed without warnings; `"$HOME/.cargo/bin/cargo" fmt --check` passed. Logs: `/tmp/opencode/ntr-task20-cargo.log`, `/tmp/opencode/ntr-task20-clippy.log`, `/tmp/opencode/ntr-task20-fmt.log`.
- Passed shell syntax checks, Bash-only help, credential-free local `--validate`, `docker compose config`, Python AST parsing, README/docs local file-link checks, explicit version/Cargo/notes consistency checks, and parent/server staged/unstaged `git diff --check`. Source application files, Dockerfile, Compose, historical `0.2.6` notes, and app pointer have no task-20 changes.

## Limits

No actual production recovery, package association, publication, authenticated production API call, real-token access, Docker login/build/bootstrap, deployment, host administration, or remote cleanup was performed. Mutation verification used synthetic tokens, temporary real Git/bare remotes, and fake service/command ports only. Public upstream source reads are distinct from fake-port verification.

Installed-server provenance, current live package/registry state, account authority, live TLS/API/UI behavior, native AMD64/ARM64 container execution/persistence, and distributed-writer exclusion remain unverified. Custom/forked deployments require separate provenance/contract review. The independent ARM64 v8/F2 warning remains unresolved. Version `0.2.7` is prepared, not published. Real `v0.2.6` recovery requires separately approved use of independently trusted pins, pushed current tooling, sufficient token/account permissions, and exclusive writers; failed evidence must not be bypassed.

## Commits And Scope

Created fresh parent/server branches named `20-package-association-compatibility-logs`. Server implementation commit: `55ded61` (`Support verified package association recovery and release progress in 0.2.7`). The parent implementation commit records that pointer and this report. No app/application behavior, dependency, historical publication object, or `todo.md` changes were made.
