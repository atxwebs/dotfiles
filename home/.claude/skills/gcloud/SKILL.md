---
name: gcloud
description: Use Google Cloud CLI for service accounts, project management, and API enablement. Read when working with gcloud, GCP, or Play Console API setup.
---
# Google Cloud CLI

**Multiple Accounts:**
```bash
gcloud auth list          # List all authenticated accounts
gcloud config set account EMAIL  # Switch active account
```

**Service Accounts:**
```bash
# Create service account
gcloud iam service-accounts create SERVICE_ACCOUNT_NAME \
  --display-name="Display Name" \
  --project=PROJECT_ID

# Enable Play Developer API
gcloud services enable androidpublisher.googleapis.com --project=PROJECT_ID

# Create and download JSON key
gcloud iam service-accounts keys create KEY_FILE.json \
  --iam-account=SERVICE_ACCOUNT_NAME@PROJECT_ID.iam.gserviceaccount.com
```

**Common Commands:**
```bash
gcloud projects list
gcloud config set project PROJECT_ID
gcloud auth list
gcloud services list --enabled
gcloud iam service-accounts list
```

**Note:** Play Console access grant (Setup → API access) must be done manually via UI; cannot be automated via CLI.
