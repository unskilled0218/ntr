# Goal

- [Command](#command)
- [Goal](#goal-1)
- [Suggestions](#suggestions)

## Command

- Make all app-owned modals visually consistent with the Settings modal.
  - Use Settings as the reference for background, border, corner radius, padding, typography, field spacing, and action buttons.
  - Cover HA list creation/rename/deletion, task moves, move reconciliation/abandonment, list removal, local/server conflicts, and open-link confirmation.
  - Align Rename list, Task/Note update previews, pickers, and compact options with the same styling.
  - Keep modal-specific content and responsive sizing where needed, including scrollable previews.
  - Preserve existing actions, validation, accessibility, focus handling, dismissal rules, and recovery safeguards.
  - Do not change native system dialogs such as the folder chooser.

## Goal

Give every app-owned modal a consistent Settings-style surface, typography, field spacing, and action treatment. Preserve each modal's content, responsive layout, scrolling, accessibility, and behavior; leave native system dialogs unchanged.

## Suggestions

Share scoped modal styling rather than duplicating Settings rules across components. Retain deliberate content differences, including title-free update previews and conflict comparisons. Verify dialog behavior and rendered layouts at narrow and desktop widths. Do not modify `todo.md`, server behavior, signing identity, or unrelated work.
