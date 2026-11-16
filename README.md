# ntr

- [Run](#run)
- [Documentation](#documentation)

Tasks organized by lists and Markdown notes for desktop and Android. Work locally or connect to ntr server; Home Assistant credentials stay on the server.

## Run

Initialize the app and server submodules:

```sh
git submodule update --init --recursive
```

From `app/`, run `npm ci` and `npm run tauri dev`. From `server/`, run `cargo run --locked` or follow [Docker setup](server/docs/docker-compose.md). The server defaults to `http://127.0.0.1:8080` and has no authentication.

## Documentation

- [App setup](app/README.md), [server connection](app/docs/server-connection.md), [update approval](app/docs/live-sync.md), and [modal styling](app/docs/modal-styling.md).
- [Server setup](server/README.md), [HA lists and recovery](server/docs/home-assistant.md), and [HTTP API](server/docs/api.md).
- [App publication](app/docs/forgejo-publishing.md), [Android signing](app/docs/android-signing.md), and [server publication](server/docs/release.md).
