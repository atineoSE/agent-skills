---
name: anthropic-guidelines
version: 1.0.0
description: Evaluate and design agentic workflows against Anthropic's recommendations for agent architecture, tool/MCP design, Claude Code configuration, prompt engineering, structured output, and context management/reliability. Use when designing, reviewing, or critiquing an agentic system, multi-agent orchestration, tool interfaces, or a Claude Code / Agent SDK workflow, or when the user asks "is this design sound?" / "review this agent design against Anthropic best practices".
user-invocable: true
allowed-tools: Read, Grep, Glob
---

# Anthropic Agentic Design Guidelines

> **Skill version: 1.0.0** — distilled on **2026-07-15** from
> `anthropic_guidelines.pdf` (Anthropic agentic-systems design reference,
> Domains 1–5: Agentic Architecture & Orchestration, Tool Design & MCP
> Integration, Claude Code Configuration & Workflows, Prompt Engineering &
> Structured Output, Context Management & Reliability).
>
> **Keep this in sync.** Whenever you learn a new Anthropic recommendation, a
> revised best practice, a new Agent SDK / Claude Code capability, or anything
> that contradicts what's written here, **update this file and bump the
> version** (patch for corrections/clarifications, minor for new
> guidelines/criteria, major for a changed recommendation that reverses prior
> guidance) before finishing the task. Note the date and source you verified
> against in the line above. These guidelines evolve as the platform and models
> evolve — treat anything more than a few months old as needing re-verification.

## What this is

A checklist-based **evaluation framework** for judging whether an agentic
design follows Anthropic's recommendations. Every item below is phrased so you
can score a concrete design against it: a ✅ **Recommend** rule (what a good
design does) paired with the ⚠️ **Anti-pattern** it replaces (what to flag).

Use it two ways:
1. **Design review** — given a proposed or existing agent/workflow, walk the
   relevant domains and produce findings (see *Review output* at the end).
2. **Design guidance** — when building something new, pull the criteria for the
   domains you're touching and satisfy them up front.

## How to run an evaluation

1. **Identify which domains apply.** Most designs touch a subset. Map the design
   to domains 1–5 below; skip domains with no surface area.
2. **Walk each applicable criterion.** For each, decide: satisfied / violated /
   not-applicable. A violation is usually the presence of a listed anti-pattern.
3. **Prioritize by consequence.** Flag hardest: anything relying on probabilistic
   LLM compliance where a **deterministic guarantee** is required (money, identity,
   irreversible actions), and anything that **silently** drops information or errors.
4. **Recommend the specific fix**, not "improve the prompt." The anti-pattern
   entries name the concrete replacement.

---

## Domain 1 — Agentic Architecture & Orchestration

### 1.1 Agentic loop control flow
- ✅ Drive the loop off `stop_reason`: continue while `stop_reason == "tool_use"`, terminate when `stop_reason == "end_turn"`.
- ✅ Append each tool result back into conversation history so the model reasons about the next action with the new information.
- ✅ Prefer **model-driven** next-action decisions (Claude picks the tool from context) over hard-coded decision trees / fixed tool sequences — unless determinism is required (see 1.4).
- ⚠️ Flag: parsing natural-language signals to decide when to stop; using an arbitrary iteration cap as the *primary* stopping mechanism; checking assistant *text content* as a completion indicator. (An iteration cap is fine as a safety backstop, not as the stop condition.)

### 1.2 Multi-agent (coordinator ↔ subagent)
- ✅ Use hub-and-spoke: a coordinator manages **all** inter-subagent communication, error handling, and information routing (for observability + consistent error handling + controlled flow).
- ✅ Coordinator dynamically **selects which subagents to invoke** based on query complexity, rather than always routing every query through the full pipeline.
- ✅ Partition research/work scope across subagents to minimize duplication (distinct subtopics / source types per agent).
- ✅ Implement **iterative refinement**: coordinator evaluates synthesis for gaps and re-delegates targeted queries until coverage is sufficient.
- ⚠️ Flag: overly narrow task decomposition that leaves broad topics with incomplete coverage; subagents talking to each other directly (bypassing the coordinator).
- ⚠️ Remember: subagents run with **isolated context** — they do **not** inherit the coordinator's conversation history.

### 1.3 Subagent invocation, context passing, spawning
- ✅ To spawn subagents, the coordinator's `allowedTools` must include `"Task"`; subagents are spawned via the `Task` tool.
- ✅ Pass **complete findings explicitly in the subagent's prompt** — subagents do not inherit parent context or share memory. (E.g. paste the web-search results / document-analysis outputs into the synthesis subagent's prompt.)
- ✅ Use **structured data formats** to separate content from metadata (source URLs, doc names, page numbers) when passing context, to preserve attribution.
- ✅ Spawn parallel subagents by emitting **multiple `Task` calls in a single coordinator response** (not across separate turns).
- ✅ Write coordinator→subagent prompts as **goals + quality criteria**, not step-by-step procedures, so subagents can adapt.
- ✅ Use **fork-based sessions** to explore divergent approaches from a shared analysis baseline.
- ⚠️ Flag: assuming a subagent "knows" anything the prompt didn't contain.

### 1.4 Multi-step workflows: enforcement vs guidance, handoff
- ✅ Use **programmatic enforcement** (hooks, prerequisite gates) when deterministic compliance is required; use prompt-based guidance only for soft ordering.
- ✅ Gate downstream tools on prerequisites (e.g., block `process_refund` until `get_customer` has returned a **verified** customer ID).
- ✅ Decompose multi-concern requests into distinct items, investigate each (in parallel, shared context), then synthesize one unified resolution.
- ✅ On escalation, compile a **structured handoff summary** (customer ID, root cause, amount, recommended action) for humans who lack the transcript.
- ⚠️ Flag: relying on prompt instructions alone for critical ordering (identity-before-financial, etc.) — prompts have a **non-zero failure rate**. This is *the* canonical mistake (see Sample Q below).

### 1.5 Agent SDK hooks (interception & normalization)
- ✅ Use `PostToolUse` hooks to **normalize heterogeneous tool outputs** (Unix timestamps, ISO 8601, numeric status codes) before the model sees them.
- ✅ Use tool-call-interception hooks to **block policy-violating actions** (e.g. refunds > $500) and redirect to an alternative flow (human escalation).
- ✅ Choose hooks over prompt-based enforcement whenever business rules require **guaranteed** compliance.
- ⚠️ Flag: enforcing a hard business/compliance rule purely in the system prompt.

### 1.6 Task decomposition strategy
- ✅ Match the pattern to the work:
  - **Fixed sequential pipeline (prompt chaining)** → predictable multi-aspect reviews (analyze each file, then a cross-file integration pass).
  - **Dynamic adaptive decomposition** → open-ended investigation where subtasks depend on what's discovered.
- ✅ Split large code reviews into **per-file local passes + a separate cross-file integration pass** to avoid attention dilution.
- ✅ For open-ended tasks ("add comprehensive tests to a legacy codebase"): map structure → identify high-impact areas → build a prioritized plan that adapts as dependencies surface.
- ⚠️ Flag: one monolithic pass over many files (attention dilution, contradictory findings).

### 1.7 Session state, resumption, forking
- ✅ Resume a named session with `--resume <session-name>` when prior context is **mostly still valid**.
- ✅ Use `fork_session` to branch independent explorations from a shared baseline (compare two testing/refactoring approaches).
- ✅ When resuming after file edits, **inform the agent which files changed** for targeted re-analysis rather than full re-exploration.
- ✅ Prefer **starting fresh with a structured summary** over resuming when prior tool results are **stale**.
- ⚠️ Flag: resuming a session whose tool results no longer reflect the code on disk.

---

## Domain 2 — Tool Design & MCP Integration

### 2.1 Tool interfaces, descriptions, boundaries
- ✅ Treat the **tool description as the primary selection signal**. Include purpose, input formats, example queries, edge cases, and boundary explanations ("use this vs that alternative").
- ✅ Make each tool's purpose **distinct** — differentiate expected inputs/outputs and when to use it over similar tools.
- ✅ Eliminate functional overlap: rename + re-scope (e.g. `analyze_content` → `extract_web_results` with a web-specific description).
- ✅ Split generic tools into purpose-specific ones with defined I/O contracts (e.g. `analyze_document` → `extract_data_points`, `summarize_content`, `verify_claim_against_source`).
- ⚠️ Flag: minimal/ambiguous descriptions; two tools with near-identical descriptions (`analyze_content` vs `analyze_document`) → misrouting.
- ⚠️ Flag: keyword-sensitive **system-prompt** wording that overrides good tool descriptions and creates unintended tool associations — review the system prompt for this.

### 2.2 Structured error responses (MCP)
- ✅ Use the MCP `isError` flag to signal failures to the agent.
- ✅ Return **structured error metadata**: `errorCategory` (transient / validation / business / permission), an `isRetryable` / `retriable` boolean, and a human-readable description.
- ✅ Include `retriable: false` + a customer-friendly explanation for business-rule violations so the agent can communicate appropriately.
- ✅ Implement **local recovery in subagents** for transient failures; propagate to the coordinator only what can't be resolved locally, **with partial results and what was attempted**.
- ✅ Distinguish **access failures** (need a retry decision) from **valid empty results** (successful query, no matches).
- ⚠️ Flag: uniform/generic errors ("Operation failed") — they block appropriate recovery decisions and waste retries.

### 2.3 Tool distribution across agents + `tool_choice`
- ✅ Give each agent only the tools its role needs. Too many tools (e.g. 18 vs 4–5) degrades selection reliability by increasing decision complexity.
- ✅ Prevent cross-specialization misuse (a synthesis agent shouldn't hold web-search tools).
- ✅ Replace generic tools with constrained alternatives (`fetch_url` → `load_document` that validates URLs).
- ✅ Provide **scoped cross-role tools** for genuine high-frequency needs (e.g. a `verify_fact` tool on the synthesis agent) while routing complex cases through the coordinator.
- ✅ Use `tool_choice`:
  - `"auto"` — model may return text or call a tool.
  - `"any"` — force *a* tool call (guarantee no bare conversational text).
  - `{"type": "tool", "name": "..."}` — force a **specific** tool first (e.g. `extract_metadata` before enrichment), then continue in follow-up turns.
- ⚠️ Flag: broad tool access "just in case"; agents holding tools outside their specialization.

### 2.4 MCP server integration
- ✅ Scope servers correctly: **project-level `.mcp.json`** for shared team tooling; **user-level `~/.claude.json`** for personal/experimental servers.
- ✅ Use **env-var expansion** in `.mcp.json` (`${GITHUB_TOKEN}`) for credentials — never commit secrets.
- ✅ Expose content catalogs (issue summaries, doc hierarchies, DB schemas) as **MCP resources** to cut exploratory tool calls.
- ✅ Write **detailed MCP tool descriptions** (capabilities + outputs) so the agent doesn't default to weaker built-ins (e.g. `Grep`) over a more capable MCP tool.
- ✅ Prefer existing community MCP servers for standard integrations (Jira, etc.); reserve custom servers for team-specific workflows.
- ⚠️ Remember: tools from **all** configured MCP servers are discovered at connection time and available simultaneously — scope deliberately.

### 2.5 Built-in tools (Read, Write, Edit, Bash, Grep, Glob)
- ✅ `Grep` for content search (function names, error strings, imports); `Glob` for path/name patterns (`**/*.test.tsx`).
- ✅ `Read`/`Write` for full-file ops; `Edit` for targeted edits via **unique** text matching. When `Edit` can't find unique anchor text, fall back to `Read` + `Write`.
- ✅ Build understanding **incrementally**: `Grep` for entry points, then `Read` to follow imports/trace flows — don't read all files upfront.
- ✅ Trace usage across wrapper modules by first listing exported names, then searching each across the codebase.

---

## Domain 3 — Claude Code Configuration & Workflows

### 3.1 CLAUDE.md hierarchy & modularity
- ✅ Know the hierarchy: user-level `~/.claude/CLAUDE.md`, project-level `.claude/CLAUDE.md` or root `CLAUDE.md`, directory-level subdirectory `CLAUDE.md`.
- ✅ User-level instructions are **personal** — not shared via version control. Team conventions belong in project-level.
- ✅ Use `@import` to keep CLAUDE.md modular (import per-package standards files); use `.claude/rules/` for topic-specific rule files instead of a monolith (`testing.md`, `api-conventions.md`, `deployment.md`).
- ⚠️ Flag: a new teammate not getting conventions because they live in *user-level* rather than *project-level* config. Use `/memory` to verify which files are loaded.

### 3.2 Custom slash commands & skills
- ✅ Project-scoped commands in `.claude/commands/` (shared via VC) vs user-scoped in `~/.claude/commands/` (personal).
- ✅ Skills live in `.claude/skills/` as `SKILL.md` with frontmatter: `context: fork`, `allowed-tools`, `argument-hint`.
- ✅ Use `context: fork` to isolate skills that produce **verbose or exploratory output** (codebase analysis, brainstorming) so they don't pollute the main conversation.
- ✅ Use `allowed-tools` to restrict tool access during skill execution (e.g. prevent destructive ops); use `argument-hint` to prompt for required params.
- ✅ Choose **skills** for on-demand, task-specific workflows; **CLAUDE.md** for always-loaded universal standards. Personal skill variants go in `~/.claude/skills/` with different names.

### 3.3 Path-specific rules
- ✅ Use `.claude/rules/` files with YAML frontmatter `paths:` glob patterns so a rule loads **only when editing matching files** (reduces irrelevant context/tokens).
- ✅ Prefer glob-pattern rules (`paths: ["terraform/**/*"]`, `**/*.test.tsx`) over directory-level CLAUDE.md when conventions **span multiple directories** (e.g. test files spread across the tree).

### 3.4 Plan mode vs direct execution
- ✅ **Plan mode** for complex/large-scale changes, multiple valid approaches, architectural decisions, multi-file edits (microservice restructuring, migrations affecting 45+ files) — safe exploration before committing, prevents costly rework.
- ✅ **Direct execution** for simple, well-scoped changes (single-file bug fix with a clear stack trace, adding one validation check).
- ✅ Use the **Explore subagent** to isolate verbose discovery output and return summaries, preserving main-conversation context during multi-phase tasks.
- ✅ Combine: plan mode for investigation → direct execution for the planned implementation.

### 3.5 Iterative refinement techniques
- ✅ Provide **2–3 concrete input/output examples** when prose descriptions are interpreted inconsistently — examples are the most effective disambiguator.
- ✅ **Test-driven iteration**: write the test suite first (expected behavior, edge cases, performance), then iterate by sharing test failures.
- ✅ Use the **interview pattern**: have Claude ask questions to surface considerations (cache invalidation, failure modes) before implementing in unfamiliar domains.
- ✅ For **interacting** problems, give all issues in one detailed message; for **independent** problems, fix sequentially.

### 3.6 CI/CD integration
- ✅ Run non-interactively with `-p` / `--print` to prevent input hangs.
- ✅ Use `--output-format json` with `--json-schema` for machine-parseable findings (auto-posted as inline PR comments).
- ✅ On re-runs after new commits, include prior findings in context and instruct Claude to report **only new or still-unaddressed** issues (avoid duplicate comments).
- ✅ Provide existing test files in context so generation doesn't duplicate covered scenarios; document testing standards / valuable criteria / fixtures in CLAUDE.md.
- ✅ **Review with an independent instance**, not the session that generated the code (see 4.6).

---

## Domain 4 — Prompt Engineering & Structured Output

### 4.1 Explicit criteria to cut false positives
- ✅ Write **specific categorical criteria**, e.g. "flag comments only when claimed behavior contradicts actual code behavior" — not "check that comments are accurate."
- ✅ Define explicit **severity criteria with concrete code examples** per level for consistent classification.
- ✅ To restore developer trust, **temporarily disable** high-false-positive categories while improving their prompts.
- ⚠️ Flag: vague hedges like "be conservative" / "only report high-confidence findings" — they don't improve precision. High-false-positive categories erode trust in the accurate ones.

### 4.2 Few-shot prompting
- ✅ Use **2–4 targeted few-shot examples** when detailed instructions alone yield inconsistent output — the single most effective consistency lever.
- ✅ Show **reasoning for ambiguous cases** (why one action was chosen over plausible alternatives) so the model generalizes to novel patterns, not just the shown cases.
- ✅ Demonstrate the exact desired **output format** (location, issue, severity, suggested fix).
- ✅ Use examples to distinguish acceptable patterns from genuine issues, and to handle varied document structures (inline citations vs bibliographies) — reduces hallucination/empty extractions.

### 4.3 Structured output via tool use + JSON schema
- ✅ Use **tool use with a JSON schema** as the most reliable path to schema-compliant output — eliminates JSON syntax errors.
- ✅ Pick `tool_choice` deliberately: `"auto"` (may return text), `"any"` (must call some tool), forced `{"type":"tool","name":...}` (must call a specific tool). Use `"any"` to guarantee structured output when multiple schemas exist and the doc type is unknown; force a tool to run a specific extraction first.
- ✅ Make schema fields **optional/nullable** when the source may lack the info — prevents the model fabricating values to satisfy required fields.
- ✅ Add enum values like `"unclear"` for ambiguous cases and `"other"` + a detail string for extensible categories.
- ✅ Include **format-normalization rules in the prompt** alongside the strict schema to handle inconsistent source formatting.
- ⚠️ Remember: strict JSON schemas kill *syntax* errors but **not semantic** ones (line items that don't sum to total, values in the wrong field) — see 4.4.

### 4.4 Validation, retry, feedback loops
- ✅ **Retry with error feedback**: on failure, append the original document + the failed extraction + the **specific validation errors** so the model self-corrects.
- ✅ Know retry limits: retries fix **format/structural** errors, but **not** missing information (info absent from the source, or only in an external doc that wasn't provided). Detect and stop retrying in those cases.
- ✅ Design **self-correction validation**: extract `calculated_total` alongside `stated_total` to flag discrepancies; add `conflict_detected` booleans for inconsistent source data.
- ✅ Add a `detected_pattern` field to findings to enable systematic analysis of which code constructs trigger false positives (so dismissal patterns can be studied).
- ⚠️ Flag: retrying when the required info simply isn't in the source.

### 4.5 Batch processing
- ✅ Use the **Message Batches API** for non-blocking, latency-tolerant workloads (overnight reports, weekly audits, nightly test generation): ~50% cost savings, up to 24-hour window, **no latency SLA**.
- ✅ Use the **synchronous API** for blocking workflows (pre-merge checks).
- ✅ Use `custom_id` to correlate request/response pairs; on failure, **resubmit only failed items** (identified by `custom_id`) with fixes (e.g. chunk docs that exceeded context).
- ✅ Refine the prompt on a **sample set** before batch-processing large volumes to maximize first-pass success and reduce resubmission cost.
- ✅ Size batch submission frequency to the SLA (e.g. 4-hour windows to guarantee a 30-hour SLA against a 24-hour batch window).
- ⚠️ Remember: batch API does **not** support multi-turn tool calling within a single request (can't execute tools mid-request).

### 4.6 Multi-instance / multi-pass review
- ✅ Review generated code with a **second, independent Claude instance** that lacks the generator's reasoning context — more effective than self-review or extended thinking (a generator retains reasoning that biases it against questioning its own decisions).
- ✅ Split large reviews into **per-file local passes** (local issues) + **separate cross-file integration passes** (data-flow) to avoid attention dilution and contradictory findings.
- ✅ Run **verification passes where the model self-reports confidence** alongside each finding, to enable calibrated review routing.
- ⚠️ Flag: asking the generating session to review its own output as the primary QA gate.

---

## Domain 5 — Context Management & Reliability

### 5.1 Preserving critical info across long interactions
- ✅ Extract transactional facts (amounts, dates, order numbers, statuses) into a persistent **"case facts" block included in every prompt**, outside the summarized history.
- ✅ **Trim verbose tool outputs to only relevant fields** before they accumulate (e.g. keep ~5 return-relevant fields, not 40+ per order lookup).
- ✅ Place **key-findings summaries at the beginning** of aggregated inputs; use explicit section headers to counter position effects.
- ✅ Require subagents to include metadata (dates, source locations, methodological context) in structured outputs to support accurate downstream synthesis.
- ✅ When downstream agents have limited budgets, have upstream agents return **structured data (key facts, citations, relevance scores)** instead of verbose content + reasoning chains.
- ⚠️ Flag: **progressive summarization** that condenses numbers/percentages/dates/expectations into vague prose. Beware the **"lost in the middle"** effect — models reliably use the start and end of long inputs but may drop the middle.

### 5.2 Escalation & ambiguity resolution
- ✅ Escalate on the right triggers: customer explicitly **requests a human**, policy **exception/gap** (not just "complex"), or **inability to make meaningful progress**.
- ✅ Honor an explicit human-agent request **immediately**, without first attempting investigation.
- ✅ Acknowledge frustration while offering resolution when the issue is within capability; escalate only if the customer reiterates.
- ✅ Escalate when policy is **ambiguous/silent** on the specific request (e.g. competitor price-match when policy only covers own-site).
- ✅ On multiple record matches, **ask for additional identifiers** — don't heuristically pick one.
- ✅ Add explicit escalation criteria **with few-shot examples** to the system prompt.
- ⚠️ Flag: sentiment-based escalation and self-reported confidence scores as proxies for actual case complexity — they're unreliable.

### 5.3 Error propagation across multi-agent systems
- ✅ Return **structured error context**: failure type, attempted query, partial results, alternative approaches — so the coordinator can make intelligent recovery decisions.
- ✅ Distinguish **access failures** (timeouts → retry decision) from **valid empty results** (successful, no matches) in error reporting.
- ✅ Subagents do local recovery for transient failures; propagate only unresolved errors (with what was attempted + partial results).
- ✅ Structure synthesis output with **coverage annotations** — which findings are well-supported vs which topic areas have gaps due to unavailable sources.
- ⚠️ Flag: generic error statuses ("search unavailable") that hide context; **silently suppressing errors** (returning empty-as-success); and **terminating the whole workflow** on a single failure — both extremes are anti-patterns.

### 5.4 Context in large-codebase exploration
- ✅ Spawn subagents to investigate specific questions ("find all test files", "trace refund-flow dependencies") while the main agent keeps high-level coordination.
- ✅ Have agents maintain **scratchpad files** recording key findings, and reference them for later questions to counteract context degradation.
- ✅ Summarize key findings from one phase **before** spawning next-phase subagents, injecting summaries into their initial context.
- ✅ Design crash recovery via **structured state exports (manifests)** that each agent writes to a known location and the coordinator loads on resume.
- ✅ Use `/compact` to reduce context usage during extended exploration when context fills with verbose discovery output.
- ⚠️ Flag: **context degradation** — the model starts giving inconsistent answers and referencing "typical patterns" instead of the specific classes discovered earlier. Treat this as a signal to summarize/offload/compact.

### 5.5 Human review & confidence calibration
- ✅ Use **stratified random sampling** of high-confidence extractions for ongoing error-rate measurement and novel-pattern detection.
- ✅ **Analyze accuracy by document type and field segment** before automating away human review — an aggregate metric (e.g. 97%) can mask poor performance on specific types/fields.
- ✅ Have models output **field-level confidence scores**, then calibrate review thresholds using labeled validation sets.
- ✅ Route low-confidence or ambiguous/contradictory-source extractions to humans, prioritizing limited reviewer capacity.
- ⚠️ Flag: trusting an aggregate accuracy number to justify removing human review.

### 5.6 Provenance & uncertainty in multi-source synthesis
- ✅ Require subagents to output **structured claim-source mappings** (source URLs, doc names, relevant excerpts) that downstream agents **preserve through synthesis**.
- ✅ Structure reports to **distinguish well-established findings from contested ones**, preserving original source characterizations + methodological context.
- ✅ On conflicting statistics from credible sources, **annotate the conflict with source attribution** rather than arbitrarily picking one value; let the coordinator decide how to reconcile before synthesis.
- ✅ Require **publication/collection dates** in structured outputs so temporal differences aren't misread as contradictions.
- ✅ Render content types appropriately in synthesis (financial data as tables, news as prose, technical findings as structured lists) — don't force everything into one uniform format.
- ⚠️ Flag: summarization steps that compress findings and **drop claim-source mappings** (attribution is lost).

---

## Cross-cutting red flags (quick scan)

Any one of these usually means a finding:

1. **Prompt where a guarantee is needed** — a hard business/compliance/ordering rule (money, identity, irreversible actions) enforced only by prompt instructions instead of a hook / prerequisite gate. *(1.4, 1.5)*
2. **Silent loss** — errors suppressed as empty-success, or whole workflows killed on one failure; summaries that drop numbers, dates, or source attribution. *(5.1, 5.3, 5.6)*
3. **Tool sprawl / ambiguity** — an agent holding many tools, tools outside its role, or two tools with near-identical descriptions. *(2.1, 2.3)*
4. **Loop driven by the wrong signal** — stopping on parsed text or an iteration cap instead of `stop_reason`. *(1.1)*
5. **Vague criteria** — "be conservative", "high-confidence only", "check accuracy" instead of specific categorical/severity criteria (and no few-shot examples where output is inconsistent). *(4.1, 4.2)*
6. **Fabrication pressure** — required (non-nullable) schema fields the source may not contain; retrying when the info is simply absent. *(4.3, 4.4)*
7. **Self-review as the QA gate** — the generating session reviews its own output. *(4.6)*
8. **Context assumptions** — assuming a subagent inherited context it was never passed; resuming a session with stale tool results. *(1.2, 1.3, 1.7)*
9. **Aggregate metric hides tail** — automating away human review on an overall accuracy number without per-type/per-field breakdown. *(5.5)*

## Reference: the canonical example

> *Production data shows the agent skips `get_customer` in 12% of cases and calls
> `lookup_order` on the customer's stated name, causing misidentified accounts
> and incorrect refunds.* **Best fix:** add a *programmatic prerequisite* that
> blocks `lookup_order`/`process_refund` until `get_customer` returns a verified
> ID. Strengthening the system prompt (B) or adding few-shot examples (C) relies
> on probabilistic compliance — insufficient when errors have financial
> consequences. A routing classifier (D) fixes tool *availability*, not tool
> *ordering* — the actual problem. **The lesson: match the mechanism to the
> guarantee the business needs.**

---

## Review output

When reviewing a design, produce:

- **Verdict** per applicable domain: sound / needs work / not applicable.
- **Findings**, most-consequential first. For each: the criterion violated
  (cite the domain, e.g. *1.4*), the concrete risk, and the **specific fix**
  (name the mechanism — hook, prerequisite gate, `tool_choice` value, nullable
  field, independent review instance, etc.).
- **What's already right** — briefly, so good decisions aren't undone.

Keep findings actionable and tied to a criterion above; if something feels off
but matches no criterion, say so explicitly rather than forcing a fit — and
consider whether it's a new guideline worth adding here (then bump the version).
