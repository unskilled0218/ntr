# Goal

- [Command](#command)
- [Goal](#goal-1)
- [Suggestions](#suggestions)

## Command

- Cancel from add/remove list go back to list, not dismiss
- handle blue borderline from list. some of borderline blocked by other view?
  - Add list button
  - Rename list button
- Remove `Changes this draft only.` from add list
- Change message from Remove list
  - Remove <list>

## Goal

Canceling Add list or Remove list should return to the originating list picker rather than dismissing the whole picker flow. Keep the picker's selection and unsaved task input intact. Fix blue borders/outlines on Add list and Rename list controls so they remain fully visible and are not clipped or covered by another surface.

Remove the visible `Changes this draft only.` text from the Add list flow. Change the Remove list message to `Remove <list>`, replacing `<list>` with the selected list's name.

## Suggestions

Accepted: check nested-dialog ownership, focus restoration, scrolling, overflow, and stacking rather than hiding focus indicators. Cover desktop/compact layouts and applicable local/HA list flows. Preserve validation, busy-operation safeguards, and existing confirmation/recovery behavior; check Escape/backdrop handling for regressions. Leave `todo.md` and unrelated work unchanged.
