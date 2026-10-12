# goal

## command

- script to build, release image to self host forgejo
- ex)
  ```bash
  FORGEJO_TOKEN="$(<"$HOME/.config/forgejo/forgejo-token")" server/scripts/release.sh
  ```

## goal

Provide a server release script that builds a runnable container image and publishes it to the self-hosted Forgejo container registry. The command above must work from the parent project root, with the script locating the server repository independently of the caller's working directory.

The target is the `server/` submodule, whose origin is `ssh://git@git.lan/ntr/ntr-server.git`. It currently has no Dockerfile or release script: `docker-compose.yml` runs `cargo run --release` inside `rust:1-bookworm` with the source mounted. The crate and binary are named `my-ntr-server`, and `Cargo.toml` currently declares version `0.2.1`. Build a deployable image containing the compiled server rather than requiring consumers to mount source or compile on startup.

Use the server's version as the authoritative version for a reproducible image tag. Default publishing should target the existing Forgejo host and `ntr` owner, with the exact container registry image name and login username confirmed during planning. Interpret “image” as an OCI container image published to Forgejo Packages; document this destination separately from downloadable Forgejo release attachments. Support explicit registry/image configuration where needed.

Preserve the server's runtime configuration and persistent `todo.txt`, `Note.md`, and `labels.json` files. Document how to run the published image with a data mount and reachable container port. Put build, authentication, publishing, and deployment details in `server/docs/<topic>.md`, keeping `server/README.md` brief with a link.

## acceptance criteria

- `server/scripts/release.sh` builds and publishes a versioned server image using the supplied `FORGEJO_TOKEN` and documented registry authentication settings.
- The script works from both the parent project root and the server repository root, and reports the published image reference and digest after success.
- The published image starts the compiled server without a source mount or Rust build tools at runtime. Its `/api/health` endpoint responds successfully with the documented container configuration.
- Existing environment variables configure the server, and mounted data survives container replacement. The documented deployment command reflects the actual port and file paths.
- The image tag identifies the intended server version and build revision. Any additional tags, Git tags, or Forgejo release records require an explicit policy during planning.
- Missing tools or credentials and build, login, or push failures produce clear errors and a nonzero exit status. Tokens are not committed or printed; credentials are passed through the container tool's supported noninteractive mechanism.
- Verification covers the script's command flow and failure paths, image build/startup, and persistence with disposable data. Record any unavailable container-engine or live Forgejo access separately.
- Server documentation includes the requested command, prerequisites, registry/image configuration, and pull/run instructions.

This stage records a fresh goal only. Implementation and publication belong to later workflow stages.
