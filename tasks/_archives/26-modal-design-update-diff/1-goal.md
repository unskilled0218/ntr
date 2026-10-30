# Modal design and update diffs

- [Modal design and update diffs](#modal-design-and-update-diffs)
  - [command](#command)
  - [goal](#goal)

## command

Match project-rename and remote-update modal styling to existing project filters and other dialogs. Show a diff for remote updates. Simplify `Rename project` to the original name and a new-name input, dismiss it after renaming, and keep the underlying create-task project selector visible when the rename dialog is dismissed.

## goal

Make rename and remote-update dialogs visually consistent with existing selector modals. Preview remote changes as a diff before approval. Show `Rename project`, `Original`, and a new-name input in the simplified rename dialog; close it after a successful rename while preserving drafts and safe error recovery. Opening or dismissing rename from the create-task project selector must leave that selector available underneath instead of closing it too.
