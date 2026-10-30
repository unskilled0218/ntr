# ntr

- [Components](#components)
- [Run](#run)

ntr is a local-first task manager and Markdown notes app. Use local files or connect the Tauri client to the optional server.

See [server connection and fallback](app/docs/server-connection.md), [remote update approval](app/docs/live-sync.md), and [project actions](app/docs/project-renaming.md).

## Components

- [app](app/README.md) — Tauri, React, and TypeScript client.
- [server](server/README.md) — Rust HTTP server backed by plain files.

Both components are Git submodules. Initialize them after cloning:

```sh
git submodule update --init --recursive
```

The app uses [guarded artifact publication](app/docs/forgejo-publishing.md); Android signing files stay local and gitignored.

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
