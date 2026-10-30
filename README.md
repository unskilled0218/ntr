# ntr

- [Components](#components)
- [Run](#run)

ntr is a local-first task manager and Markdown notes app. The Tauri client works with local files on its own or connects to the optional Rust server for shared access and live updates.

Remote changes ask before updating. Declining keeps drafts and server data untouched; pending note updates pause autosave. See [update approval](app/docs/live-sync.md).

Pencil/trash project actions are available in filter and create-task selectors, with preserved drafts and selector-based recovery. See [project actions](app/docs/project-renaming.md).

## Components

- [app](app/README.md) — Tauri, React, and TypeScript client.
- [server](server/README.md) — Rust HTTP server backed by plain files.

Both components are Git submodules. Initialize them after cloning:

```sh
git submodule update --init --recursive
```

## Run

Start the app:

```sh
cd app
npm install
npm run tauri dev
```

Start the optional server in another terminal:

```sh
cd server
cargo run
```

The server listens on `http://127.0.0.1:8080` by default and has no authentication. See the component READMEs for configuration, testing, and release details.

Priority is no longer a task feature. Legacy data stays intact with the new client and server; see [compatibility limits](app/docs/task-text.md) before using an older server.
