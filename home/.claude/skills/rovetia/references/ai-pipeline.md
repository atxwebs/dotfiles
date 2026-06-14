# AI Pipeline

- Ollama local (dev) + AI Gateway fallbacks (prod)
- Model tuples: general, events, entries, extractUpload, messages (src/model/tuple.ts)
- Structured output: Zod→JSON Schema; ai-sdk-ollama (local), inlined schemas (cloud)
- Tracking: AiRequest (tokens, cost, duration, finishReason)

## Models (2026)

- Top: mistral/devstral-small-2 (~1.4s, ~$0.00017), nvidia/nemotron-nano-9b-v2 (~2.6s, ~$0.0002)
- Avoid: qwen3.5-plus (66s, $0.01), nemotron-3-nano-30b (Method Not Allowed)
- OCR: qwen3-vl-instruct (expensive but necessary for image/PDF)
- Cost optimization: cheapest viable AI per task, markup on cost for credits
