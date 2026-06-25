# Product

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
- **Currently focused on veterinary clinics** (narrowed from vets + human health for Apple approval, cleaner ICP, and messaging focus)
- Focus: Argentina/Latin America (Spanish-first), globally scalable
- Not: large hospitals, heavy PMS, extreme customization
- Early adopter profile: Younger vets (<10 years experience, recent graduates) — no entrenched workflow, more open to tech/AI
- Human health (dietitians, psychologists, dermatologists) on hold until vets validated

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
