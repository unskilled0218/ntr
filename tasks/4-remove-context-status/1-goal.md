# goal

## command

- remove context, status

## goal

Simplify the app's todo interface by removing context controls and the status filter.

Interpret "context" as the todo.txt `@context` feature exposed in the app, and "status" as the All/Active/Completed task filter.

- Remove context selection, creation, removal, filtering, and sorting from the todo interface, including compact Options dialogs and task add/edit forms.
- Remove context metadata from task list presentation.
- Remove the status picker and its saved view preference. Show both active and completed tasks, subject to the remaining project filter.
- Keep task completion and reopening available through the existing task controls.
- Preserve existing `@context` tokens when editing tasks. Removing the interface must not silently delete stored task metadata.
- Handle a previously saved context sort by falling back to file order.
- Keep project controls, priority, due date, other sort choices, and sort direction working in both standard and compact layouts.

## project findings

- `app/src/components/FilterBar.tsx` renders the status and context filters in both layouts.
- `app/src/components/TodoPane.tsx` owns status/context filter state, builds task queries, and persists status changes.
- `app/src/components/AddForm.tsx` and `app/src/components/EditTaskModal.tsx` expose context pickers and label creation.
- `app/src/components/TaskItem.tsx` displays context metadata.
- `app/src/config.ts` defines context label controls, the context sort, and status choices. `app/src/settings.ts` stores the status preference and validates saved sorts.
- The app and server are separate Git submodules. The local/server task format supports contexts independently of these interface controls.

## acceptance criteria

- No context controls, context sort, context metadata, or status picker appear in standard or compact todo layouts.
- A previously saved Active or Completed preference does not hide tasks after the status filter is removed.
- A previously saved Contexts sort does not break rendering and falls back to file order.
- Adding, editing, completing, reopening, deleting, and project-filtering tasks still work in local and server modes.
- Editing an existing task preserves its stored contexts, including multiple context tokens.
- Relevant component, settings, and task serialization tests reflect the simplified interface, and app build checks pass.
