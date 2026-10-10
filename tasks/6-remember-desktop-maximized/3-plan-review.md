# Brooks-Lint Review

**Mode:** PR Review
**Scope:** `tasks/6-remember-desktop-maximized/2-plan.md` at `8fba5bc`, checked against `1-goal.md`, the local window-state plugin, and the installed Linux Tao window request/state implementation. Planning documents only.
**Health Score:** 94/100
**Trend:** Stable at 94 compared with the preceding PR Review record; that record reviewed a different task plan.

The plan addresses normal/maximized/fullscreen coordination, but timeout completion and failed mode queries need explicit persistence rules.

## Findings

### Warning

**R6 — Domain Model Distortion: Timeout can treat issued mode requests as completed restoration [guided]**

Symptom: Step 2 requires confirmed maximization before fullscreen, yet its timeout callback applies requested modes and clears the pending transition at the deadline. Issuing a native request is not confirmation: Linux Tao queues `WindowRequest::Maximized` and reads observed maximization from an atomic state separately (`tao-0.35.3/src/platform_impl/linux/window.rs:617–633`). The plugin currently suppresses intermediate geometry only while its pending marker is set (`app/src-tauri/vendor/tauri-plugin-window-state/src/lib.rs:346–347`, `511–514`, `546–549`). The proposed timeout path can bypass the ordering and protection required by the normal path.

Source: Domain-Driven Design — invariant ownership; A Philosophy of Software Design — Information Hiding and Leakage.

Consequence: A slow or constrained native transition can enter fullscreen before maximization settles, or release geometry capture while startup samples are still in flight. The fallback can reproduce the wrong underlying mode or lost normal bounds that the plan otherwise guards against.

Remedy: Define the timeout as an input to the same phased restore controller. It may replace an impossible exact-size wait with confirmed usable bounds, but it must not batch maximize/fullscreen calls or equate successful dispatch with completion. Clear protection only after observed mode confirmation or an explicit terminal failure that preserves cached normal bounds. Specify cancellation/stale-attempt handling and deterministic cases where maximization remains unconfirmed at expiry, constrained geometry advances, and late callbacks follow failure or close.

### Suggestion

**R6 — Domain Model Distortion: Unknown geometry eligibility can become false mode flags [quick-fix]**

Symptom: The plan replaces the move handler's constant maximized false with a native query, but does not specify failed-query behavior. Existing resize/minimized queries use `unwrap_or_default()` (`app/src-tauri/vendor/tauri-plugin-window-state/src/lib.rs:507`, `537`, `543`), and `can_capture_geometry` represents unknown fullscreen explicitly but accepts plain maximized/minimized booleans (`309–310`). Following the existing pattern would turn a failed maximized query into false and authorize a normal-position sample.

Source: Code Complete — Defensive Programming and explicit error paths; Domain-Driven Design — invariant ownership.

Consequence: An unavailable native mode observation can overwrite saved normal bounds or clear the remembered maximized mode. Unknown state is not evidence that the window is normal.

Remedy: Require confirmed non-fullscreen, non-maximized, and non-minimized observations before geometry capture. Extend the policy helper's input representation or gate the event handler on successful queries; on failure, skip the sample and retain cached mode/bounds. Preserve deliberate platform-specific behavior separately from error defaults. Add cases with each observation independently unavailable and successful normal observations afterward.

## Summary

One warning and one suggestion yield `100 - 5 - 1 = 94`. Both findings are accepted and addressed in `2-plan.md`; the score describes the reviewed plan before correction.

R1–R5 produced no additional actionable findings: the extra sequencing addresses a known native sizing interaction, the plugin remains the persistence owner, and the test/release scope is bounded. The Quick Test Check was skipped because this stage changes only planning/review records; no runtime test or implementation fix was performed.

## Fix Summary

- Replaced unconditional timeout completion with phased, observation-driven advancement and explicit failure handling.
- Made failed mode observations preserve cached geometry and maximized state.
- Expanded planned regression checks for deadline expiry, late callbacks, and unknown query results.
- Implementation code remains unchanged.
