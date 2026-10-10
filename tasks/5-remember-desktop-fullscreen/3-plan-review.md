# Brooks-Lint Review

**Mode:** PR Review
**Scope:** `tasks/5-remember-desktop-fullscreen/2-plan.md` at `8df1086`, checked against `1-goal.md`, desktop plugin registration, app data paths, server reconciliation, and installed `tauri-plugin-window-state` version `2.4.0`. Planning documents only.
**Health Score:** 94/100
**Trend:** 95 → 94 (−1) from the previous PR Review record; that record reviewed different implementation code, so the scores are not directly comparable.

The flags-first approach is appropriate, but the plan needs an actionable fallback for geometry capture and a fully isolated runtime fixture.

## Findings

### Warning

**R6 — Domain Model Distortion: Windowed geometry preservation has no concrete fallback [guided]**

Symptom: Step 3 recognizes that the plugin can capture fullscreen bounds, but instructs the implementer to resolve the policy and update the plan without specifying a correction. In the pinned plugin, `WindowExtInternal::update_state` excludes maximized/minimized windows but not fullscreen (`src/lib.rs:281–318`); the move and resize handlers likewise update cached geometry without a fullscreen guard (`src/lib.rs:455–495`). Restoring saved size before fullscreen can therefore establish monitor-sized windowed bounds on platforms where fullscreen is not also maximized.

Source: Domain-Driven Design — invariant ownership; A Philosophy of Software Design — Information Hiding and Leakage.

Consequence: The implementation can restore the fullscreen boolean while losing the separately required pre-fullscreen windowed bounds. A failed runtime check leaves the implementer without an executable remediation path and can turn a small native change into competing persistence mechanisms.

Remedy: Keep the flags-only change as the first path, but specify a conditional plugin-local correction if a runtime reproduction shows lost bounds. Patch all three geometry capture paths to preserve normal bounds while fullscreen, retaining close-time fullscreen capture and the existing state file. Describe a reproducible local crate override, focused policy tests, and dependency-lock verification rather than editing the installed Cargo cache or adding another persistence owner. Gate geometry acceptance on repeated native transition checks; source inspection establishes the missing guard, not a completed runtime reproduction.

### Suggestion

**R2 — Change Propagation: Runtime fixtures isolate configuration but leave data shared [quick-fix]**

Symptom: Step 2 suggests isolating `XDG_CONFIG_HOME` and then connecting the optional server. The app stores its selected data-path configuration and default task files under `app_data_dir`, separately from the plugin's `app_config_dir` (`app/src-tauri/src/paths.rs:58–88`). Connection/startup reconciliation can write local or remote tasks and notes (`app/src/api.ts:276–322`). Isolating only the window-state location does not isolate those writes.

Source: The Pragmatic Programmer — Orthogonality; Working Effectively with Legacy Code — Separation.

Consequence: Window-lifecycle verification can depend on existing user data and conflict settings, produce unrelated reconciliation prompts, or modify task/note data during a fullscreen test. Those side effects make the runtime checks less reproducible.

Remedy: Specify separate config, data, and cache roots for Linux test runs, fresh webview preferences, and a disposable server whose task/note/labels files use the same temporary fixture root. On other platforms, use an equivalent isolated test profile or explicit test-data path and document the resolved locations. Reuse each fixture across its relaunch sequence so isolation does not accidentally erase the state being tested.

## Summary

One warning and one suggestion yield `100 - 5 - 1 = 94`. Both findings are accepted and addressed in `2-plan.md`; this score describes the original reviewed plan, not a projected implementation score.

R1, R3, R4, and R5 yielded no additional findings: the primary change remains one desktop flag, the plugin owns persistence, and mobile dependency boundaries remain explicit. The Quick Test Check was skipped because no production or test code changes were requested; native runtime verification remains an implementation-stage requirement.

## Fix Summary

- Added a concrete, conditional plugin-local geometry correction and its test/lockfile verification steps.
- Expanded runtime fixture isolation to cover app data, webview preferences, and the optional server.
- Implementation code remains unchanged.
