# Brooks-Lint Review

**Mode:** PR Review
**Scope:** Stacked branch `6-remember-desktop-maximized` relative to its creation base, `5-remember-desktop-fullscreen`: parent `859767a..a515b79` (app pointer and implementation report), including app `e77c512..8e927a9` (10 changed files). Reviewed all changed files, with deeper analysis sampled around mode capture, phased restoration, callbacks, and tests. Generated lockfiles were excluded from design diagnosis; their changes contain only the app version bump.
**Health Score:** 90/100
**Trend:** 94 → 90 (−4) from the previous PR Review record; that record reviewed the plan, so the scopes are not directly comparable.

The normal Linux restart flows are verified, but two unprotected transition cases remain in maximized-state capture and position restoration.

## Findings

### Warning

**R6 — Domain Model Distortion: Confirmed maximization is discarded while fullscreen**

Symptom: `WindowState::observe_modes` updates maximization only when fullscreen is false (`app/src-tauri/vendor/tauri-plugin-window-state/src/lib.rs:176–189`). Protecting a remembered true value from platforms that report maximized false while fullscreen is reasonable, but the same condition also discards an observed true value. With cached `maximized: false` and a first combined observation `{ fullscreen: true, maximized: true, minimized: false }`, the method stores fullscreen true and leaves maximized false. Close/exit capture uses that same method (`lib.rs:503–506`), so a later snapshot cannot recover the positive observation while the window remains fullscreen.

Source: Domain-Driven Design — invariant ownership; The Mythical Man-Month — Conceptual Integrity.

Consequence: If maximize/fullscreen changes are coalesced or the fullscreen query becomes true before a non-fullscreen maximize event is sampled, a combined mode can be persisted as fullscreen-only. After relaunch, leaving fullscreen returns to normal instead of the user's maximized mode. The existing test seeds a non-fullscreen maximized observation first (`lib.rs:788–803`), and the recorded native workflow waits between transitions, so both miss this capture sequence.

Remedy: In `observe_modes`, accept a confirmed maximized true observation even while fullscreen, while continuing to ignore fullscreen-only false/unknown observations that would erase the underlying mode. Add a cache/serialization case starting with cached false and receiving a combined true/true observation, plus rapid native maximize/fullscreen verification without a deliberate inter-transition wait. The policy must distinguish positive evidence of maximization from absence of evidence while fullscreen.

### Warning

**R6 — Domain Model Distortion: Geometry completion excludes requested position**

Symptom: Restoration dispatches a position request (`lib.rs:419–430`), but `Observation` and `Attempt` contain only size and mode values (`app/src-tauri/vendor/tauri-plugin-window-state/src/restore.rs:13–19`, `48–57`). The Geometry phase advances when size matches, without representing whether the requested position has applied (`restore.rs:78–106`). Linux Tao queues position requests separately and exposes observed position separately (`tao-0.35.3/src/platform_impl/linux/window.rs:449–465`); request success is not an observation of placement.

Source: Domain-Driven Design — invariant ownership; A Philosophy of Software Design — Information Hiding and Leakage.

Consequence: If placement settles later than sizing, maximization/fullscreen can start with an old normal origin. The cached requested coordinates do not guarantee the native window manager retained that origin for unmaximize/fullscreen exit, so normal-position preservation can fail even while saved size is correct. This review confirmed the missing gate at policy level: the actual `Attempt::next` returns `Maximize(true)` for matching size while the conceptual current position is (140, 140) rather than requested (220, 180). This is not a newly reproduced live window-manager failure; the gap follows from the unrepresented position observation and asynchronous request boundary.

Remedy: Carry an optional requested normal position and observed native position through the existing restore policy. When a supported position request is made, confirm placement alongside size before changing modes. When monitor availability or native placement constraints require an OS-selected location, use an explicit bounded placement fallback rather than assuming the requested origin applied. Add a controlled sequence where size arrives before position and verify no mode request is issued until placement is confirmed or the defined fallback is accepted. Keep the existing persistence owner and JSON format.

## Verification And Quick Test Check

- Confirmed the parent branch's creation base from its reflog and matching branch ancestry. The app implementation is one commit on top of the fullscreen branch; the earlier fullscreen implementation is inherited context, not counted as a new change in this review.
- `cargo test --locked -p tauri-plugin-window-state`: passed, 12 tests plus documentation target.
- A temporary standalone Rust probe imports the actual `src/restore.rs` module and confirms the size-ready policy advances to maximization without a position input. No repository source or test file was changed for the probe.
- The combined true/true capture result is confirmed by tracing the existing `observe_modes` condition. Rapid native transition failure was not reproduced during this review.
- `git diff --check 5-remember-desktop-fullscreen...HEAD`: passed.
- The implementation report records 42 app-native tests, the desktop build, Android ARM64 compilation, and local/server Linux/Muffin lifecycle verification at app commit `8e927a9`. Those broader checks were not repeated in this review. Known baseline formatting mismatches remain outside the branch's implementation changes.
- Tests cover mode combinations, unknown queries, deadlines, callback identities, geometry protection, and serialization. Missing positive combined-mode capture and delayed-position observations are included in the findings above rather than counted again as test findings.
- No separate Mock Abuse or Test Obscurity finding is justified: policy tests assert actions and persisted/cache invariants with controlled observations/time, and temporary production harness hooks were removed.

## Summary

Two warnings yield `100 - 2 × 5 = 90`. Address positive maximized-state capture and placement confirmation before treating combined-mode and normal-position preservation as complete; no fixes were implemented in this stage.

The 955-line app diff is a size-based Change Propagation signal and deserves focused review, but it stays within the native persistence feature, its tests, and release records. R1–R5 yielded no additional actionable findings: the phased policy remains separate from native effects, callbacks share one transition controller, and no new dependency cycle or unrelated subsystem coupling was introduced.
