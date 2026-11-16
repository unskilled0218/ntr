# Goal

- [Command](#command)
- [Goal](#goal-1)
- [Suggestions](#suggestions)

## Command

- Support multiple lists
  - List = Project from todo.md

## Goal

Support multiple Home Assistant to-do lists through one ntr server, with each list represented as a project in the client. Selecting a project selects its HA list, and creating or editing a task uses the corresponding list. Keep HA connection settings server-side and Markdown notes unchanged.

## Suggestions

Accepted: identify tasks by both list entity ID and item UID to avoid collisions across lists. Preserve existing single-list configuration and metadata where possible. Keep existing +project text lossless; list membership is separate routing metadata.

Confirmed: manage lists in ntr, creating HA Local To-do lists and renaming their HA display names. Use a configured default list when no project is selected. Cross-list task moves require explicit confirmation and partial-failure protection. Delete only Local To-do lists, after explicit confirmation and a fresh check for both active and completed tasks; never delete the configured default list. Keep other providers' unsupported list-management actions disabled.
