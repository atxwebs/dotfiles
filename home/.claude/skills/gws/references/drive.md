# Drive

```bash
gws drive files list --params '{"pageSize": 20}'
gws drive files get --params '{"fileId": "ID"}'
gws drive files list --params '{"q": "mimeType=\"application/vnd.google-apps.spreadsheet\""}'
gws drive files list --params '{"q": "name contains \"foo\""}'
gws drive files create --json '{"name":"report.pdf"}' --upload ./report.pdf
gws drive about get  # quota, storage
```
`q` = Drive search syntax. Common mimeTypes: spreadsheet, document, presentation, folder.
