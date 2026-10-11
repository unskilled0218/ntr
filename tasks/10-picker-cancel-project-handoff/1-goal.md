# goal

## command

- `Cancel` button from Priority and Projects doesn't dismiss modal
- `Project > Add project...` create modal to create project behind itself

## goal

Fix Priority and Project picker interactions so a single Cancel action dismisses the picker and selecting `+ Add project...` replaces the picker with a visible, interactive project-creation modal. The creation modal must not appear behind a still-open or reopened Project picker.

Preserve the underlying task form or Options/Edit modal, its pending input, and current selections. Dismissing the picker or project-creation modal must not submit a task, save an edit, or create a project. Confirming a valid new project should retain the existing staging/selection flow.

## project findings

- `app/src/components/SelectField.tsx` handles Priority and Project picker Cancel by setting React open state to false. Selecting a row similarly sets state to false and immediately invokes its caller's callback.
- `app/src/components/usePickerDialog.ts` applies `showModal()` and `close()` in a React effect. A requested close and the native dialog actually leaving the modal top layer are separate lifecycle steps.
- `app/src/components/LabelSelect.tsx` routes the `+ Add project...` sentinel to `onAdd`. AddForm and EditTaskModal then set `modalKind`, causing `LabelModal` to open through its own effect. Inspect native close/open ordering and any trigger reactivation before choosing a fix; this goal stage has not reproduced the reported runtime behavior.
- Priority and Project controls are rendered inside labels in `AddForm.tsx` and `EditTaskModal.tsx`. Compact AddForm places them inside Options. LabelModal is a sibling of AddForm's form and a child of EditTaskModal's dialog, so both replacement flows need coverage.
- Shared event ownership currently isolates close/cancel propagation, and `useBackdropClose.ts` prevents default label activation for backdrop clicks. Preserve those one-layer dismissal guarantees while investigating button cancellation and project-modal handoff.
- Existing SelectField, AddForm, and EditTaskModal tests cover cancellation, reopening, and label handoffs using jsdom dialog shims. Those shims do not model native top-layer ordering, focus, or actual pointer interactions, so passing tests alone do not establish that project creation is visible on the reported platform.

## acceptance criteria

- In Priority and Project pickers, one Cancel click/tap closes the native picker and keeps it closed until the trigger is explicitly activated again. Cancellation does not change the selected value.
- When a picker is inside Options or Edit task, Cancel closes only the picker. The underlying modal remains usable with pending description, priority, due date, and project values preserved.
- Selecting `+ Add project...` closes the Project picker and presents the creation modal as the interactive topmost dialog. Its name input can receive focus and text immediately, without an extra dismissal action.
- Cover add-task controls in compact and noncompact layouts and the Edit task flow. Repeat open/Cancel/reopen and Project/create/cancel/reopen cycles without hidden, stuck, or spontaneously reopened pickers.
- Cancelling project creation preserves the previous project selection and task input. Confirming a valid name stages/selects the new project through the existing form behavior without unintended task submission or edit save.
- Existing picker selection, backdrop/native cancellation, and one-layer dismissal remain functional. Related shared picker consumers continue to work.
- Add regression coverage for the reported Cancel and replacement-order failures, including differing parent layouts and delayed lifecycle events where relevant. Verify actual dialog visibility/interactivity in an available browser/device, including Android if that is the affected platform; record platform/WebView versions and unavailable runtime checks separately from jsdom results.
