# IAM

```bash
aws iam get-role --role-name ROLE
aws iam list-attached-role-policies --role-name ROLE
aws iam list-role-policies --role-name ROLE
aws iam get-role-policy --role-name ROLE --policy-name POLICY --output json | jq '.PolicyDocument'
```
Access denied → check list-attached-role-policies. KMS: verify get-key-policy includes role.
