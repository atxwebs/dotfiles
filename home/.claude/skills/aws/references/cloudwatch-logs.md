# CloudWatch Logs

```bash
aws logs describe-log-groups --log-group-name-prefix PREFIX
aws logs describe-log-streams --log-group-name GROUP --order-by LastEventTime --descending
aws logs get-log-events --log-group-name GROUP --log-stream-name STREAM --query 'events[-30:].message' --output text
aws logs filter-log-events --log-group-name GROUP --start-time $(($(date +%s -d '24h ago')*1000)) --query 'events[*].message' --output text
```
Key EB log groups: `.../var/log/web.stdout.log`, `.../nginx/error.log`, `.../eb-hooks.log`. Streams per-instance; filter-log-events crosses streams.
