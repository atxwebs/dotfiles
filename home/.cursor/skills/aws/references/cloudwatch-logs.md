# CloudWatch Logs

## Quick Status Checks
```bash
# List available log groups
aws logs describe-log-groups --log-group-name-prefix LOG_GROUP_PREFIX

# Get log streams for a group
aws logs describe-log-streams --log-group-name LOG_GROUP_NAME --order-by LastEventTime --descending
```

## Log Access Methods

### Method 1: EB Log Retrieval (Temporary S3 URLs)
```bash
# Request logs
aws elasticbeanstalk request-environment-info --environment-id EB_ENVIRONMENT_ID --info-type tail

# Wait a few seconds, then retrieve log URLs
aws elasticbeanstalk retrieve-environment-info --environment-id EB_ENVIRONMENT_ID --info-type tail

# Download logs using curl (URLs expire quickly)
curl -s "S3_LOG_URL" | tail -100
```

### Method 2: CloudWatch Logs (More Reliable)
```bash
# List available log groups
aws logs describe-log-groups --log-group-name-prefix "/aws/elasticbeanstalk/EB_ENVIRONMENT_NAME"

# Get latest log stream name
aws logs describe-log-streams \
  --log-group-name "/aws/elasticbeanstalk/EB_ENVIRONMENT_NAME/var/log/web.stdout.log" \
  --order-by LastEventTime --descending --max-items 1 \
  --query 'logStreams[0].logStreamName' --output text

# Get recent log events
aws logs get-log-events \
  --log-group-name "/aws/elasticbeanstalk/EB_ENVIRONMENT_NAME/var/log/web.stdout.log" \
  --log-stream-name LOG_STREAM_NAME \
  --query 'events[-30:].message' --output text
```

## Key Log Groups for Node.js Apps
- `/aws/elasticbeanstalk/EB_ENVIRONMENT_NAME/var/log/web.stdout.log` - **Application stdout/stderr** (most important)
- `/aws/elasticbeanstalk/EB_ENVIRONMENT_NAME/var/log/nginx/error.log` - Nginx proxy errors
- `/aws/elasticbeanstalk/EB_ENVIRONMENT_NAME/var/log/eb-hooks.log` - Deployment hooks (prebuild, predeploy)
- `/aws/elasticbeanstalk/EB_ENVIRONMENT_NAME/var/log/eb-engine.log` - EB platform logs

## Time-based Log Filtering
```bash
# Get logs from last hour (timestamp in milliseconds)
aws logs get-log-events \
  --log-group-name LOG_GROUP_NAME \
  --log-stream-name LOG_STREAM_NAME \
  --start-time $(($(date +%s - 3600)*1000))
```

## Cross-Stream Search (filter-log-events)
```bash
# Dump last 24h across all streams (no stream name needed)
aws logs filter-log-events \
  --log-group-name "/aws/elasticbeanstalk/hwg-hub-api-prod-1/var/log/web.stdout.log" \
  --start-time $(($(date +%s -d '24 hours ago')*1000)) \
  --query 'events[*].message' --output text > /tmp/cw.log
# Then grep locally: rg "pattern" /tmp/cw.log
```
Note: Log streams are per-instance. When EB replaces an instance, a new stream starts; old streams may retain history but describe-log-streams shows current instance only. Retention can be long (3653 days) but current stream may only cover recent days.

## JSON Parsing Examples
```bash
# Extract log messages with jq
aws logs get-log-events --log-group-name LOG_GROUP_NAME --log-stream-name LOG_STREAM_NAME --output json | jq '.events[].message'

# Query log stream names
aws logs describe-log-streams --log-group-name LOG_GROUP_NAME --query 'logStreams[*].logStreamName'
```
