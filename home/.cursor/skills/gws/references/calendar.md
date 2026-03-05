# Calendar

```bash
gws calendar calendarList list
gws calendar events list --params '{"calendarId":"primary", "maxResults":10}'
gws calendar events list --params '{"calendarId":"ID", "timeMin":"2026-01-01T00:00:00Z", "timeMax":"2026-01-31T23:59:59Z"}'
gws calendar events get --params '{"calendarId":"primary", "eventId":"EVENT_ID"}'
gws calendar +agenda  # upcoming across calendars
```
`calendarId`: "primary" or from calendarList. RFC3339 for timeMin/timeMax. Helper: `+insert`.
