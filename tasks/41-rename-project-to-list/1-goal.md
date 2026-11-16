# Goal

- [Command](#command)
- [Goal](#goal-1)
- [Suggestions](#suggestions)

## Command

- Update term `Project` to `List`
- Not just user-facing text but also the project's code side.

## Goal

Use “List” instead of “Project” consistently across the app and server: user-facing text, maintained documentation, and code terminology. Rename relevant types, functions, variables, components, files, tests, and internal contracts for the task-grouping concept, not unrelated uses of “project.” Preserve existing local and Home Assistant behavior and user data.

## Suggestions

Update code, tests, and documentation together rather than only replacing display text. Review API fields, persisted settings/storage keys, and task syntax explicitly; use compatibility handling or migration where renaming would otherwise break existing clients or data. Leave historical records and `todo.md` unchanged.
