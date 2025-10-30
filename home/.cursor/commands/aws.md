# AWS CLI Debugging Guide

## 🚨 CRITICAL RULE
**NEVER make AWS changes via CLI without explicit user approval each time.** Only use for read-only debugging and information gathering.

## Stack

- Elastic Beanstalk for the API
- RDS with Postgres 13.7
- Route 53 for the domain ($STAGE.fin.manufactured.com)
- CloudWatch for the logs
- CDK for the stack at [bin/cdk](/bin/cdk)

## Elastic Beanstalk Debugging

### Environment Status & Events
```bash
# Get environment details
aws elasticbeanstalk describe-environments --environment-ids e-muh8x9zmqx

# Get recent deployment events (most useful for failures)
aws elasticbeanstalk describe-events --environment-id e-muh8x9zmqx --max-records 15

# Get detailed health status
aws elasticbeanstalk describe-environment-health --environment-id e-muh8x9zmqx --attribute-names All

# Get instance-level health details
aws elasticbeanstalk describe-instances-health --environment-id e-muh8x9zmqx --attribute-names All
```

### Log Access (Two Methods)

#### Method 1: EB Log Retrieval (Temporary S3 URLs)
```bash
# Request logs
aws elasticbeanstalk request-environment-info --environment-id e-muh8x9zmqx --info-type tail

# Wait a few seconds, then retrieve log URLs
aws elasticbeanstalk retrieve-environment-info --environment-id e-muh8x9zmqx --info-type tail

# Download logs using curl (URLs expire quickly)
curl -s "https://elasticbeanstalk-us-east-1-xxx.s3.amazonaws.com/..." | tail -100
```

#### Method 2: CloudWatch Logs (More Reliable)
```bash
# List available log groups
aws logs describe-log-groups --log-group-name-prefix "/aws/elasticbeanstalk/mfd-fin-api-dev-1"

# Get latest log stream name
aws logs describe-log-streams \
  --log-group-name "/aws/elasticbeanstalk/mfd-fin-api-dev-1/var/log/web.stdout.log" \
  --order-by LastEventTime --descending --max-items 1 \
  --query 'logStreams[0].logStreamName' --output text

# Get recent log events
aws logs get-log-events \
  --log-group-name "/aws/elasticbeanstalk/mfd-fin-api-dev-1/var/log/web.stdout.log" \
  --log-stream-name "i-0c768d8c26d4edfa7" \
  --query 'events[-30:].message' --output text
```

### Key Log Groups for Node.js Apps
- `/aws/elasticbeanstalk/ENV-NAME/var/log/web.stdout.log` - **Application stdout/stderr** (most important)
- `/aws/elasticbeanstalk/ENV-NAME/var/log/nginx/error.log` - Nginx proxy errors
- `/aws/elasticbeanstalk/ENV-NAME/var/log/eb-hooks.log` - Deployment hooks (prebuild, predeploy)
- `/aws/elasticbeanstalk/ENV-NAME/var/log/eb-engine.log` - EB platform logs

## IAM & Permissions Debugging

### Check Role Existence & Policies
```bash
# Check if role exists
aws iam get-role --role-name mfd-fin-api-instanceRole

# List attached managed policies
aws iam list-attached-role-policies --role-name mfd-fin-api-instanceRole

# List inline policies (if any)
aws iam list-role-policies --role-name mfd-fin-api-instanceRole
```

## CloudFormation Stack Status
```bash
# Check CDK stack deployment status
aws cloudformation describe-stacks --stack-name mfd-fin-api-app-stack

# List stack resources (see what was created)
aws cloudformation list-stack-resources --stack-name mfd-fin-api-app-stack
```

## Common Debugging Patterns

### 1. Deployment Failures
1. Check `describe-events` for high-level errors
2. Look at `eb-hooks.log` for build/deploy script failures  
3. Check `web.stdout.log` for application startup errors

### 2. Runtime 5xx Errors
1. Check environment health with `describe-environment-health`
2. Look at `web.stdout.log` for application crashes/exceptions
3. Check `nginx/error.log` for proxy issues

### 3. Permission Issues
1. Look for "Access Denied" in logs
2. Check IAM role policies with `list-attached-role-policies`
3. For KMS issues, verify `get-key-policy` includes the role

### 4. Instance Health Problems
1. Use `describe-instances-health` for per-instance details
2. Check system metrics (CPU, load) vs application metrics
3. Look for ELB health check failures

## Pro Tips

### JSON Parsing
```bash
# Use jq for complex JSON parsing
aws elasticbeanstalk describe-events --environment-id e-muh8x9zmqx --output json | jq '.Events[0].Message'

# Use --query for simple filtering
aws iam list-attached-role-policies --role-name ROLE --query 'AttachedPolicies[].PolicyName'
```

### Time-based Log Filtering
```bash
# Get logs from last hour (timestamp in milliseconds)
--start-time $(($(date +%s - 3600)*1000))
```

### Output Formats
- `--output table` - Human readable tables
- `--output text` - Plain text (good for scripts)
- `--output json` - Full JSON (pipe to jq)# AWS CLI Debugging Guide

## 🚨 CRITICAL RULE
**NEVER make AWS changes via CLI without explicit user approval each time.** Only use for read-only debugging and information gathering.

## Stack

- Elastic Beanstalk for the API
- RDS with Postgres 13.7
- Route 53 for the domain ($STAGE.fin.manufactured.com)
- CloudWatch for the logs
- CDK for the stack at [bin/cdk](/bin/cdk)

## Elastic Beanstalk Debugging

### Environment Status & Events
```bash
# Get environment details
aws elasticbeanstalk describe-environments --environment-ids e-muh8x9zmqx

# Get recent deployment events (most useful for failures)
aws elasticbeanstalk describe-events --environment-id e-muh8x9zmqx --max-records 15

# Get detailed health status
aws elasticbeanstalk describe-environment-health --environment-id e-muh8x9zmqx --attribute-names All

# Get instance-level health details
aws elasticbeanstalk describe-instances-health --environment-id e-muh8x9zmqx --attribute-names All
```

### Log Access (Two Methods)

#### Method 1: EB Log Retrieval (Temporary S3 URLs)
```bash
# Request logs
aws elasticbeanstalk request-environment-info --environment-id e-muh8x9zmqx --info-type tail

# Wait a few seconds, then retrieve log URLs
aws elasticbeanstalk retrieve-environment-info --environment-id e-muh8x9zmqx --info-type tail

# Download logs using curl (URLs expire quickly)
curl -s "https://elasticbeanstalk-us-east-1-xxx.s3.amazonaws.com/..." | tail -100
```

#### Method 2: CloudWatch Logs (More Reliable)
```bash
# List available log groups
aws logs describe-log-groups --log-group-name-prefix "/aws/elasticbeanstalk/mfd-fin-api-dev-1"

# Get latest log stream name
aws logs describe-log-streams \
  --log-group-name "/aws/elasticbeanstalk/mfd-fin-api-dev-1/var/log/web.stdout.log" \
  --order-by LastEventTime --descending --max-items 1 \
  --query 'logStreams[0].logStreamName' --output text

# Get recent log events
aws logs get-log-events \
  --log-group-name "/aws/elasticbeanstalk/mfd-fin-api-dev-1/var/log/web.stdout.log" \
  --log-stream-name "i-0c768d8c26d4edfa7" \
  --query 'events[-30:].message' --output text
```

### Key Log Groups for Node.js Apps
- `/aws/elasticbeanstalk/ENV-NAME/var/log/web.stdout.log` - **Application stdout/stderr** (most important)
- `/aws/elasticbeanstalk/ENV-NAME/var/log/nginx/error.log` - Nginx proxy errors
- `/aws/elasticbeanstalk/ENV-NAME/var/log/eb-hooks.log` - Deployment hooks (prebuild, predeploy)
- `/aws/elasticbeanstalk/ENV-NAME/var/log/eb-engine.log` - EB platform logs

## IAM & Permissions Debugging

### Check Role Existence & Policies
```bash
# Check if role exists
aws iam get-role --role-name mfd-fin-api-instanceRole

# List attached managed policies
aws iam list-attached-role-policies --role-name mfd-fin-api-instanceRole

# List inline policies (if any)
aws iam list-role-policies --role-name mfd-fin-api-instanceRole
```

## CloudFormation Stack Status
```bash
# Check CDK stack deployment status
aws cloudformation describe-stacks --stack-name mfd-fin-api-app-stack

# List stack resources (see what was created)
aws cloudformation list-stack-resources --stack-name mfd-fin-api-app-stack
```

## Common Debugging Patterns

### 1. Deployment Failures
1. Check `describe-events` for high-level errors
2. Look at `eb-hooks.log` for build/deploy script failures  
3. Check `web.stdout.log` for application startup errors

### 2. Runtime 5xx Errors
1. Check environment health with `describe-environment-health`
2. Look at `web.stdout.log` for application crashes/exceptions
3. Check `nginx/error.log` for proxy issues

### 3. Permission Issues
1. Look for "Access Denied" in logs
2. Check IAM role policies with `list-attached-role-policies`
3. For KMS issues, verify `get-key-policy` includes the role

### 4. Instance Health Problems
1. Use `describe-instances-health` for per-instance details
2. Check system metrics (CPU, load) vs application metrics
3. Look for ELB health check failures

## Pro Tips

### JSON Parsing
```bash
# Use jq for complex JSON parsing
aws elasticbeanstalk describe-events --environment-id e-muh8x9zmqx --output json | jq '.Events[0].Message'

# Use --query for simple filtering
aws iam list-attached-role-policies --role-name ROLE --query 'AttachedPolicies[].PolicyName'
```

### Time-based Log Filtering
```bash
# Get logs from last hour (timestamp in milliseconds)
--start-time $(($(date +%s - 3600)*1000))
```

### Output Formats
- `--output table` - Human readable tables
- `--output text` - Plain text (good for scripts)
- `--output json` - Full JSON (pipe to jq)