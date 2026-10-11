# goal

## command

- remove project display from description
  - duplicate with small project text under description

## goal

Stop displaying project tokens in the main task description because projects already appear in the smaller metadata text beneath it. Keep projects visible in that metadata line, including multiple projects, while showing only the remaining description text in the main line.

This is a task-row presentation change. Preserve stored task descriptions, project associations, editing, filtering, sorting, and task actions.

## project findings

- `app/src/components/TaskItem.tsx` renders the main line using `hideContexts(task.description, task.contexts)`, which hides context tokens but leaves project tokens visible. `renderMeta` separately renders every parsed project as `+name`, producing the reported duplication.
- `app/src/labels.ts` already has whole-token matching for hidden context tokens and structured descriptions. `bareDescription` also removes tags, so using it without considering the existing display contract would hide unrelated text such as due tags.
- `app/src/components/TaskItem.test.tsx` currently expects `+work` in both the main line and metadata. It also covers ordinary text containing `@`, fallback text for context-only tasks, and unchanged Edit/Delete/complete callbacks.
- The task row is shared by active/completed tasks and local/server-backed data. The rendering change can stay in the frontend without altering persistence or backend parsing.

## acceptance criteria

- A task such as `call bank +work` displays `call bank` in the main description and retains `+work` in the small metadata line.
- All parsed project tokens are hidden from the main description, including multiple or repeated project tokens. Project metadata remains visible under the description.
- Match complete project tokens rather than substrings. Ordinary text containing `+`, URLs, and similarly named text remain intact unless they are exact tokens for the task's parsed projects.
- Preserve current context hiding, priority display, created/completed metadata, and non-project description content, including tags that are currently displayed.
- If removing hidden project/context tokens leaves no description text, display the existing `Task without description` fallback while retaining available project metadata.
- Active and completed rows use the same rule on mobile and desktop. Stored descriptions and project associations remain unchanged, and Edit/Delete/complete callbacks receive the original task.
- Add focused task-row regression coverage for deduplicated display, multiple projects, token boundaries, project-only fallback, and preserved task actions. Record relevant frontend verification during implementation.
