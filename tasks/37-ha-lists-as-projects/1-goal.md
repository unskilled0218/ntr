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

Identify tasks by both list entity ID and item UID to avoid collisions across lists. Define how tasks without a selected project, project changes, and existing +project tokens map to HA lists. Confirm list creation, renaming, and removal behavior before planning; removing a project must not silently delete an HA list or its tasks. Preserve existing single-list configuration and metadata where possible.
