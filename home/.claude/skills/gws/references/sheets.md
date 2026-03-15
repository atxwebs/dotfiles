# Sheets

**Ranges:** use single quotes `'Sheet1!A1:C10'` — bash expands `!` otherwise.

```bash
gws sheets spreadsheets get --params '{"spreadsheetId":"ID"}'
gws sheets spreadsheets values get --params '{"spreadsheetId":"ID", "range":"Sheet1!A1:C10"}'
gws sheets spreadsheets values append --params '{"spreadsheetId":"ID", "range":"Sheet1!A1", "valueInputOption":"USER_ENTERED"}' --json '{"values":[["a","b"]]}'
gws sheets spreadsheets values batchGet --params '{"spreadsheetId":"ID", "ranges":["S1!A1","S2!B1"]}'
```
valueInputOption: RAW or USER_ENTERED (formulas). Create: `spreadsheets create --json '{"properties":{"title":"X"}}'`.
