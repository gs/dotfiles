---
name: select-task-model
description: Use when selecting or escalating OpenAI or Ollama Cloud models for coding, review, security, or repository research tasks.
---

# Select task model

Select using task evidence, not model names. Keep assignments outside skill prose in the repository's routing policy (for example `.pi/delivery.json`).

## Selection procedure

1. Classify role, complexity, sensitive data, required tools, and context needs. Security-sensitive changes require a security-qualified reviewer; small diffs are not automatically low risk.
2. Inspect the actual available catalog and approved providers. Catalog presence means configured, not tested. Ollama **Cloud** sends data off-machine; it is not local execution.
3. Read accepted qualification evidence for the exact provider/model, role, and harness version. Require reliable tool use, task correctness, and review defect/false-positive results. Without evidence, status is **BLOCKED**. Name-based candidates may be listed as **UNQUALIFIED**, never selected for dispatch.
4. Among qualified candidates, choose the lowest measured cost per accepted task that meets quality requirements. Include retries, review overhead, cached input, output, elapsed time and subscription quota. Unknown prices remain unknown, not zero.
5. Research/design uses the user's preferred `openai-codex/gpt-6-astra`; verify availability and disclose that preference is not comparative qualification. Automated execution/review still requires its role-specific evidence.
6. Specify provider/model explicitly on every dispatch. No silent fallback, including within one provider. Escalation outside approved routing/budget requires renewed approval. A failed agent needs new context, a smaller task, or an approved stronger model—not an identical retry loop.

## Decision record

Record: status (`SELECTED` or `BLOCKED`), task/role/risk, exact provider/model (or none), qualification evidence, approved data boundary, measured cost/latency or unknown, per-agent/run limits, reason, and escalation condition. Keep it brief and reference evidence files.

## Common mistakes / stop signals

| Temptation | Required response |
|---|---|
| “Code means best coder; Flash means cheap” | Labels do not qualify a model or establish price. |
| “The client is waiting; use a provisional route” | Missing evidence or provider approval blocks dispatch. |
| “Ollama is private” | Distinguish cloud hosting from local inference. |

Example: catalog lists Kimi and GLM but has no evaluations → `BLOCKED; model: none; candidates: UNQUALIFIED`. Propose a bounded qualification run with approval rather than starting production work.
