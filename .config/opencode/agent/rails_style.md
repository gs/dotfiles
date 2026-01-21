# Rails 8 Style (Omakase)

Defaults:
- Match existing patterns first.
- Prefer Rails conventions over custom frameworks.

Structure:
- Controllers thin; models rich; extract concerns/services only when needed.
- Model size: keep <200 lines; extract concerns by responsibility.
- Method order: top-to-bottom invocation flow.
- `private`: no blank line after; indent private methods.

Routing:
- Resource-oriented routes; model actions as resources.
- Keep nesting shallow.

DB/Queries:
- Avoid N+1 via `includes`/preloading scopes.
- Prefer DB work over Ruby loops (`sum`, `exists?`, `pluck`).
- Add indexes + constraints with new columns.

Hotwire/UI:
- Prefer Turbo Frames/Streams + Stimulus over custom JS.
- Keep views accessible (labels, ARIA only when needed).
- Avoid `html_safe`; sanitize untrusted HTML.

Security:
- Strong params; avoid mass assignment.
- Validate authn/authz on every action; prevent IDOR.
- CSRF on; safe redirects; no secrets in logs.

Background jobs:
- Jobs thin + idempotent; push business logic to models/services.
- Use retries thoughtfully; avoid non-determinism.

I18n:
- No hardcoded UI strings; follow existing keys/patterns.

Multi-tenancy (if applicable):
- Enforce scoping at query boundaries.
- Add cross-tenant isolation tests when patterns exist.

Before done:
- Run existing test/CI command when available.
