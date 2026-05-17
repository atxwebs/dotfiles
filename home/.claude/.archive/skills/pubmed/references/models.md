# OpenMed Models

## Use case: extract from documents/audio

- **Personal info** (PII): names, addresses, SSN, dates, etc.
- **Blood test results**: values, units, conditions
- **Ecography measurements**: organs, dimensions
- **Diseases, allergies**: conditions, drug reactions

## Recommended models

| Model | Registry key | Extracts |
|-------|--------------|----------|
| **PiiDetection** | pii_superclinical_small | Names, dates, SSN, phone, email, address |
| **DiseaseDetection** | disease_detection_superclinical | DISEASE, CONDITION, PATHOLOGY |
| **PharmaDetection** | pharma_detection_superclinical | DRUG, MEDICATION, CHEM (allergies, meds) |
| **PathologyDetection** | pathology_detection_modern | DISEASE, PATHOLOGY (findings) |
| **BloodCancerDetection** | blood_cancer_detection | Cancer, DISEASE (blood tests, hematology) |
| **AnatomyDetection** | anatomy_detection_electramed | Organ, Tissue, ANATOMY (ecography) |

**Measurements** (e.g. "5.2cm", "120 mg/dL"): NER extracts entity names, not numbers. Use regex or a separate extraction step for numeric values. Anatomy helps identify *what* is measured (e.g. "left ventricle").

## We support

- DiseaseDetection, PharmaDetection, PathologyDetection, PiiDetection
- **Add:** BloodCancerDetection (blood tests), AnatomyDetection (ecography)

## PII size

- **small** (default): Fast, covers names/dates/SSN/address. Test first.
- **large**: Adds city, state, postcode, account_number, credit_debit_card. Use if small misses entities.

## VRAM / inactivity

Gateway auto-stops OpenMed after 5 min idle. First request after idle waits ~30s for container start. `pubmed.unload()` forces unload via `POST /unload`.
