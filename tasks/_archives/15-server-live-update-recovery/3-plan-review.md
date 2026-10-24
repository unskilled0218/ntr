# Brooks-Lint Review

**Mode:** PR Review
**Scope:** `tasks/15-server-live-update-recovery/2-plan.md` at `4e223fd`, checked against `1-goal.md` and the current app subscription, note, settings, transport, and startup reconciliation paths. This is a plan review, not an implementation review.
**Health Score:** 80/100 before revisions, using balanced deductions for four warnings.
**Trend:** Previous PR Review score was 85; this score is 80. The scopes differ, so this is not a project-wide quality trend.

The ownership and reconnect design is sound, but four missing transition rules could preserve lost updates or redirect stale work after a settings change.

## Findings

### Warning

**R1: Cognitive Overload — Note reads and autosave lack one arbitration rule**

Symptom: Step 4, especially original lines 52–57, defers reads during saves and drains after completion, but does not block an already scheduled autosave or blur save while a remote read is pending or running. It also leaves failed drains and revision invalidation unspecified. The current `flushNote` guards saving, composition, and conflict, but not reconciliation.

Source: Code Complete — Defensive Programming and explicit invariants; A Philosophy of Software Design — Strategic vs. Tactical Programming.

Consequence: A known incoming update can be overwritten before its GET finishes, or a failed GET can cause either silent loss or an indefinite busy drain. Invalidating reads for ordinary typing can starve reconciliation while the user edits.

Remedy: Specify one note transition policy: known pending reconciliation blocks automatic writes; a read uses current editor text; save/baseline or transport changes invalidate results, while ordinary typing is classified rather than discarded. Failed reads retain pending work and retry with delay. After a successful drain, autosave resumes only when no conflict remains. Explicit conflict choices remain the only overwrite authorization.

**R2: Change Propagation — Read epochs do not bind deferred side effects to their server**

Symptom: Step 5, original lines 62–65, offers either a React `connectionKey` or a shared epoch, without specifying the synchronous invalidation point. It protects pane reads but excludes startup reconciliation and deferred saves. `App.onSettingsClose` invokes pane handles before the new key renders; `api.ts` rereads global settings inside multi-step work, and startup conflict records contain no server identity.

Source: A Philosophy of Software Design — Information Hiding and Leakage; The Pragmatic Programmer — Orthogonality.

Consequence: A delayed save completion can rearm a write using the new URL, and a startup reconciliation or old conflict choice can write server A's content to server B. Response guards alone do not prevent these side effects.

Remedy: Choose a single captured transport context owned by `api.ts`, with a synchronous activation generation and immutable URL/certificate snapshot. Carry it through the affected reads, note saves, label persistence, startup reconciliation, and conflict choices. Invalidate before settings-close reloads, suppress stale completions and new side effects, and retain dirty note drafts without automatically uploading them to a new target. Do not redesign task mutation semantics or conflict strategies.

**R1: Cognitive Overload — Reconnect reads can still be dropped permanently**

Symptom: Step 3 refreshes once on `connected`, but the final risk at original line 106 preserves existing read failures without a retry. A server can accept the SSE stream while `/api/tasks` or `/api/note` temporarily fails; the stream then remains healthy with no later mutation. Existing ordinary HTTP reads have no finite response deadline.

Source: Code Complete — Error-Handling Discipline; Working Effectively with Legacy Code — Sensing and Separation.

Consequence: The client remains stale after reconnect even though the stream recovered, violating the explicit requirement to recover missed changes without another event. A hung read can prevent a single-flight reconciliation path from progressing.

Remedy: Keep recovery pending per resource until its read succeeds. Retry failed reads with bounded backoff and a finite GET deadline, cancel retries on new transport/unmount, and preserve visible error state without clearing the editor or list. This is event-triggered recovery retry, not continuous polling. Test a healthy stream with a failed first GET followed by recovery and no new change event.

**R1: Cognitive Overload — Silent stream interruption is excluded from recovery**

Symptom: Original line 104 defers heartbeat detection, although the goal requires automatic recovery after network interruption. The server already emits `KeepAlive` comments, but the planned bridge retries only when the transport reports failure or EOF.

Source: Code Complete — Defensive Programming and explicit failure handling.

Consequence: A half-open TCP connection can wait indefinitely and never enter the reconnect loop. Restoring connectivity does not guarantee the old socket will report an error or receive future changes.

Remedy: Add an established-stream inactivity deadline comfortably above the existing server heartbeat interval. Reset it for all incoming bytes, including comment heartbeats. Timeout enters the same reconnect/backoff loop and is canceled by disconnect. Test a silent accepted stream and a healthy comment-only stream with deterministic time.

## Summary

All four findings are addressed in the revised `2-plan.md`: note arbitration, captured transport ownership, per-resource recovery retries, and stream inactivity detection. The revised plan has no remaining findings from this pass; its scoped planning score is 100/100, not a claim about implementation correctness.

R1–R6 were considered in the guide's order. Coordinated edits within this live-sync boundary, cross-language wire DTOs, and a transport test seam are justified; no separate duplication, speculative framework, dependency-cycle, or domain-model finding is warranted. The Quick Test Check was skipped because this change is documentation-only; planned regressions were checked for coverage of the identified transitions instead.

No implementation code or `todo.md` was modified. Tests were not rerun for this document review.
