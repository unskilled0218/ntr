# Brooks-Lint Health Dashboard

- [Module dependency graph](#module-dependency-graph)
- [Top findings](#top-findings)
- [Recommendation](#recommendation)

**Mode:** Health Dashboard
**Scope:** Latest `tasks/21-remove-priority/2-plan.md` and relevant task parsing and edit paths; this is not a whole-project audit.
**Composite Score:** 98/100

| Dimension | Score | Top finding |
| --- | --- | --- |
| Code Quality | 95/100 | The proposed input guard can block unchanged existing descriptions. |
| Architecture | 100/100 | No additional finding in the inspected boundaries. |
| Tech Debt | 100/100 | No additional finding in the inspected plan. |
| Test Quality | 95/100 | The tests omit valid existing descriptions beginning with a priority-shaped token after a date. |

Balanced scoring assigns one warning each to Code Quality and Test Quality. The weighted score is 97.75, rounded half-up to 98. Scores concern this plan review only. No project configuration was found. History is not modified for this document-only review.

## Module dependency graph

```mermaid
graph TD
  UI[Task UI] --> Serializer[Task serializer]
  UI --> Transport[Client transport]
  Serializer --> Transport
  Transport --> Local[Local commands and store]
  Transport --> Server[Server API and store]
  Local --> LocalModel[Local task model and file]
  Server --> ServerModel[Server task model and file]
```

## Top findings

### Warning: The new guard blocks some existing task edits

**Symptom:** `2-plan.md:26` rejects every submitted description beginning with a complete `(A)`–`(Z)` token, except a hidden legacy prefix recovered from `raw`. The current parsers in `app/src-tauri/src/task.rs:49-69` and `server/src/task.rs:46-64` accept `2026-06-01 (A) call` as a creation date followed by description `(A) call`; the token is not a hidden prefix in that line.

**Source:** Software Engineering at Google — Backward compatibility.

**Consequence:** An unchanged existing task can no longer be saved, even when the user only changes its due date or project. Rejecting this description is broader than preventing new ambiguous leading file tokens and conflicts with preserving normal edits.

**Remedy:** Define a safe exception or serialization rule for existing descriptions whose priority-shaped token appears after lifecycle metadata. Specify how unchanged and changed descriptions are handled for active and completed tasks, including lines with and without dates. Never silently reclassify or discard the text; if the format cannot safely represent a case, fail visibly and explain the limitation.

### Warning: The test matrix misses the existing-description regression

**Symptom:** `2-plan.md:48` tests new submissions beginning `(A)` and an existing hidden legacy prefix, but not a valid existing line where `(A)` begins the description after a parsed date.

**Source:** How Google Tests Software — Change Coverage.

**Consequence:** Tests can pass while users cannot save otherwise valid existing tasks after the upgrade.

**Remedy:** Add real local and HTTP edit/save/reload cases for `2026-06-01 (A) call` and `x 2026-06-02 2026-06-01 (A) call`, including unchanged descriptions and changes to unrelated fields. Assert both lifecycle dates and visible description survive. Include an undated case and document its distinct ambiguity.

The previous review's findings about ambiguous new input and repeated `pri:` merging now have explicit policies and test cases. The remaining issue is the effect of the new guard on already valid data. No tests were run for this document-only review.

## Recommendation

Revise the edit guard and its persistence tests before implementation. Preserve the distinction between a leading legacy prefix and priority-shaped text that already follows task dates.
