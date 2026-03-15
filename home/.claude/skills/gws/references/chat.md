# Chat

```bash
gws chat spaces list
gws chat spaces messages list --params '{"parent":"spaces/SPACE_ID"}'
gws chat spaces messages create --params '{"parent":"spaces/ID"}' --json '{"text":"msg"}'
```
Requires chat scope: `gws auth login --scopes chat` (or chat.readonly). 403 insufficient scopes = re-auth with chat.
