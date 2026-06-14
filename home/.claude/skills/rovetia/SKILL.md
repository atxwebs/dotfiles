---
name: rovetia
description: Read only when you need to really understand the product
---

# Rovetia

AI-assisted patient management for small practices. Three repos: rovetia-api, rovetia-app, rovetia-www.

## Routing

| Task | READ |
| --- | --- |
| What is Rovetia, who is it for, core capabilities | [product](./references/product.md) |
| Entities, PatientItem types, data flow | [domain-model](./references/domain-model.md) |
| Pricing, credits, differentiation | [business](./references/business.md) |
| Backend, GraphQL, Prisma, AWS | [api](./references/api.md) |
| Web/mobile app stack, Capacitor | [app](./references/app.md) |
| Marketing site | [www](./references/www.md) |
| Deploy, domains, stages | [infrastructure](./references/infrastructure.md) |
| AI models, tuples, costs | [ai-pipeline](./references/ai-pipeline.md) |
| Brand, values, MVP limits | [brand-constraints](./references/brand-constraints.md) |
| Current status, roadmap | [status-roadmap](./references/status-roadmap.md) |

## Principles

- AI assistive, never authoritative; human verification mandatory
- Every fact traceable to source upload
- B2B: orgs are the customer; guardians/patients don't login
- Cheapest viable AI per task (see src/model/tuple.ts in api repo)

## References

- [product](./references/product.md) — identity, problem, market, capabilities
- [domain-model](./references/domain-model.md) — entities, PatientItem types, flow
- [business](./references/business.md) — freemium/paid, credits
- [api](./references/api.md) — rovetia-api stack and entities
- [app](./references/app.md) — rovetia-app stack
- [www](./references/www.md) — marketing site
- [infrastructure](./references/infrastructure.md) — AWS, domains, CI/CD
- [ai-pipeline](./references/ai-pipeline.md) — models, tuples, costs
- [brand-constraints](./references/brand-constraints.md) — values, brand, MVP limits
- [status-roadmap](./references/status-roadmap.md) — 2026 status and roadmap
