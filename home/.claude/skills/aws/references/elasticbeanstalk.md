# Elastic Beanstalk

```bash
aws elasticbeanstalk describe-environments --application-name APP --environment-names ENV --region REGION --query 'Environments[0].[Status,Health,VersionLabel]' --output text
aws elasticbeanstalk describe-events --environment-id ID --max-records 15
aws elasticbeanstalk describe-environment-health --environment-id ID --attribute-names All
aws cloudformation describe-stacks --stack-name STACK --region REGION --query 'Stacks[0].StackStatus' --output text
```
Deploy failures: describe-events → eb-hooks.log → web.stdout.log. Runtime 5xx: describe-environment-health → web.stdout.log.
