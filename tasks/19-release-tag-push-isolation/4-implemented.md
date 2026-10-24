# Implementation

- [Changes](#changes)
- [Verification](#verification)
- [Limits](#limits)
- [Commits And Scope](#commits-and-scope)

## Changes

Fixed task 18's critical F1 by adding `--no-follow-tags` to the existing explicit, non-force release-tag push in `server/scripts/release.sh`. The bounded command wrapper, exact refspec, destination checks, pre-write guards, accepted-but-lost response reconciliation, and subsequent publication sequence are unchanged. The publisher does not edit user Git configuration or delete previously published tags.

Added `test_follow_tags_setting_cannot_expand_publication_or_completed_retry` in `server/tests/test_bash_release.py`. Its ordinary and lost-tag-response subcases enable repository-local `push.followTags=true` only after source setup, create a reachable unpublished annotated tag, and invoke the real Bash entry point through the unchanged real-Git command port. They compare actual bare-remote refs, require only the intended tag and peeled advertisement to be added, preserve source/pre-existing refs and the unrelated local tag, and verify configuration bytes/the enabled setting remain unchanged. Each case permits exactly one normal publication sequence, then verifies a completed retry performs no publication writes and preserves all refs/configuration.

Prepared server version `0.2.6`: updated canonical `VERSION`, Cargo manifest/package-lock mirrors, notes setting, README, consumer-contract assertions, and active release links. Added `server/docs/releases/0.2.6.md`; retained historical `0.2.5` notes, dependencies, Compose `latest`, and the template pin/version. Publication/verification documents explain the command-local hardening and regression boundaries. ARM64 v8 warning F2 remains unchanged and unresolved.

## Verification

- Red regression: `python3 -B -m unittest test_bash_release.BashReleaseTests.test_follow_tags_setting_cannot_expand_publication_or_completed_retry -v`, run from `server/tests/` before changing the production push. Both subcases reached successful publication but failed the remote-ref isolation assertion because `refs/tags/unrequested-tag` and its peeled advertisement were also published. One method ran in 19.386 seconds with two expected subtest failures. No unrelated early refusal caused the failure. Log: `/tmp/opencode/ntr-task19-red.log`.
- Green targeted run: the new method plus existing successful-publication/completed-retry, all-lost-writes, tag-only/release-only startup, source-destination preflight, and confirmed-tag-loss methods all passed: six methods in 109.081 seconds. Both new subcases also passed their completed read-only retries. Log: `/tmp/opencode/ntr-task19-targeted.log`.
- Full suite: `python3 -B -m unittest discover -s tests -p 'test*.py' -v`, from `server/`, passed all 52 methods in 723.151 seconds. Log: `/tmp/opencode/ntr-task19-unittest.log`.
- Passed: `bash -n scripts/release.sh`, `bash -n scripts/release-common.sh`, `./scripts/release.sh --help`, `./scripts/release.sh --validate`, `docker compose config`, Python AST parsing, README/docs local file-link checks, and explicit `VERSION`/Cargo/notes consistency checks. Compose retained non-root execution, loopback binding, storage, health check, and restart policy.
- After the operator installed Rust, `"$HOME/.cargo/bin/cargo" test --locked` passed all 37 Rust tests: 23 unit tests and 14 integration tests. `"$HOME/.cargo/bin/cargo" clippy --all-targets --locked` passed without warnings, and `"$HOME/.cargo/bin/cargo" fmt --check` passed. Tool versions: Cargo `1.99.1` and rustc `1.99.1`. Logs: `/tmp/opencode/ntr-task19-cargo-test.log`, `/tmp/opencode/ntr-task19-clippy.log`, and `/tmp/opencode/ntr-task19-fmt.log`.
- Parent/server `git diff --check` and server staged diff checks passed. Source application files, Dockerfile, Compose, fake command port, and app pointer have no task-19 changes.

## Limits

Initial `cargo test --locked`, `cargo clippy --all-targets --locked`, and `cargo fmt --check` attempts each failed with exit `127`: `cargo: command not found`; rustc was also absent. The operator subsequently installed the toolchain. All three checks then passed using the explicit user-local Cargo path, resolving that verification blocker. The agent did not install tools or perform privileged preparation.

No real image build, runtime smoke check, registry login, or live publication ran. Native AMD64/ARM64 execution, non-root/API/persistence smoke checks, live registry/TLS behavior, deployed API compatibility, account permissions, and distributed-writer exclusion remain unverified. The fake-port suite uses synthetic credentials and temporary real Git remotes; it does not certify live release readiness. Version `0.2.6` is prepared, not published. The separate ARM64 v8 warning F2 remains outstanding.

## Commits And Scope

Created fresh parent and server branches named `19-release-tag-push-isolation`. Server implementation commit: `7bc9b8c` (`Isolate release tag pushes from follow-tags for server 0.2.6`). The parent implementation commit records that pointer and this report. No real source push, remote tag/release/package mutation, deployment, existing-artifact cleanup, application behavior change, dependency upgrade, or `todo.md` edit occurred. The parent retains its unrelated pre-existing `todo.md` modification outside implementation commits.
