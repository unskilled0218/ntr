# plan

- [scope](#scope)
- [Implementation Plan](#implementation-plan)
  - [Summary](#summary)
  - [1. Add safe release progress events](#1-add-safe-release-progress-events)
  - [2. Report long-running commands and target builds](#2-report-long-running-commands-and-target-builds)
  - [3. Cover progress and safety with offline tests](#3-cover-progress-and-safety-with-offline-tests)
  - [4. Document and validate the behavior](#4-document-and-validate-the-behavior)
- [Acceptance Criteria](#acceptance-criteria)
- [Risks And Decisions](#risks-and-decisions)

## scope

Add live, credential-safe terminal logs to the app release workflow entered through `app/scripts/release.sh`. Cover local checks, isolated setup/tests/builds, remote publication, and verification. Preserve standalone build behavior and all existing release safeguards. Do not change the app UI, server, release identity format, target selection, credentials, or recovery policy. This task writes a plan only; implementation belongs to a later task.

## Implementation Plan

### Summary

`app/scripts/release_publish.py::run()` captures all subprocess output in a private temporary file. The publisher currently prints only two broad phase messages plus its final result, so dependency installation, tests, builds, uploads, and verification appear silent. Add flushed, curated progress events and periodic elapsed-time messages while retaining private raw output. Do not stream arbitrary tool output: Android signing tools, dependency scripts, and Git can expose credentials.

### 1. Add safe release progress events

- Add one small progress helper in `app/scripts/release_publish.py` that writes consistently prefixed messages to stderr with `flush=True`. Keep existing final success messages on stdout and preserve CLI exit codes.
- Use fixed stage labels and validated release identifiers or artifact names only. Never interpolate command arguments, environment values, Git configuration, token/signing paths, HTTP headers, remote response bodies, or arbitrary exception text.
- Log stage starts and successful completions around local configuration checks, source validation, Forgejo preflight, remote release inspection, isolated checkout creation, dependency installation, JavaScript tests, Rust tests, artifact validation, and Android certificate checks. Announce a stage before its potentially blocking work.
- Log source/remote rechecks, tag creation/push, release creation, each asset upload, and each asset download verification. Include safe asset names and counts so users can distinguish successive transfers without dumping URLs or metadata.
- Explicitly announce the existing-release read-only verification branch. Print final verified success only after all existing verification and stability checks pass. Preserve partial-state warnings and never imply a failed write was rolled back.
- Keep `--validate` local and credential-free, and keep `--help` free of release execution. Do not add publication-oriented events or background work to either path.

### 2. Report long-running commands and target builds

- Extend the subprocess runner with an optional fixed progress label. Leave machine-readable Git and `apksigner` return values unchanged and keep their output private.
- For labeled long-running setup/test/build commands, use `subprocess.Popen` with the existing private temporary output file and a monotonic-clock polling loop. Emit a waiting message every 15 seconds with the stage label and elapsed seconds; do not wait for process completion before flushing progress.
- Preserve each caller's timeout, nonzero-exit refusal, UTF-8 decoding, and 16 MiB captured-output limit. Include the safe stage label in timeout/failure messages without replaying raw output. On timeout or interruption, terminate and reap the launched process and any descendants started for that labeled command so polling does not leave a build running.
- Keep a single combined `scripts/build-release.sh` invocation and its existing multi-target validation/build ordering. Add fixed desktop/Android build-start and build-complete markers in that script for standalone users, but do not expose its captured output through the publisher. In the publisher, label the combined build with the selected targets and report its elapsed time rather than claiming per-target progress it cannot observe.
- Do not add shell tracing, a verbose/raw-output switch, persistent log files, automatic retries, or upload concurrency.

### 3. Cover progress and safety with offline tests

- Extend `app/tests/test_release.py` using its temporary Git repositories, fake Forgejo service, and fake toolchain. Test ordered stage logs for successful publication, per-asset upload/verification, and the existing-release read-only branch.
- Test a labeled subprocess that emits a readiness signal and waits for the test to release it. Assert the start/waiting message is observable before process completion, including when stderr is redirected. Use controllable time or synchronization rather than real 15-second sleeps.
- Test quiet commands, nonzero exit, timeout, interruption cleanup, and successful machine-readable output. Check that failures name the stage, never print verified success, and retain nonzero CLI behavior.
- Keep and extend the existing secret-output regression: inject sentinel secrets into both stdout and stderr on successful and failed tool executions and assert neither reaches public logs. Also assert credentials, signing-file contents, and raw remote response bodies stay absent.
- Confirm `--validate` remains offline and secret-free, partial releases still stop before building, and repeat verification performs no build, signing access, or remote writes. Test standalone target markers with fake tools rather than real builds.

### 4. Document and validate the behavior

- Update `app/docs/forgejo-publishing.md` to describe stderr stage events, 15-second waiting updates, safe failure context, and the deliberate withholding of raw tool output. Update its current statement about tool-output privacy without weakening the credential policy.
- Update `app/docs/release-builds.md` with standalone target progress behavior and explain that publisher logs use curated events rather than raw compiler/test output. Maintain each document's table of contents.
- Run `python3 -B -m unittest discover -s tests -p 'test_release*.py' -v`, `bash -n scripts/release.sh`, `bash -n scripts/build-release.sh`, `bash scripts/release.sh --help`, and `bash scripts/release.sh --validate` from `app/`. Run `git diff --check` for both the app submodule and parent repository changes.
- Do not run actual publication, production API requests, dependency installation, signing, or full release builds to validate logging. Record any unavailable local prerequisites rather than installing system packages.

## Acceptance Criteria

- Normal app publication visibly announces the current major stage before blocking work, with flushed stderr output even under redirection.
- Quiet setup/test/build commands produce elapsed-time updates at 15-second intervals while running; each asset upload and verification is identified separately.
- Failures identify the relevant safe stage, exit nonzero, and retain existing partial-state guidance without exposing private output.
- Existing complete releases visibly follow the read-only verification path; validation remains local and offline.
- Logs contain no raw subprocess output, tokens, signing secrets, credential-bearing command arguments, headers, or remote response bodies.
- Release ordering, integrity checks, source isolation, target behavior, timeouts, and no-retry/no-rollback guarantees remain intact. Offline tests and shell syntax checks pass.

## Risks And Decisions

- Curated progress is the default and only new logging mode. Raw build output cannot be reliably sanitized because tools may transform or split secrets; this task does not promise compiler diagnostics in public logs.
- A combined build cannot expose exact per-target progress without a new trusted event channel. Keep the current build contract and report selected targets plus elapsed time instead of adding fragile parsing of tool output.
- Waiting events show that an operation is still pending, not that it is making measurable progress. No invented percentages or completion-time estimates are shown.
- Subprocess polling introduces lifecycle risks. Keep changes limited to labeled commands and require explicit timeout/interruption cleanup tests before accepting them.
- Existing local modifications in the `app` submodule and `todo.md` are user work. Do not overwrite them or include unrelated changes in commits. Do not publish releases as part of this task.
