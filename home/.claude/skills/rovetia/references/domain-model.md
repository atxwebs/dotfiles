# Domain Model

## Entities

- Organization (vet or forHumans; UI adapts)
- User, Membership (Viewer | Member | Admin) — users can belong to multiple orgs
- Patient, Guardian (owner) — many-to-many, org-scoped, not shared across orgs
- Upload (pdf, photo, audio, text, sheet; status: Pending/Processing/Completed/Failed)
- PatientEntry (clinical notes; manual or AI-generated)
- PatientItem (structured fact; status: Pending/Matched/Approved)
- Appointment, Event (external calendar blocks)
- Channel, Message (Web/AI/WhatsApp)
- Flow: upload → transcription/OCR → extraction → human review → PatientItem
- Audit: AiRequest logging (model, provider, tokens, cost, thinking)

## PatientItem Types

Allergy, Behavior, ChronicCondition, Diagnosis, Diet, Disease, Lab, Measurement, Medication, Procedure, Symptom, Test, Vaccine, Other

Fields: name, quote (from source), amount, min, max, unit, status, occurredAt. Each linked to source upload.
