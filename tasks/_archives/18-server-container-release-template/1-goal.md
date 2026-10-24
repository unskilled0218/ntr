# goal

- [command](#command)
- [goal](#goal-1)

## command

server: update build image and release process as reference: https://git.lan/dev/container-release-template

## goal

Update the server's container image build and release workflow to follow the referenced container-release template, adapted to `ntr/ntr-server` rather than its sample image. Use the reference's configuration, version/release-note, credential, validation, and publication conventions for AMD64/ARM64 images, including repository package association where supported. Reference inspected: `3c73528231ac1cbdd43600a5ca723390db804bac` (template `0.5.0`).

Preserve the Rust server's runtime behavior, non-root execution, persistent data paths, and application configuration. Update relevant server documentation and release tests to match the adopted workflow, documenting migration differences and verification limits. Keep this task confined to server image/release tooling; do not change the app or unrelated server functionality.
