# goal

## command

- update UI
  ```
  Do something
  +cart due:2026-10-12 created:2026-10-10 updated:2026-10-11
  ```

- `created` field disappear when edit. always dispaly `created`
- after edit display `updated`

## goal

Update task rows to show description text on the main line and project/date metadata on the smaller line beneath it, following the supplied example. Use space-separated project tokens followed by `due:YYYY-MM-DD`, `created:YYYY-MM-DD`, and, after a successful edit, `updated:YYYY-MM-DD` for available values.

Always retain and display an existing creation date, including after edits. Add the latest successful edit date alongside it; both `created` and `updated` must remain visible together. Keep original creation data and persist update metadata through reload, restart, and subsequent edits in local and server modes.

Preserve priority, completion information, project associations, hidden contexts, and task actions. Dedicated project/date metadata should not also appear as duplicate tokens in the main description; unrelated description and tag content retain their existing behavior.

## project findings

- `app/src/components/TaskItem.tsx` currently orders metadata as `created <date>`, `done <date>`, then projects, separated by middle dots. It has no due-date or updated-date metadata branch, so its formatting differs from the requested example.
- TaskItem uses `bareDescription` with an empty tags map. Projects/contexts are hidden from the main text, but due and other tags remain there. Moving due/update metadata below the description requires deliberate token handling that preserves unrelated text.
- `app/src/style.css` already renders `.meta` as a smaller, muted block below the main task text, providing the existing two-line presentation boundary.
- `app/src/components/EditTaskModal.tsx` strips structured tags from the editing text and uses `composeEditedTask` in `app/src/labels.ts` to save whole task lines. The serializer intends to retain creation/completion dates and reconstruct due/project fields, but generates no update date. Investigate the reported creation-date loss across edit, save, response, and reload rather than assuming it is only a display issue.
- `app/src/api.ts` exposes creation/completion dates and generic tags in the shared task shape, without a dedicated update-date field. The local store replaces tasks from the submitted todo.txt line and persists before swapping cached state. The implementation plan must choose a durable update-date representation compatible with local/server task data and later edits.

## acceptance criteria

- A row with the example values displays `Do something` above `+cart due:2026-10-12 created:2026-10-10 updated:2026-10-11`, using the existing smaller metadata presentation. Multiple projects appear before the date fields.
- A task's original creation date remains unchanged and visible after first and repeated edits. Updated metadata adds to the created display rather than replacing it.
- A successful saved edit records/displays the latest edit date. Opening/cancelling Edit and failed saves do not commit new update metadata or change creation metadata.
- Project, due, creation, and update metadata survive reload/restart and subsequent edits in both local and server modes. Active and completed rows retain applicable completion information and existing lifecycle behavior.
- Dedicated project/date tokens appear in the metadata line without duplicate housekeeping text in the main description. Priority, unrelated tags/text, and hidden-context behavior remain intact.
- Omit unavailable date fields without empty labels or invented historical dates. Legacy tasks without update metadata remain readable and keep any existing creation date visible.
- Add regressions for the requested metadata ordering/format, due-token relocation, creation-date preservation, first/repeated/cancelled/failed edits, legacy tasks, and persistence/reload. Record relevant frontend and storage/transport checks plus available mobile/desktop visual verification during implementation.
