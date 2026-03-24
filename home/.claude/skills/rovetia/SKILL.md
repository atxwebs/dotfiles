---
name: rovetia
description: Read only when you need to really understand the product
---

# Rovetia

**AI-assisted patient management for small health practices** — converts unstructured data (notes, audio, images, labs, WhatsApp) into structured, searchable timelines. Web + iOS + Android app. Bilingual ES/EN.

## Core Identity

* Web-first with native mobile apps (iOS + Android)
* AI is assistive, never authoritative; human-in-the-loop verification mandatory
* Built for small practices (1–5 professionals)
* Supports veterinary and human-health (dietitians, psychologists, dermatologists, etc.)

## Core Problem

* Data lives in WhatsApp, emails, PDFs, lab files, photos, audio notes, Excel, paper
* Manual note-writing wastes time
* No clean longitudinal structured history
* Many small practices use nothing or outdated systems

## Core Value Proposition

* Saves time (AI drafting, OCR, ASR, summarization)
* Centralizes all patient data
* Extracts structured data from unstructured inputs into clean timelines and lists
* Human verification ensures trust and auditability

## Target Market

* Small independent clinics and micro-teams (1–5 people)
* Veterinarians and human-health practitioners
* Initial focus: Argentina/Latin America (Spanish-first), global scalability
* Not large hospital chains or heavy enterprise PMS

## Key Capabilities

* **Multi-tenant workspace**: organizations, members, roles (Viewer/Member/Admin)
* **Patients + guardians**: profiles, species (Person/Dog/Cat), breed, avatar
* **Notes + uploads**: attach PDFs, images, audio, text; track processing status
* **Timeline + search**: fast retrieval and chronological history
* **AI ingestion**: audio transcription, OCR, structured extraction, AI-composed notes, per-patient AI chat
* **Appointments**: calendar, CRUD, patient-linked; external calendar conflict detection
* **Channels & messaging**: per-patient or org-wide; WhatsApp integration
* **Credits & subscriptions**: org-level credits, subscription tiers (Freemium/Paid)

## Product Model

* Organization (adapts terminology for veterinary vs human-health)
* User, Membership (Viewer | Member | Admin)
* Patient, Guardian (owner)
* Upload (pdf, photo, audio, text, sheet)
* PatientEntry (clinical notes; manual or AI-generated)
* PatientItem (structured facts: Allergy, Lab, Vaccine, Medication, etc.; status: Pending/Matched/Approved)
* Appointment, Event (external calendar blocks)
* Channel, Message (Web/AI/WhatsApp)
* Full audit trail

## What It Is NOT

* A full EHR replacement for large hospitals (optimized for small teams)
* A billing/inventory system
* A diagnostic authority

## Business Model

* **Freemium**: basic patient CRUD + manual notes; limit (~10 patients/org); no AI ingestion
* **Paid**: monthly subscription + prepaid credits for AI-heavy actions (bulk import, transcription/OCR, extraction, chat)

## Differentiation

* Holistic unstructured-to-structured pipeline (not just transcription)
* Trust + reviewability: every extracted fact traceable to source
* Pragmatic monetization: prepaid credits keep costs visible
* Real competition: paper, Excel, WhatsApp chaos, mediocre legacy PMS

## Technical Overview

* **Repos**: API (`rovetia-api`), App (`rovetia-app`), Marketing (`rovetia-www`)
* **Infrastructure**: AWS (S3, SES, RDS, CDK), PostgreSQL
* **Stack**: GraphQL API, TypeScript, React (web + Capacitor mobile)
* **AI**: Local Ollama + cloud fallback; vision models, Whisper, client-side OCR

## Status (2026)

* ✅ Patient/Guardian CRUD, Uploads, Timeline, AI ingestion
* ✅ Appointments (calendar, CRUD)
* ✅ WhatsApp integration (channels, webhooks)
* ✅ Auth: Google, Facebook; Apple ready
* 🚧 Play Store: close to publish; App Store: awaiting enrollment
* 🚧 Treatment plans, pet owner portal
* 🚧 Marketing site: bilingual static (rovetia.com)

## Core Values

* Efficiency / smart automation
* Continuous learning (practice improves with use)
* Modernity (bring small practices into 2026+ without enterprise complexity)
