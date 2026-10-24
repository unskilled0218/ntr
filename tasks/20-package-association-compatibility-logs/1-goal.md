# goal

- [command](#command)
- [goal](#goal-1)

## command

Fix package association on `https://git.lan`, whose API reports `{"version":"28.2.0"}`, after verifying the deployed software and link API safety. Preserve accepted `v0.2.6` artifacts and existing safety checks, update tests/documentation, and display logs so the user can see what is happening. No live publication, package mutation, cleanup, or privileged setup without separate approval.

## goal

Add tested package-association support only after establishing the deployed server's identity and conflict/refusal semantics, without bypassing the existing Gitea safety gate or allowing reassignment and blind write retries. Provide an identity-verified way to complete association for the accepted `v0.2.6` publication without rebuilding, republishing, or rewriting its image, Git tag, or release. Preserve existing supported-server behavior and refusal of uncertain evidence. Add clear, secret-safe progress logs and relevant tests/documentation. Do not perform live mutations or privileged setup, change unrelated application behavior, or edit `todo.md`.
