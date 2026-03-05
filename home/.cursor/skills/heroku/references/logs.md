# Heroku Logs

```bash
heroku logs --num 100 | grep pattern
heroku logs --num 100 | grep -i -E "(ignore|Newer message exists)"
```
Never use `--tail` (hangs). `--app` not needed.
