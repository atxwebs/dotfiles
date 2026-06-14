# Infrastructure

- AWS: S3, CloudFront (CORS for Capacitor), RDS, SES, KMS, CDK
- Stages: local, dev, prod
- Domains: app.rovetia.com, dev.rovetia.com, www.rovetia.com
- CI/CD: GitHub Actions → S3/EB
- OTA: Capgo (manifest.json + version.zip; static, no backend)
- AI: Ollama local (dev); AI Gateway (prod)
- OCR: qwen3-vl-instruct (expensive, 235B minimum); cost optimization in progress
