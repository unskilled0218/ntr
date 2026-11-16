# Goal

- [Command](#command)
- [Goal](#goal-1)
- [Suggestions](#suggestions)

## Command

- Cancel from add/remove list go back to list, not dismiss
- handle blue borderline from list. some of borderline blocked by other view?
  - Add list button
  - Rename list button

## Goal

Canceling Add list or Remove list should return to the originating list picker rather than dismissing the whole picker flow. Keep the picker's selection and unsaved task input intact. Fix blue borders/outlines on Add list and Rename list controls so they remain fully visible and are not clipped or covered by another surface.

## Suggestions

Check nested-dialog ownership, focus restoration, scrolling, overflow, and stacking rather than hiding focus indicators. Cover desktop/compact layouts and applicable local/HA list flows. Preserve validation, busy-operation safeguards, and existing confirmation/recovery behavior; check Escape/backdrop handling for regressions. Leave `todo.md` and unrelated work unchanged.
