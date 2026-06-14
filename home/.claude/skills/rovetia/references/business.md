# Business Model

## Tiers

- Freemium: CRUD + manual notes, ~10 patients/org, no AI features
- Paid: subscription + prepaid credits (bulk import, transcription/OCR, extraction, labs, chat); extra bundles purchasable

## Credits

- Consumption proportional to AiRequest.cost (markup on underlying AI cost)
- Exhaustion: one-time monthly top-up; uploads allowed but no AI extraction/entry generation (manual typing)
- Pricing: not finalized, targeting Argentina market sensitivity

## Differentiation

- Unstructured→structured pipeline (not just transcription)
- Every fact traceable to source
- Prepaid credits = visible costs, no surprise bills
- Real competition: paper, Excel, WhatsApp chaos, legacy PMS (especially Argentina)
- Cheapest viable AI per task (see src/model/tuple.ts)
