---
name: rovetia
description: Read only when you need to really understand the product
---
# Rovetia

AI-assisted patient management for small practices (1–5 people). Converts unstructured data (notes, audio, images, labs, WhatsApp) into structured timelines. Web + iOS + Android. Bilingual ES/EN. Three repos: rovetia-api, rovetia-app, rovetia-www.

## Core Identity

- Web-first (PWA) + native mobile (iOS/Android), ES/EN
- AI assistive, never authoritative; human verification mandatory
- Built for small clinics, vets + human health (dietitians, psychologists, dermatologists)
- B2B first: guardians/patients don't login, orgs are the customer

## Problem

- Data scattered: WhatsApp, emails, PDFs, labs, photos, audio, Excel, paper
- Manual notes waste time; no clean longitudinal history
- Many use nothing or outdated systems (especially Argentina vets, dietitians)

## Value Proposition

- Saves time (AI drafting, OCR, ASR, summarization)
- Centralizes patient data
- Extracts structured facts from unstructured inputs
- Human review ensures trust/auditability
- Every fact traceable to source

## Target Market

- Small independent clinics (1–5 people)
- Vets + human health practitioners
- Focus: Argentina/Latin America (Spanish-first), globally scalable
- Not: large hospitals, heavy PMS, extreme customization
- Early adopters: Argentina vets, dietitians, psychologists via referrals

## Key Capabilities

- Multi-tenant: orgs, members, roles (Viewer/Member/Admin)
- Patients + guardians: many-to-many, species (Person/Dog/Cat), breed, avatar, contact import
- Uploads: PDF, images, audio, text; client-side OCR (Tesseract, pdfjs, mammoth, xlsx), Whisper transcription
- Timeline + search: chronological history, fast retrieval
- AI ingestion: audio→text, OCR, extractUpload (structured JSON), generatePatientEntry (AI notes), per-patient AI chat
- Appointments: FullCalendar, CRUD, patient-linked, external calendar conflicts (Events)
- Channels & messaging: per-patient/org-wide, WhatsApp webhooks (future: Rovetia account for forwarding)
- Credits/subscriptions: org credits, Freemium/Paid tiers
- Roadmap: treatment plans, pet owner portal (magic links)

## Product Model

- Organization (vet or forHumans; UI adapts)
- User, Membership (Viewer | Member | Admin) - users can belong to multiple orgs
- Patient, Guardian (owner) - many-to-many, org-scoped, not shared across orgs
- Upload (pdf, photo, audio, text, sheet; status: Pending/Processing/Completed/Failed)
- PatientEntry (clinical notes; manual or AI-generated)
- PatientItem (structured fact; status: Pending/Matched/Approved)
- Appointment, Event (external calendar blocks)
- Channel, Message (Web/AI/WhatsApp)
- Flow: upload → transcription/OCR → extraction → human review → PatientItem
- Audit: AiRequest logging (model, provider, tokens, cost, thinking)

## PatientItem Types

- Allergy, Behavior, ChronicCondition, Diagnosis, Diet, Disease, Lab, Measurement, Medication, Procedure, Symptom, Test, Vaccine, Other
- Fields: name, quote (from source), amount, min, max, unit, status, occurredAt
- Each linked to source upload

## Business Model

- Freemium: CRUD + manual notes, ~10 patients/org, no AI features
- Paid: subscription + prepaid credits (bulk import, transcription/OCR, extraction, labs, chat); extra bundles purchasable
- Credit consumption: proportional to AiRequest.cost (markup on underlying AI cost)
- Credit exhaustion: one-time monthly top-up; uploads allowed but no AI extraction/entry generation (manual typing)
- Pricing: not finalized, targeting Argentina market sensitivity

## Differentiation

- Unstructured→structured pipeline (not just transcription)
- Every fact traceable to source
- Prepaid credits = visible costs, no surprise bills
- Real competition: paper, Excel, WhatsApp chaos, legacy PMS (especially Argentina)
- Cheapest viable AI per task (see src/model/tuple.ts)

## Products

### rovetia-api (Backend)

- GraphQL (Apollo Server 5), Node 24, TS, Prisma 7
- PostgreSQL on RDS (sa-east-1)
- AWS: S3 (presigned), SES, KMS, CDK
- AI: Ollama local (dev) + AI Gateway fallbacks; Whisper; vision models (qwen3-vl-instruct for OCR)
- WhatsApp: Meta webhooks, two-way messaging (future: Rovetia account for forwarding)
- Auth: Google, Facebook live; Apple ready (blocked on Service ID); JWT
- Port 5005 (local), Elastic Beanstalk (prod)

Entities: User, Membership, Organization, Patient, Guardian, Upload, PatientEntry, PatientItem, Appointment, Event, Channel, Message, AiRequest, OrgSubscription (Freemium/Paid, patientLimit), CreditDelta, Integration (WhatsApp tokens), Notification, Device, Webhook, Mutation

### rovetia-app (Web + Mobile)

- Vite 7, React 19, Apollo Client 4, Zustand, Tailwind 4, Radix UI
- Forms: Formik + Zod
- Routing: React Router v7
- Mobile: Capacitor 8, Capgo (OTA, push)
- Native: Camera, document scanner, contacts, speech recognition, share, haptics, toast, splash, status bar, deep links
- OCR: Tesseract (all platforms), pdfjs, mammoth, xlsx
- Audio: @capgo/capacitor-audio-recorder + Whisper
- Dictation: Web Speech (web), @capgo/capacitor-speech-recognition (native)
- Calendar: FullCalendar (interaction/timegrid)
- Deploy: S3 + CloudFront (app.rovetia.com, dev.rovetia.com); SPA routing (403/404→index.html)
- Platforms: Android native (Play Store approved), iOS on hold (requires org account/LLC/SRL), PWA on iOS (mic permission asks on reload)

### rovetia-www (Marketing)

- Eleventy, Tailwind 3, TS
- Bilingual static (EN/ES): rovetia.com
- Blog: SEO articles (vet + human health)
- Deploy: S3 + CloudFront

## Infrastructure

- AWS: S3, CloudFront (CORS for Capacitor), RDS, SES, KMS, CDK
- Stages: local, dev, prod
- Domains: app.rovetia.com, dev.rovetia.com, www.rovetia.com
- CI/CD: GitHub Actions → S3/EB
- OTA: Capgo (manifest.json + version.zip; static, no backend)
- AI: Ollama local (dev); AI Gateway (prod)
- OCR: qwen3-vl-instruct (expensive, 235B minimum); cost optimization in progress

## AI Pipeline

- Ollama local (dev) + AI Gateway fallbacks (prod)
- Model tuples: general, events, entries, extractUpload, messages (src/model/tuple.ts)
- Structured output: Zod→JSON Schema; ai-sdk-ollama (local), inlined schemas (cloud)
- Tracking: AiRequest (tokens, cost, duration, finishReason)
- Top models (2026): mistral/devstral-small-2 (~1.4s, ~$0.00017), nvidia/nemotron-nano-9b-v2 (~2.6s, ~$0.0002)
- Avoid: qwen3.5-plus (66s, $0.01), nemotron-3-nano-30b (Method Not Allowed)
- OCR: qwen3-vl-instruct (expensive but necessary for image/PDF)
- Cost optimization: cheapest viable AI per task, markup on cost for credits

## Values

- Efficiency / smart automation
- Continuous learning (practice + system improve)
- Modernity (2026+ without enterprise complexity)
- Pragmatism: one-man band with full-time job, focus on 0→1 users first

## Brand

- Professional, modern, reliable, simple
- Green (health, trust), subtle violet accents
- Avoid childish vet clichés; compatible with human health

## Constraints

- Not full PMS (no billing/inventory in MVP)
- Not diagnostic authority
- Cost-aware AI; browser-first OCR/ASR
- Compliance: HIPAA/GDPR deferred until post-product-market-fit

## Status (2026)

- Play Store: approved (native Android)
- App Store: on hold (requires org account, LLC/SRL pending profitability)
- Auth: Google, Facebook live; Apple ready (blocked on Service ID)
- WhatsApp: infrastructure ready, user delegation on ice; future: Rovetia account for forwarding
- Appointments: live (FullCalendar, CRUD)
- AI ingestion: live (audio, OCR, extraction, chat)
- Users: 0 real users, early bird testing with known contacts

## Roadmap

- Appointments: pre-appointment summary, post-reminder, reschedule chat
- WhatsApp: Rovetia account for user forwarding (avoid app usage)
- Pet owner portal: magic link read-only views
- App updates: native version detection + store prompts
- Treatment plans: deferred (too futuristic)
- iOS native: deferred until LLC/SRL + profitability
