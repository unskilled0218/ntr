# goal

- [command](#command)
- [goal](#goal-1)

## command

Fix critical from previous code review.

## goal

Fix critical finding F1 from `tasks/18-server-container-release-template/5-code-review.md`: ensure the server release publisher pushes only its intended release tag, even when `push.followTags=true`, without changing the user's Git configuration. Add regression coverage proving unrelated annotated tags remain local while preserving non-force publication and lost-response reconciliation. Exclude the ARM64 v8 warning, live publication, unrelated changes, and edits to `todo.md`.
