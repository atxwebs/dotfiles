---
name: pubmed
description: Read when hitting the local OpenMed API
---

# OpenMed

Medical NLP toolkit (disease, drug, PII extraction). Runs as Docker REST API.

Port **18080**. Setup: [install](./references/install.md).

## Endpoints

| Endpoint | Purpose |
|----------|---------|
| `GET /health` | Health check |
| `POST /analyze` | Medical NER (diseases, drugs, anatomy, genes) |
| `POST /pii/extract` | PII detection (names, dates, SSN, etc.) |
| `POST /pii/deidentify` | De-identify text (mask, remove, replace, hash) |
| `POST /unload` | Unload model / restart container (gateway) |

## Example Requests

**Analyze (disease):**
```bash
curl -X POST http://localhost:18080/analyze -H "Content-Type: application/json" -d '{"text":"Patient started on imatinib for chronic myeloid leukemia.","model_name":"disease_detection_superclinical"}' --max-time 60
```

**PII extract (Spanish):**
```bash
curl -X POST http://localhost:18080/pii/extract \
  -H "Content-Type: application/json" \
  -d '{"text":"Paciente: Maria Garcia, DNI: 12345678Z","lang":"es"}'
```

## Models

Full list: [models](./references/models.md).

**Supported:** disease_detection_superclinical, pharma_detection_superclinical, anatomy_detection_electramed, PII (pii_superclinical_small). PII lang: en, es, fr, de, it, nl, hi, te.

Repo: https://github.com/rovetia/pubmed
