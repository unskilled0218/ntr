# Plan

- [Scope](#scope)
- [Implementation](#implementation)
- [Verification](#verification)
- [Delivery](#delivery)

## Scope

Use task 43's accepted goal. Keep the existing Settings-style visual design; change the specified nested navigation, outline clearance, and copy, not the overall modal layout. Cover local Add/Edit list creation, staged/global list removal from add/filter selectors, and applicable HA create/delete cancellation. Preserve existing task drafts, selected lists, busy guards, explicit approval/recovery, and destination ownership. Do not change native/server behavior, dependencies, signing identity, historical tasks/releases, `todo.md`, or `command.md`.

## Implementation

1. Create fresh parent/app `43-list-modal-navigation-focus` branches. Extend the existing scoped `ListSelectorSession` mechanism instead of simulating clicks or reopening selectors by a global DOM query. Retain the originating picker under add/remove confirmation; restore focus to the originating action/row after Cancel, Escape, or backdrop dismissal. Use generation/scope guards so obsolete sessions cannot focus, close, or resurrect a newer picker.
2. Let `SelectField` retain explicitly identified action choices such as the Add sentinel and pass their session to the owner. Ordinary selection still closes normally. Preserve rename's revision-aware focus behavior; match Add by option value/label and Remove by its action control. Scope retained sessions to their destination and mounted owner.
3. Wire local AddForm/EditTaskModal label creation to retain/resolve its picker session. Cancel restores the picker without changing task fields or selection; successful Add retains existing selection/staging semantics and closes its picker. Invalidate sessions when task, compact layout, destination, or edit suspension changes.
4. Keep staged/global removal pickers under the confirmation instead of closing their enclosing compact options. Cancel returns to that picker without writes. Preserve global sequential writes, partial results, busy dismissal refusal, explicit Review update stack closure, retry/abandon, and successful removal result handling. Use the existing session close boundary when review/navigation must close the whole stack. Keep filter rename behavior unchanged unless needed to pass through the scoped session safely.
5. Retain the HA picker under create/delete prompts and restore it on cancellation, guarded by destination/catalog ownership. Keep HA rename, move/recovery, admin/default/empty-list guards, and uncertain-write handling intact. No live HA operations are authorized.
6. The blue outline is drawn outside picker buttons while the scrolling list has no padding. Add internal outline clearance and local focused-row stacking so Add/Rename outlines cannot be clipped by the scroll container or covered by adjacent rows. Keep scrolling, selected/danger colors, focus visibility, and top-layer ordering; do not hide indicators or add global z-index hacks.
7. Remove `Changes this draft only.` where it currently appears in draft rename reached through the add-list picker flow. Show local removal's visible heading/message as `Remove <name>` using the literal selected list name, without its syntax prefix or the old generic removal paragraph. Keep progress, errors, and partial-operation/recovery warnings. Do not remove HA deletion safeguards.
8. Add focused tests for cancellation returning to the same picker, preserved drafts/selection, no cancellation writes, repeated close delivery, keyboard/backdrop dismissal, obsolete scope/session invalidation, busy removal, and HA cancellation. Extend appearance tests for outline clearance/row stacking without claiming real layout proof. Update affected existing expectations, README/topic docs, app version `0.15.37`, mirrors/release pointer, and new notes. Keep server unchanged.

## Verification

- Run targeted selector/add/edit/removal/HA/lifecycle/appearance tests, then all frontend tests with `NODE_OPTIONS=--no-experimental-webstorage`, production build, offline app release validation, and all app release-tool tests.
- Confirm cancellation performs no task/label/HA writes, preserves task drafts/selection, and exposes the originating picker rather than merely focusing its closed trigger. Retain busy and late-event protections, origin/destination validation, recovery authority, title-free update previews, and exact wire/storage contracts.
- Inspect CSS overflow/outline rules and long rows. No real browser was available in prior tasks; check availability and record browser/device visual limitations rather than claim screenshot verification from jsdom. Native/server suites need not be rerun for frontend-only changes; validate version mirrors and unchanged native code.
- Check maintained links/anchors/TOCs, whitespace, unchanged historical/vendor/server/native content, exact dependency/signing preservation, and original `todo.md`/`command.md` hashes. No merge, push, publication, deployment, or live services.

## Delivery

Record implementation/checks/limits in `5-implemented.md`. Commit app first, then parent README/task report and app pointer. Preserve previous task work and leave unrelated files unstaged. Notify after each workflow stage.
