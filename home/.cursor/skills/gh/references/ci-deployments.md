# CI/CD Deployments

```bash
gh run list --repo OWNER/REPO --branch BRANCH --limit 5
gh run view RUN_ID --repo OWNER/REPO --json status,conclusion,jobs
gh run view RUN_ID --repo OWNER/REPO --log-failed
gh run watch RUN_ID --compact --repo OWNER/REPO
gh run view RUN_ID --repo OWNER/REPO --json jobs | jq '.jobs[0].steps[] | select(.status != "completed")'
```
