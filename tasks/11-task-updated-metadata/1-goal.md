# goal

## command

- `created` field disappear when edit. after edit show `updated`

## goal

After a successfully saved task edit, show `updated <date>` in the small task metadata line instead of `created <date>`. Use the date of the latest successful edit, with formatting consistent with existing date metadata. Tasks without an edit date continue to show their available creation date.

Retain the original creation date in task data while changing which date the row displays. Persist edit-date metadata so the updated label remains correct after reload, restart, and subsequent edits in local and server modes. Preserve completion dates, priority, projects, contexts, and task actions.

## project findings

- `app/src/components/TaskItem.tsx` currently renders only creation and completion dates plus projects in its metadata line. There is no updated-date display branch.
- `app/src/api.ts` defines the shared task DTO with `creation_date`, `completion_date`, and arbitrary tags, but no dedicated update-date field. The app-native and server DTOs use the same shape.
- `app/src/components/EditTaskModal.tsx` saves a whole task line through `composeEditedTask` in `app/src/labels.ts`. That helper retains creation/completion dates but currently generates no edit-date metadata. The edit form strips parsed tags from its description input, so any chosen update-date representation must survive subsequent edit serialization deliberately.
- Both `app/src-tauri/src/store.rs` and `server/src/store.rs` replace task content by parsing the submitted todo.txt line. Their update paths do not currently stamp an edit date. The stores persist before swapping cached state, providing the existing successful-write boundary.
- Server-mode updates back up the server's canonical raw task text locally through `app/src/api.ts`. Update-date persistence must remain compatible with raw-file reloads and that shared storage path.
- Task-row rendering currently retains general tags in the main description. If update metadata is represented as a tag, its display needs explicit handling so it appears as metadata without adding duplicate housekeeping text to the description. The exact storage representation belongs in the implementation plan.

## acceptance criteria

- An unedited task with a creation date shows the existing `created <date>` metadata.
- After a successful edit save, the row replaces that created display with `updated <latest edit date>`. A later successful edit refreshes the update date rather than displaying the original creation date as an edit date.
- The original creation date remains intact in task data. Updated metadata survives reload/restart and further edits in both local and server modes.
- Opening or cancelling Edit and a failed save do not change the displayed date or commit a new update date.
- Active and completed tasks support the same update-date display rule. Completion dates, priority, projects, contexts, and existing completion/reopening/edit/delete behavior retain their contracts.
- Legacy tasks without update metadata remain readable and show available creation metadata. A task without a creation date can still show its valid update date after a successful edit.
- Updated metadata appears in the small metadata line without duplicating an internal date token in the main description or hiding unrelated description/tag content.
- Add meaningful regression coverage for first/repeated edits, cancelled/failed saves, legacy tasks, original creation-date preservation, and persistence/reload. Record relevant frontend and storage/transport verification during implementation.
