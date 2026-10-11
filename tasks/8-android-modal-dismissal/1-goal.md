# goal

## command

- android dismiss modal one by one
  - options > project
    -> dismiss(click outside or cancel button) all modal. one click dismiss one modal

## goal

Fix Android nested modal dismissal so one dismissal action closes only the topmost modal. In the Options > Project flow, tapping outside the Project picker or tapping its Cancel button must close the picker while leaving the Options modal open. A separate dismissal action can then close Options.

Preserve the underlying controls, selections, and pending task input when dismissing a child modal. Opening, dismissing, and reopening nested pickers must keep native dialog visibility and React state consistent.

## project findings

- `app/src/components/FilterBar.tsx` nests the Project `SelectField` and `SortField` inside `OptionsModal` when compact controls are enabled. `app/src/components/AddForm.tsx` also nests task fields, including the project picker, inside an Options modal.
- `app/src/components/OptionsModal.tsx` and `app/src/components/SelectField.tsx` each own a native `<dialog>` through `usePickerDialog`. Both set their open state to false in an `onClose` handler. Project Cancel sets the picker's open state to false; Options uses a Done button.
- `app/src/components/usePickerDialog.ts` synchronizes React open state with native `showModal()` and `close()`. `app/src/components/useBackdropClose.ts` closes a dialog when a click targets the dialog element itself and assumes nested backdrop clicks leave ancestors open.
- Existing `OptionsModal.test.tsx` and `SelectField.test.tsx` cover standalone opening and dismissal. They do not establish that closing a nested Project picker leaves Options open. Inspect native close-event handling and React event propagation as well as backdrop clicks before choosing a fix; the Android root cause has not been reproduced in this goal stage.

## acceptance criteria

- On Android with compact controls enabled, open Options and then Project. One tap outside the Project picker closes only Project and leaves Options visible and usable.
- In the same flow, Project Cancel closes only Project. Options closes only through a separate dismissal of its own backdrop or Done button.
- Repeat the flow for filter Options and task Options. Dismissal preserves the current project selection and pending task input, and the Project picker can reopen normally.
- Clicking inside a child modal does not dismiss the parent. Choosing a project retains the existing selection behavior and does not inadvertently dismiss Options.
- Other nested picker flows using the same dialog handling, including Sort inside Options, retain one-layer dismissal. Standalone dialogs and desktop dismissal continue to work.
- Add meaningful nested-dialog regression coverage for backdrop and Cancel dismissal, including the parent's remaining open state and reopening the child.
- Record relevant frontend checks and Android runtime results, including Android/WebView version and the tested modal flow. If device verification is unavailable, record the limit rather than treating jsdom checks as proof of Android behavior.
