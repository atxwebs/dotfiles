# rovetia-api

Backend: GraphQL (Apollo Server 5), Node 24, TS, Prisma 7.

- PostgreSQL on RDS (sa-east-1)
- AWS: S3 (presigned), SES, KMS, CDK
- AI: Ollama local (dev) + AI Gateway fallbacks; Whisper; vision models (qwen3-vl-instruct for OCR)
- WhatsApp: Meta webhooks, two-way messaging (future: Rovetia account for forwarding)
- Auth: Google, Facebook live; Apple ready (blocked on Service ID); JWT
- Port 5005 (local), Elastic Beanstalk (prod)

Entities: User, Membership, Organization, Patient, Guardian, Upload, PatientEntry, PatientItem, Appointment, Event, Channel, Message, AiRequest, OrgSubscription (Freemium/Paid, patientLimit), CreditDelta, Integration (WhatsApp tokens), Notification, Device, Webhook, Mutation
