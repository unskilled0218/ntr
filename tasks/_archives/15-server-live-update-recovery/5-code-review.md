# Brooks-Lint Review

**Mode:** PR Review
**Scope:** Current branch versus `main`: parent `cfc353c..f056e14` and app submodule `e78d110..adcbc1b`. Inventoried all branch changes: two parent paths and 24 app paths. Reviewed substantive production changes, release configuration, documentation, and sampled the added tests, prioritizing asynchronous ownership, note safety, and recovery. The server pointer and sources are unchanged. Excluded generated `app/package-lock.json` and `app/src-tauri/Cargo.lock` from smell analysis and excluded the unrelated working-tree change in `todo.md` entirely.
**Health Score:** 80/100, using balanced deductions for one critical finding and one warning.
**Trend:** Stable at 80 compared with the previous PR Review record. That record reviewed the plan, not the implementation, so this is not a project-wide quality trend.

Changes requested: reconnect handling improves substantially, but a reproduced same-client save-ordering bug can silently revert newer note text.

## Findings

### Critical

**R1: Cognitive Overload — Context activation drops ownership of a live note save**

Symptom: `app/src/components/NotePane.tsx:85-100` resets `savingNote.current` at line 93 whenever its transport context becomes obsolete, even when `targetChanged` is false. `app/src/App.tsx:103-111` activates a new generation on every settings close, including an unchanged server. The old PUT continues, but `flushNote`'s single-flight check at `NotePane.tsx:122` no longer sees it. Late completion checks prevent old UI updates; they do not serialize requests already sent to the same destination.

Source: Code Complete — Defensive Programming and explicit invariants; A Philosophy of Software Design — Strategic vs. Tactical Programming. In-flight ownership is represented by a resettable flag tied to view generation rather than the outstanding write's actual lifecycle.

Consequence: One client can issue a newer note save before its older save settles. If the older request reaches storage later, it overwrites the newer text; the next live refresh treats the editor as clean and adopts the old version without a conflict. This is a regression of the client's own single-flight ordering, not the intentionally retained last-write-wins behavior between independent editors.

Remedy: Retain an outstanding write owner keyed to the actual note destination until that attempt settles. Invalidating read/view generations must not release a same-destination write slot. Before issuing another automatic PUT to that destination, wait for the previous attempt, reconcile current server state, and preserve any later draft. Keep genuinely different-target work separately scoped and prevent stale completions from updating current state. Add a regression that closes unchanged settings during a deferred PUT, types newer text, and resolves attempts adversarially; assert that only one same-destination PUT is outstanding and newer text is not silently replaced.

Evidence: A temporary component probe held the first save of `base1`, activated an unchanged server context, requested a note refresh, and typed `2`. Before the first save completed, two PUTs had been issued and the editor contained `base12`. Completing the older write last and delivering its note event produced `finalEditor: 'base1'` and `finalServer: 'base1'`. The single-flight assertion failed: expected one outstanding write, observed two.

### Warning

**R1: Cognitive Overload — Post-save continuation uses the editor after unmount**

Symptom: `app/src/components/NotePane.tsx:140-146` checks mount/lifetime/context before `await recovery.current?.resume()`, but line 145 calls `noteDirty()` and schedules work afterward without rechecking ownership. Unmount cleanup invalidates the lifetime and clears the editor ref while that recovery GET can still be pending. Cancellation correctly prevents the read from applying its result, but does not stop the outer save continuation.

Source: Code Complete — Error-Handling Discipline and Defensive Programming. An asynchronous boundary separates the lifetime guard from the guarded DOM access.

Consequence: Unmounting while the post-save drain awaits a remote note produces an unhandled `TypeError` from `readNoteText(null)`. The timer and blur paths discard `flushNote`'s promise, so this rejection is not handled at their call sites. The same missing revalidation can let obsolete save continuations make scheduling decisions for a replacement context.

Remedy: After the drain await, recheck mount state, captured lifetime, and captured transport ownership before reading the editor or scheduling another save. Make canceled save continuations settle without DOM access or follow-up work. Add a regression that queues an event during a PUT, completes the PUT to start the deferred GET, unmounts during that GET, then resolves it; assert no unhandled rejection or new timer/write.

Evidence: A second temporary probe followed that exact sequence. Vitest caught `TypeError: Cannot read properties of null (reading 'children')`, with the stack at `app/src/lib/caret.ts:16`, `NotePane.tsx:56`, and `flushNote` at `NotePane.tsx:145`.

## Verification and review coverage

- Re-ran `npm test` in `app/`: all 436 tests across 33 files passed. Expected disk-full and failed-reconciliation diagnostics were emitted by existing fixtures.
- Re-ran `cargo test --locked` in `app/src-tauri/`: 56 tests passed; the opt-in external-server test was ignored as designed. Its passing two-client restart result is recorded in `4-implemented.md`; it was not rerun in this review.
- Ran `./node_modules/.bin/vitest run --config /tmp/opencode/ntr-branch-review/vitest.config.ts` from `app/`. Temporary probes in `/tmp/opencode/ntr-branch-review/probes.test.tsx` reproduced one failed save-ordering assertion and one unhandled unmount rejection. They import the real component and use deferred transport promises; they do not alter implementation code or the tracked test suite.
- Applied the risk scan in guide order. Coordinated changes across the transport, panes, and composition root serve the requested feature; no unrelated change-propagation finding is warranted. Shared recovery has two real consumers, native transport seams are used in production, and boundary DTO/event constants are deliberate. No separate knowledge-duplication, speculative framework, dependency-cycle, or domain-model finding was established.
- The Quick Test Check found meaningful happy/sad-path, cancellation, transport-boundary, DOM, and native loopback coverage. Interaction assertions test observable subscription ownership; multi-assertion tests have coherent state-transition stories. The two missing temporal regressions are included in the remedies rather than counted again as duplicate coverage findings.
- GUI, device, and deployment-specific proxy/TLS checks remain the explicit limits recorded in `4-implemented.md`. They are not claimed as verified or treated as evidence for either reproduced finding.

## Summary

Fix same-destination write ownership before merging, then revalidate the post-save continuation after its recovery await. The change is over 500 lines and spans transport, orchestration, and editing state, which increases review and change-propagation cost despite its coherent feature scope; keep follow-up fixes narrowly focused on these two verified transitions. This stage records findings only: no implementation fixes, version changes, or edits to `todo.md` were made.
