# Docs

```bash
gws docs documents get --params '{"documentId":"ID"}'
gws docs documents batchUpdate --params '{"documentId":"ID"}' --json '{"requests":[...]}'
```
Doc IDs from Drive (mimeType document). get returns body.content[]. batchUpdate for insert/delete/replace. Schema: `gws schema docs.documents.get`.
