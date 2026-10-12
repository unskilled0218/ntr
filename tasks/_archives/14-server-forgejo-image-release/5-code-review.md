# Brooks-Lint Review

**Mode:** PR Review
**Scope:** Branch `14-server-forgejo-image-release` against local base `main`, merge base `10bd534a30ebafa77a1072b98c0d1240e4f2c633`, through `9f04024`. The parent changes the server gitlink and adds `4-implemented.md`; the server advances from `317b447` to `d4d91e4` in one implementation commit. All changed files were inventoried; this is a sampled, risk-focused review of the 1,018 added and 32 removed server lines, emphasizing credential isolation, subprocess termination, registry identity, packaging, deployment, and tests.
**Health Score:** 85/100
**Trend:** 90 → 85 (−5) over the last three recorded PR Review runs; prior runs cover different scopes, including the task plan.

The release workflow has strong digest-bound validation, but automatic credential-helper selection violates its temporary-login isolation guarantee.

## Findings

### Critical

**Change Propagation (R2) — Docker can write the release token into the user's native credential store**

Symptom: `server/scripts/image_release.py:199–205` creates an isolated Docker configuration without authentication entries or an explicit credential backend. `release()` then runs `docker login` at line 346. Docker CLI's `LoadDefaultConfigFile()` detects a platform-default credential helper when `ContainsAuth()` is false. On Linux, this can select `docker-credential-pass` or `docker-credential-secretservice`; the helper's credential store is outside `DOCKER_CONFIG`. Omitting the original `credsStore` therefore does not ensure file-only storage. The fake login in `server/tests/release_script_test.py:123–130` always writes `auths` directly and cannot reveal this behavior.

Source: A Philosophy of Software Design — Information Hiding and Leakage; The Pragmatic Programmer — Orthogonality.

Consequence: On a host with a native helper, publication can leave the Forgejo token in the user's persistent credential store after the temporary directory is removed. It can also replace an existing login for the same registry. An unavailable or locked native store can fail an otherwise valid release. This contradicts the documented temporary-login and original-credential preservation guarantees.

Remedy: Make the isolated configuration explicitly use temporary file-backed authentication and prevent Docker's automatic helper detection, using a Docker-supported configuration that satisfies `ContainsAuth()` without selecting a native helper. Verify both login and subsequent Buildx authentication with the real Docker CLI and a disposable credential-helper spy. Assert that no persistent helper receives store/erase operations and that existing registry credentials remain intact after success and failure.

## Review Coverage

- Reviewed changed server files: `.dockerignore`, `.gitignore`, `Cargo.toml`, `Dockerfile`, `README.md`, `docker-compose.yml`, `docs/docker-compose.md`, `docs/image-release.md`, `scripts/image_release.py`, `scripts/release.sh`, and `tests/release_script_test.py`, plus the parent gitlink and implementation report.
- Skipped generated `server/Cargo.lock` for decay analysis; inspected its diff to confirm that only the server package version changes from `0.2.1` to `0.2.2`.
- R2 produced the credential-boundary finding. R1, R3, R4, R5, and R6 produced no additional actionable findings. The long isolation helper carries several policies, but its current behavior is sufficiently explicit to avoid a separate length-only finding. Packaging, release publication, and Compose changes belong to the same feature. DTO/configuration records and boundary command fakes are appropriate here.
- The Quick Test Check found substantial success/error coverage and externally observable command, output, cleanup, and digest assertions. The native credential-helper gap is included in the credential finding rather than counted twice. Multiple assertions describe coherent scenarios, and command seams are justified by engine/registry nondeterminism; no separate Mock Abuse or Test Obscurity finding is warranted.
- No `.brooks-lint.yaml` exists at the parent project root; default risks and balanced scoring apply. One Critical deducts 15 points.

## Verification

- `bash -n scripts/release.sh`: passed in `server/`.
- `python3 -m unittest discover -s tests -p 'release_script_test.py' -v`: passed all 13 test groups, including scenario matrices, in approximately 21 seconds.
- `git diff --check 317b447 d4d91e4`: passed in `server/`.
- Docker is available at review time, unlike the implementation environment described in `4-implemented.md`. `docker version` reports client/server `29.9.0`; `docker buildx version` reports `v0.38.0`.
- The exact `BUILDER_FORMAT` template succeeds against real `docker buildx ls`, including the duplicated default builder/node wrapper that the code deduplicates. The available builder uses the intentionally unsupported `docker` driver; no `docker-container` builder was created or bootstrapped.
- `docker compose config`: passed with defaults. A second configuration check passed with overridden digest reference, `NTR_BIND=0.0.0.0`, `NTR_PORT=9000`, `NTR_UID=1234`, and `NTR_GID=2345`; the resolved image, bind address, port, and user match those values.
- A disposable subprocess probe using the actual `Commands.run()` and SIGTERM handler returned in approximately 0.01 seconds despite a child attempting to sleep for two seconds. `subprocess.run()` kills the child when the handler raises. An initial direct-`Popen` probe did not model this wrapper and was rejected as evidence; no termination finding is retained.
- Checked Docker CLI [configuration loading](https://github.com/docker/cli/blob/v29.0.0/cli/config/config.go), [default helper detection](https://github.com/docker/cli/blob/v29.0.0/cli/config/credentials/default_store.go), and [Linux helper selection](https://github.com/docker/cli/blob/v29.0.0/cli/config/credentials/default_store_linux.go). These establish the credential finding; no real token or persistent credential store was used.
- Checked Buildx 0.13 [builder formatter](https://github.com/docker/buildx/blob/v0.13.0/commands/ls.go), [builder/node JSON serialization](https://github.com/docker/buildx/blob/v0.13.0/builder/node.go), and [manifest/config formatter](https://github.com/docker/buildx/blob/v0.13.0/util/imagetools/printers.go) against the script's boundary assumptions.
- No container build/run, Forgejo push, or live absent-tag classification was performed. The implementation's native Rust test/smoke results were read rather than rerun because this branch does not modify Rust behavior. ShellCheck remains unavailable.

## Summary

Fix persistent credential-store escape and verify the authentication boundary with a real Docker CLI and disposable helper. The large diff merits focused boundary review, but the file count reflects one coherent packaging feature rather than unrelated change propagation. Existing tests and real Compose checks provide useful evidence; image runtime, both architectures, and live registry behavior still need verification.
