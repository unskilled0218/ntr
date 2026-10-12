# Brooks-Lint Review

**Mode:** PR Review
**Scope:** Full review of `tasks/14-server-forgejo-image-release/2-plan.md` at `ad09322`, against `1-goal.md`, the user's amd64/arm64 requirement, and the server's current runtime/Compose configuration. This is a plan review, not a review of implemented release code.
**Health Score:** 90/100
**Trend:** 100 → 90 (−10) over the last three recorded PR Review runs; the preceding review covers a different task and scope.

The plan addresses both architectures and image-based deployment, but two operational boundaries need concrete contracts before implementation.

## Findings

### Warning

**Change Propagation (R2) — Docker credential isolation can change the builder being validated**

Symptom: Step 3 checks the selected builder's advertised platforms, then requires a temporary Docker configuration while only generally instructing the implementation to preserve context and builder settings. Buildx configuration defaults to `$DOCKER_CONFIG/buildx`, so changing `DOCKER_CONFIG` can lose the selected builder; platform availability alone also does not establish that the builder's driver can export a multi-platform index.

Source: A Philosophy of Software Design — Information Hiding and Leakage; The Pragmatic Programmer — Orthogonality.

Consequence: Credential cleanup can alter engine or builder selection, causing publication to fall back to a default builder or fail despite a passing platform preflight. Multi-node builders and user-installed plugins add hidden configuration dependencies that an implementation may patch by copying unrelated credentials or changing global state.

Remedy: Resolve and pin one existing supported builder, keep its Buildx state path explicit, preserve the engine and all required named contexts in the temporary configuration, and verify plugin visibility, driver, connectivity, and both platforms after isolation. Use a documented `docker-container` driver baseline, and add fixtures for changed Docker configuration, a non-default context, multiple node contexts, and an unsupported driver.

**Cognitive Overload (R1) — Release identity validation lacks a machine-readable inspection contract**

Symptom: Steps 3 and 6 require index existence classification, per-platform labels, revision matching, digest reporting, attestation filtering, and rerun decisions, but do not define how those values are obtained and bound together. Human-readable `imagetools inspect` output and raw manifest JSON do not expose the same data; OCI labels belong to each image configuration, not the index descriptor. The plan also leaves the missing-manifest error classification unspecified.

Source: Code Complete — Defensive Programming and Error-Handling Discipline; A Philosophy of Software Design — Deep Modules.

Consequence: Several branches may grow independent text parsers and inconsistent precedence rules. An implementation can validate only the host configuration, mistake an ARM64/v8 image for a missing platform, or report a digest unrelated to the pushed build while its mocked push tests still pass.

Remedy: Define one registry-inspection helper shared by preflight, reruns, and post-push checks. Parse machine-readable manifest/config JSON by immutable digest, validate both platform descriptors and configurations, accept the ARM64/v8 representation, explicitly filter attestation descriptors, and capture the build's index digest through `--metadata-file`. Define fail-closed missing-reference classification and test malformed, incomplete, conflicting, and mismatched-digest responses.

## Review Coverage

- R2 and R1 produced the warnings above. R3, R4, R5, and R6 produced no additional actionable findings: packaging, publication, and deployment belong to one feature; Dockerfile and Compose have distinct runtime responsibilities; generic API/file behavior remains unchanged; and the multi-platform requirement justifies Buildx.
- The warning count describes the submitted plan, before revision. Addressing the findings does not retrospectively change that diagnosis.
- The Quick Test Check is skipped because this stage changes planning documents only. The proposed behavioral and real-container verification was examined for feasibility, including the stated lack of Docker access.
- No `.brooks-lint.yaml` exists at the project root; default risks and balanced scoring apply.
- Technical references checked: Docker's [multi-platform build prerequisites](https://docs.docker.com/build/building/multi-platform/), [Buildx configuration variables](https://docs.docker.com/build/building/variables/#buildx_config), and [imagetools inspection JSON/config support](https://docs.docker.com/reference/cli/docker/buildx/imagetools/inspect/).

## Plan Revisions

- Step 3 now defines supported builder selection and post-isolation validation, including plugin/context/state preservation.
- Step 3 now specifies one digest-bound registry inspection contract, per-platform configuration validation, missing-reference classification, and build metadata comparison.
- Documentation, fixtures, live checks, acceptance criteria, and risks now cover those same boundaries. No implementation code was changed or container/registry publication attempted.

## Summary

Make builder selection independent of credential isolation and keep all registry identity decisions behind one digest-bound inspection helper. The revised plan retains the requested amd64/arm64 output and Compose deployment while making the previously ambiguous failure and rerun paths testable.
