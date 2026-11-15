# Goal

- [Command](#command)
- [Goal](#goal-1)
- [Suggestions](#suggestions)

## Command

Use HomeAssistant's To-do instead todo.md
- HA: self-host with self-signed cert (homeassistant.lanCA.crt)
- Use option 2: client → ntr server → Home Assistant.

## Goal

Use the self-hosted Home Assistant To-do integration instead of todo.md for task storage and management through the ntr server. Clients connect only to the ntr server, which manages the Home Assistant URL, authentication token, certificate trust using homeassistant.lanCA.crt, and task mapping. Keep Markdown notes unchanged.

## Suggestions

Configure the Home Assistant connection once on the ntr server, without distributing its token to clients. Keep certificate verification enabled and trust the supplied certificate rather than bypassing HTTPS validation. Confirm the Home Assistant URL, target to-do lists, and handling of existing tasks during planning.
