# Gmail

```bash
gws gmail users getProfile --params '{"userId":"me"}'
gws gmail users messages list --params '{"userId":"me", "maxResults":10}'
gws gmail users messages get --params '{"userId":"me", "id":"MSG_ID"}'
gws gmail users labels list --params '{"userId":"me"}'
gws gmail users threads list --params '{"userId":"me", "maxResults":5}'
gws gmail +triage  # unread inbox summary
```
`userId` = "me" for authed user. IDs from list. Helpers: `+send`, `+triage`, `+watch`.
