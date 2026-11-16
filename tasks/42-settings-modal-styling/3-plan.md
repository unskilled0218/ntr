# Plan

- [Scope](#scope)
- [Implementation](#implementation)
- [Verification](#verification)
- [Delivery](#delivery)

## Scope

Use the existing Settings modal as the approved visual reference, not a new design or workflow. Cover every app-owned native HTML dialog: settings, add-label, edit-task, rename/remove-list, pickers, compact options, remote-update previews, local/server conflicts, dirty-note conflicts, open-link confirmation, and the shared HA confirmation dialogs. Native system dialogs and server code are excluded. Preserve task 41 changes, `todo.md`, task history, dependencies, and signing identity.

## Implementation

1. Create fresh `42-settings-modal-styling` branches in parent and app. Keep server unchanged. Add one shared `app-modal` styling marker to every app-owned dialog while preserving its existing IDs, specialized classes, ARIA labels, refs, event handlers, and content.
2. Consolidate duplicated modal shell/form/heading/field rules in `src/style.css`. Share Settings' white surface, 1px border, 8px radius, 1.25rem padding, 1.1rem headings, 0.75rem form spacing, muted 0.8rem field labels, and existing neutral/primary action treatment. Style unnamed-type text inputs consistently. Keep keyboard focus visible inside modals and action rows wrapping safely.
3. Apply viewport-bounded width/height and scroll handling to every app modal, including Settings. Keep dialog layout overrides restricted to open dialogs so closed dialogs remain hidden. Preserve wider comparison/update previews, Edit task's content width, picker scrolling/selection/danger states, and title-free remote update previews. Use the shared white surface for the sticky update footer. Retain busy dismissal, nested picker focus, approval, and recovery behavior unchanged.
4. Add modal-style coverage that checks all dialog templates opt in and verifies rendered shared shell, typography, fields, actions, and relevant responsive/overflow rules. Run existing lifecycle, picker, list-management, and update-preview suites unchanged except for necessary style expectations. No new component framework or dependencies are needed.
   Remove competing old shell rules, check form/non-form spacing for double margins, and explicitly test open-only layout and the shared sticky-footer background. Verify the TSX diff is only styling markers.
5. Update the app README and a dedicated modal-styling topic with the common contract, intentional size/content differences, and native-dialog exclusion. Bump app `0.15.35` to `0.15.36` with exact existing metadata mirrors and concise release notes describing the UI styling change. Do not bump the unchanged server.

## Verification

- Run all frontend tests with `NODE_OPTIONS=--no-experimental-webstorage`, production build, offline app release validation, and app release-tool tests. Check changed TSX for event/ARIA/content invariance. Native Rust runtime and server suites are not required for class/CSS-only behavior changes; version mirrors still need validation.
- Inspect rendered styling at desktop/narrow widths if a real browser is available. None is currently found in PATH/cache; if unavailable, use DOM/computed-style and CSS-policy coverage, record that it does not prove actual browser layout/focus or Android behavior, and do not claim screenshot verification.
- Verify every dialog family uses the shared shell, closed dialogs stay hidden, long names/URLs and multi-action recovery dialogs can wrap, previews remain scrollable/title-free, sticky footers use the common surface, and destructive/primary/selected states remain distinct.
- Check docs links/anchors/TOCs, whitespace, exact version-only changes outside UI/tests/docs, and unchanged dependencies/signing/server/history/vendor/`todo.md` content. Do not publish, deploy, merge, push, or use live HA.

## Delivery

Record implementation and exact checks/limits in `5-implemented.md`. Commit app first, then parent README/task results and app pointer. Do not stage `command.md`, `todo.md`, or unrelated work. Notify after each workflow stage.
