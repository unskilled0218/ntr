# goal

## command

- android dismiss modal one by one
  - options > project
    -> dismiss(click outside or cancel button) all modal. one click dismiss one modal
- Clarification: `Options > Project` is only an example. Fix modal dismissal for all modals.

## goal

Fix Android modal dismissal across all app modals so one dismissal action closes only the topmost modal. `Options > Project` is an example, not the scope boundary. For every supported modal stack, tapping outside the topmost modal or using its dismissal button must leave underlying modals open and usable. Each remaining modal requires its own dismissal action.

Preserve underlying controls, selections, and pending input according to each modal's existing cancel behavior. Opening, dismissing, and reopening any modal must keep native dialog visibility and React state consistent.

## project findings

- `app/src/components/FilterBar.tsx` nests the Project `SelectField` and `SortField` inside `OptionsModal` when compact controls are enabled. `app/src/components/AddForm.tsx` also nests task fields, including the project picker, inside an Options modal.
- `app/src/components/OptionsModal.tsx` and `app/src/components/SelectField.tsx` each own a native `<dialog>` through `usePickerDialog`. Both set their open state to false in an `onClose` handler. Project Cancel sets the picker's open state to false; Options uses a Done button.
- `app/src/components/usePickerDialog.ts` synchronizes React open state with native `showModal()` and `close()`. `app/src/components/useBackdropClose.ts` closes a dialog when a click targets the dialog element itself and assumes nested backdrop clicks leave ancestors open.
- Modal implementations also include `SettingsModal`, `EditTaskModal`, `LabelModal`, `RemoveLabelDialog`, `ConflictDialog`, `NoteConflictDialog`, and `OpenLinkDialog`. They use the shared backdrop hook with different state ownership and close/cancel handlers. The task covers these dialogs as well as Options, Select, and Sort pickers; inspect every supported nesting and stacking flow rather than limiting the fix to one component pair.
- Existing `OptionsModal.test.tsx` and `SelectField.test.tsx` cover standalone opening and dismissal. They do not establish that closing a nested Project picker leaves Options open. Inspect native close-event handling and React event propagation as well as backdrop clicks before choosing a fix; the Android root cause has not been reproduced in this goal stage.

## acceptance criteria

- Inspect all app modal implementations and supported stacking flows. On Android, one backdrop tap or dismissal-button action closes only the topmost modal and leaves all underlying modals visible and usable.
- Apply the same one-layer rule to native cancel actions where supported, including Escape and Android Back when delivered as dialog cancellation. Preserve each modal's existing cancellation semantics.
- Verify representative flows involving both self-owned pickers and externally controlled dialogs, including Options > Project, Options > Sort, Settings > picker, and Edit task > picker or label dialog. Verify any other supported modal stacks found during inspection.
- Each remaining modal closes only through a separate dismissal action. Standalone modals remain dismissible, and dismissed children can reopen normally.
- Dismissing a child preserves the underlying modal's selections and pending input. Clicking inside a modal does not dismiss an ancestor, and selection or confirmation actions preserve their existing behavior without unintended ancestor dismissal.
- Cover all modal families, including task and note conflict dialogs, label removal, and link confirmation. Desktop dismissal continues to work.
- Add meaningful regression coverage for nested backdrop, dismissal-button, and native cancel handling, including underlying open state, preserved input, and reopening. Include differing dialog state-ownership patterns rather than testing only Options > Project.
- Record relevant frontend checks and Android runtime results, including Android/WebView version and the tested modal flow. If device verification is unavailable, record the limit rather than treating jsdom checks as proof of Android behavior.
