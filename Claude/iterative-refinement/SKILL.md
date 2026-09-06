---
name: iterative-refinement
version: 2.4.0
description: Build an evaluator-optimizer loop — two agents ping-ponging over a shared workspace until a structured artifact stops changing. Use when a single LLM pass produces an unreliable artifact that can be checked against a source, when you are tempted to decompose a task into independent passes and reconcile them afterward, or when the user asks for an iterative refinement / generate-and-critique / self-correcting loop.
user-invocable: true
---

# Iterative Refinement (Evaluator–Optimizer)

> **Skill version: 2.4.0** — distilled from one project, not yet proven across
> many. Update it when practice contradicts it (§16).

Two agents work over a shared directory until the artifact reaches a fixed point:
an **optimizer** that writes the artifact, and an **evaluator** that reads the
source and the artifact and writes findings. The loop terminates on convergence,
not on an agent declaring itself done.

Based on the evaluator-optimizer pattern in Anthropic's
[Building effective agents](https://www.anthropic.com/engineering/building-effective-agents).
Everything beyond the pattern name and its two fit criteria is elaboration on
making the criteria mechanical.

---

## 1. When this applies

**Fit criteria** (from the article): there are *clear evaluation criteria*, and
*iterative refinement provides measurable value*.

**Strong fit** — all three hold:

- The artifact is **checkable against a source** that is present at check time.
- A meaningful share of "correct" is **mechanically decidable** — referential
  integrity, uniqueness, locatability — not pure judgement.
- A single pass is unreliable in a way that *feedback* fixes, not one that a
  better prompt fixes.

**Do not use it when:**

- Criteria are vague or contested. The loop **amplifies** the criteria in both
  directions; miscalibrated criteria are worse than no loop, because they drive
  a correct optimizer toward a wrong answer with rising confidence.
- The only available check is another LLM's opinion of the same input. Shared
  blind spots make that check far weaker than it looks.
- One pass already succeeds. Retry-on-failure is cheaper.

**The anti-pattern this replaces:** decomposing a task into independent passes
because one pass was unreliable, then reconciling the halves. Reconciliation is
a seam, and seams between agents that cannot see each other's output are where
coordination bugs live. No prompt wording makes two blind agents agree on a
shared vocabulary; a stronger model does not fix it either.

---

## 2. Workspace

Both agents work in a directory. State lives in files, not conversations — this
is what keeps agents grounded and makes the trace durable.

```
<task-dir>/
  source.<ext>          # the input, exactly as the agents will read it
  artifact.v1.json      # optimizer output
  evaluation.v1.json    # evaluator findings + optimizer dispositions
  keys.json             # key ledger (§5)
  artifact.v2.json
  ...
```

Versioned files give the full trace for free. The result is the last version
that exited cleanly.

---

## 3. The two roles

**Optimizer** — the *only* writer of the artifact. Its conversation
**persists across rounds**: round 1 reads the source and mints the first
version; every round after that, the harness injects the latest
`evaluation.json` as a new turn in that same conversation, and the optimizer
edits incrementally against it. Nothing about the role depends on starting
over each round — it is not the independence-bearing side of the loop, so
there is nothing to protect by resetting it, and letting it persist is what
keeps edits incremental and diffable instead of re-deriving the whole
artifact from scratch every round.

**Evaluator** — reads the source and the artifact in a **fresh context every
round**. Writes only the evaluation. The fresh context is what makes it an
independent check; an evaluator that inherits the optimizer's context inherits
its reasoning and stops being one.

**The two conversations are disjoint.** The optimizer's conversation may
persist, but it must never contain the evaluator's reasoning — only the
`evaluation.json` the evaluator wrote. The evaluator must never see the
optimizer's conversation at all. Disjointness, not statelessness, is what
makes the evaluator's check independent; the optimizer keeping its own
history across rounds does not weaken that, because the optimizer was never
the side the loop relies on for an unbiased read.

**Pass it the settled disagreements.** A fresh context also forgets its own
prior findings, so a judgemental finding the optimizer rejected in round 2 gets raised
identically in round 3, rejected again, and so on until the budget is gone.
Include prior findings carrying `disposition: rejected`, with their reasons, in
the evaluator's prompt.

This does not compromise independence: it sees *what was settled*, not the
optimizer's reasoning. It is the same move as withdrawal (§6) — memory belongs
in the files, not the conversation, and the optimizer's persisting conversation
is a cache of that same file-backed state, not a second copy of it, and must
stay reconstructable from the files alone.

### Enforce roles with tools, not instructions

An agent asked not to write, but holding a write tool, is a policy. An agent
without a write tool is a guarantee.

| | Optimizer | Evaluator |
|---|---|---|
| Edit the artifact | ✅ scoped to the artifact path | ❌ no write tool at all |
| Read source + artifact | ✅ | ✅ |
| Search the workspace | ✅ | ✅ |
| Submit structured output | ❌ | ✅ — its only output channel |

Two asymmetries carry weight:

**The optimizer edits a file; the evaluator submits an object.** This mirrors
their outputs. The artifact is iterated on across rounds, so incremental edits
keep repair cheap and leave a diffable trace. The evaluation is a one-shot
verdict per round, so it is submitted as a validated structure and the *harness*
writes the file. The evaluator then needs no write capability at all.

**Scope the optimizer's writes to the artifact.** With a general file editor it
can edit the source — altering the ground truth to agree with its artifact
rather than the reverse. The source must be immutable to both agents.

**Single-writer discipline is load-bearing.** If both agents can write the
artifact, changes cannot be attributed and the fixed-point test means nothing.

---

## 4. The two contracts

| File | Scope | Changes per project |
|---|---|---|
| `artifact.json` | domain-specific | yes — this *is* the domain |
| `evaluation.json` | generic | no |

That is the reuse boundary. Porting this to another problem means swapping the
artifact contract and the two prompts; everything else transfers.

### Evaluation format (portable as-is)

```
finding:
  tier:        mechanical | judgemental
  code:        machine-readable finding type
  locus:       key(s) of the artifact element(s) at fault
  message:     what is wrong, phrased for repair
  disposition: (written by the optimizer next round)
               accepted | rejected + reason
```

Three rules, all load-bearing:

1. **Findings, not a verdict.** A boolean cannot drive repair. This is what
   distinguishes the pattern from retry-on-failure.
2. **Findings are localized.** `locus` lets repair be scoped to the broken
   elements instead of regenerating the artifact — cheap rounds, no collateral
   damage to correct output.
3. **Findings carry a tier.** *Mechanical* = a mechanical invariant is violated.
   *Judgemental* = a judgement call. Only mechanical findings block exit. The
   tier names which checker raised the finding (§11), and that is what decides
   contestability — not a separate severity ranking layered on top of it.

### Artifact requirements

Any domain artifact must satisfy these for the generic loop to work:

1. **Surrogate keys.** Every element carries a key the *pipeline* owns, not one
   borrowed from the source. Natural keys vary by source; surrogate keys don't,
   and minting one is never a fabrication.
2. **Keys are never reused or renumbered.** A key denotes one record forever.
   Records may leave (§6), but keys are never reissued. Renumbering means no two
   artifacts compare equal and the fixed point never fires; recycling means every
   `locus` referring to that key becomes ambiguous.
3. **Canonical form.** A deterministic serialization — sorted by key, whitespace
   normalized, volatile fields excluded — whose hash is the artifact's identity.
4. **No derived positional data.** Offsets, indices, anything recomputable from
   the source stays *out*. It shifts whenever parsing changes, making
   semantically identical artifacts compare unequal. Derived data belongs in the
   evaluation, recomputed each round.

Bind the artifact to a **content hash of the source** so it cannot drift from
what the evaluator is reading.

> **Watch for required fields the source cannot supply.** Any such field is a
> demand for fabrication — the model will fill it with something. If a field is
> only meaningful for some inputs, make it nullable and record *how* the value
> was established in a separate field.

---

## 5. Key minting

The optimizer mints keys; a persistent **ledger** records every key ever issued:

```json
{"used": ["r1", "m1"], "next_r": 2, "next_m": 2}
```

Tell the optimizer the next available keys in its prompt. The gate (§7) checks
that every pre-existing key still denotes the same record and every new key is
absent from `used`, then appends and bumps the counters.

> **Do not have the harness assign keys post-turn.** It looks safer — the
> optimizer writes `key: null` and reuse becomes structurally impossible — but
> it does not work. A new record that another new record must reference has
> nothing to point at until stamping, so intra-artifact links cannot be
> expressed, and referential-integrity checks cannot run until after the step
> they should be gating.

The ledger trades *impossible* for *detected-in-turn*, which is close enough:
the gate rejects with a specific message while the agent is still working.

---

## 6. Withdrawal, not deletion

When a record should not be in the artifact, it stays with a **status and a
reason**, and its key is never reissued.

Hard deletion breaks the loop. The evaluator reads the source in a fresh context
every round, so it sees the same input that produced the record and raises it as
missing again; the optimizer re-adds it under a new key; the next round removes
it. Each artifact genuinely differs, so the fixed point never fires and the loop
runs to exhaustion.

Withdrawal is how a fresh-context evaluator remembers a settled dispute: the
memory lives **in the artifact**, not in a conversation — the same move as the
workspace itself.

Removal is a judgement, so it follows contestability (§8): the evaluator raises a
*judgemental* finding, and the optimizer either withdraws the record or rejects the
finding with a reason. Neither outcome is silent.

Withdrawn records participate in the canonical form; otherwise a withdrawal does
not register as a change and the fixed-point test misfires.

---

## 7. The finish-gate

**The optimizer's turn ends by calling a tool that validates, not by the agent
falling silent.** On failure the executor withholds the "finished" status and
returns the errors as an observation, so the agent sees exactly what is wrong
and fixes it *in the same turn*.

```
optimizer edits artifact (free, incremental)
    ↓
calls finish_artifact
    ↓
gate: parses? schema fits? keys intact? mechanical checks pass?
    ├─ fail → error observation, NOT finished → agent keeps working
    └─ pass → commit ledger, persist version, FINISHED
```

Without a gate, every mechanical error costs a full round-trip through the
evaluator's fresh context before it even reaches the optimizer — and, even
with a persisting conversation, the optimizer may by then have compacted away
(§13) the reasoning that produced the error.

Because the gate exists, run the **mechanical tier of the evaluator there too**.
The optimizer then never emits a mechanically-broken artifact, and the outer
ping-pong is reserved for judgement.

Two guards:

- **Cap the rejections.** Agents thrash. After N failed attempts let the turn
  end and let the outer loop surface what remains.
- **Keep mechanical checks in the outer evaluator as well.** Nearly free, and
  the backstop for whatever slipped through when the cap fired.

**What the gate cannot do:** it is local, so it cannot tell repair from evasion.
A record whose check fails can be made to pass by removing it. That is why
withdrawal demands a reason and why the evaluator reads the source
independently — a gate satisfiable by deletion recreates silent-drop failures
inside a single turn.

**Watch the direction of your checks.** Mechanical checks accrete in one
direction — artifact → source, *"does this record resolve?"* Every check of that
shape is blind to omission by construction: a record that was never written has
nothing to fail. A gate composed entirely of them will pass an artifact that is
half the answer, and report it as clean. Pair them with at least one
source → artifact check — *"is everything in the source accounted for?"* — even
a crude one. Counting is enough: occurrences of a joinable token in the source
versus records in the artifact.

---

## 8. Contestability

**The optimizer must be able to reject a judgemental finding, with a reason, and
that rejection resolves it.**

Without this, an evaluator false-positive becomes artifact corruption: told "you
missed something" and unable to disagree, the optimizer invents something to
satisfy the demand.

Mechanical findings are not contestable. Judgemental findings are opinions and
must be.

### Getting the mechanical/judgemental line right

**A check belongs in the mechanical tier only if the optimizer can always
satisfy it honestly.**

Ask of every candidate mechanical finding: *can a legitimate source make this
unsatisfiable?* If yes, it belongs in the judgemental tier. A non-contestable
check that the input cannot satisfy leaves only two moves — fabricate, or
thrash until the cap — which is the same fabrication pressure as a required
field the source cannot supply (§4).

Reliable mechanical checks are properties of the artifact *alone*: does this
key resolve, is it unique, was it mutated, does this span exist in the source.
Anything that asserts what the source *ought to contain* is a judgement wearing
a mechanical costume.

### Unsatisfiable mechanical findings

Even a well-drawn mechanical check can be locally unsatisfiable — a span that
exists in the document but not in the extracted text, say. Give the optimizer
one narrow escape: mark a mechanical finding **`unsatisfiable` with a reason**.

This is not contesting the check. The check is right; the source cannot satisfy
it. Route those to withdrawal (§6) rather than infinite repair, and surface them
in the result. Without it the loop retries for information that is not there —
retries fix structure, never absence.

---

## 9. Mode: when validity rules depend on the input

If what counts as a *valid artifact* depends on a property of the input — its
kind, genre, or regime — establish that property **before** the loop and hold it
fixed. Rules that mutate mid-loop let the artifact oscillate between two
internally consistent states forever.

Give the evaluator exactly one privileged finding — `wrong_mode` — which
**aborts the outer loop** rather than being repaired in place. Cap restarts at
one.

**Determining the mode:** gather countable, deterministic signals first, then
have one cheap LLM call adjudicate over the *signal summary* rather than the
whole input. Signals alone are usually ambiguous; a classifier over evidence is
cheap and reviewable.

**On uncertainty, prefer the permissive mode.** Failure modes are rarely
symmetric. Identify the mode whose misapplication the loop *cannot* self-correct
— typically one that forbids a category of output, so the evaluator will never
raise its absence — and require **positive evidence** for it, never a mere
failure to detect the alternative.

---

## 10. Exit criteria

Five states. Only the first is unqualified success.

| State | Condition | Outcome |
|---|---|---|
| **Converged** | no mechanical findings; judgemental findings resolved or rejected | emit |
| **Accepted** | no mechanical findings; judgemental findings outstanding | emit **with findings attached** |
| **Stalemate** | artifact identical to previous round, findings remain | emit **with the disagreement recorded** |
| **Regressed** | findings worsened | revert to best-so-far, stop |
| **Exhausted** | budget spent, mechanical findings remain | **failure — not a result** |

- **Accepted must exist.** If the only clean exit is zero findings of any kind,
  unresolvable judgemental findings force either fabrication or spurious failure.
- **Stalemate ≠ converged.** A fixed point reached while the evaluator still
  objects means the agents agreed to disagree. Stopping is right; reporting it
  as success is not.
- **Track best-so-far.** The loop is not monotonic. The last iteration is not
  necessarily the best; without this a loop can end worse than it started.
- **Exhausted is a failure, but not an empty one.** A process that did not reach
  a verdict must not emit something that looks like one — *and* must not throw
  away what it achieved. Attach the best-so-far artifact and the outstanding
  findings to the failure. A run that got 21 of 23 records right should not
  report identically to one that produced nothing.

Detect the fixed point by comparing **canonical-form hashes**, not raw
serializations.

---

## 11. Split the evaluator

Two tiers with different economics. Build and trust them separately.

| | Mechanical | Judgemental |
|---|---|---|
| Cost | ~free | expensive |
| Reliability | deterministic, no hallucination | fallible, correlated with the optimizer |
| Proves | something *is* wrong | nothing conclusively |
| Catches | invariant violations | omissions (recall) |
| Run | every round, and at the gate | every round (the default) |

**Mechanical checks have zero recall.** They can prove something is wrong; they
can never prove nothing is missing. A green light is not a completeness
guarantee, and should not be reported as one. Recall is the *only* thing the
judgemental tier adds — and it is the reason the pattern has a second agent at
all. Dropping it does not make a leaner evaluator-optimizer loop; it makes
something that is no longer one (see §12).

---

## 12. Build order

Ordered so everything offline lands before anything costing an API call:

1. **Models + canonical form + hashing.** Round-trip tests; artifacts differing
   only in formatting must hash equal.
2. **Key ledger.** Validate/commit as pure functions.
3. **Mechanical checks** as a *pure function* over `(artifact, source, previous,
   ledger)`. It is called from two places — the gate and the outer evaluator —
   so it must not reach for state. **This is the highest-value phase and it is
   entirely offline.** Run it over archived outputs of the system you are
   replacing to get a measured baseline.
4. **Tools.** Scoped editor, finish-gate, submit-evaluation.
5. **The optimizer runner only.** A single conversation that persists across
   outer rounds, editing against the gate, with each round's `evaluation.json`
   injected as a new turn. **Do not build the LLM evaluator yet** — see below.
6. **Loop driver** — generic, importing nothing from the domain. Test the five
   exit states with stub callables, no LLM. *If domain types leak in, the reuse
   boundary is gone.*
7. **Mode detection**, if applicable.
8. **The evaluator agent and judgemental findings** — the pattern's second
   agent. This is the destination: a working loop runs it every round, gated on
   by default. Steps 1–7 are the scaffold you build it on, not the finished
   thing.
9. **Integration.** Keep the old path alive until the new one is measured
   against it.

> **Build the mechanical tier first — but do not mistake it for the whole loop.**
> Sequencing this last is deliberate: steps 1–7 are pure functions, cheap and
> offline, and they give you a correctness floor and a measurable baseline before
> you spend an API call. Ship them and see how far they get.
>
> But be honest about what you have shipped at step 7: one agent, a validator,
> and a gate — *validation with retry feedback*, **not** an evaluator-optimizer
> loop. The two agents ping-ponging are the pattern; a mechanical-only loop is
> the degenerate case, the exception, not the rule. The second agent is the only
> source of recall, which is the one thing the whole structure exists to buy.
>
> So step 8 is the norm, not an optional extra. Default it **on**. Falling back
> to mechanical-only is a *deliberate* choice — you measured the recall lift and
> found it negligible, or a hard cost constraint forces it — never the resting
> default reached by leaving the second agent unbuilt. The flag lets you drop to
> the degenerate mode; it does not make that mode the baseline.

---

## 13. Progress needs its own record

The artifact records **what exists**. It never records **how far the agent got**.
So nothing in the workspace distinguishes

> *absent because the agent judged it absent*

from

> *absent because the agent never reached it.*

Both look like a clean, complete artifact, and every check in §7 agrees.

This is no longer an edge case, because **context compaction is normal**. A
condenser preserves the first few events and replaces the rest with a summary,
so an agent mid-task routinely loses the memory of what it has already read.
When it does, its context is not the record of its work — the files are. It must
be able to parachute in and re-orient from disk alone.

For the optimizer this now spans the **whole loop**, not one round's reading:
its conversation persists across every round (§3), so a long refinement run is
exactly the mid-task scenario compaction targets. The progress marker and the
terminal-condition instruction below are load-bearing across outer rounds, not
just within one.

**Add a progress marker to the workspace.** Same discipline as the key ledger
(§5): append-only, pipeline-owned, persisted beside the artifact.

**Make it observed, not declared.** This is the part that is easy to get wrong.
If the agent reports its own progress, the marker records a *claim* — and an
agent can forget to report, or assert coverage it never had. Write it in the
**executor of the tool that delivers the data**, so progress is a machine record
of what the agent was actually shown. The agent never writes it, exactly as it
never writes the key ledger. Single writer, no clobber race against the agent's
own writes, and nothing to fabricate.

> **Record what was RETURNED, never what was REQUESTED.**

That invariant is the whole of it. The failure it defends against is a reader
that quietly returns *part* of the input while presenting itself as complete —
truncating in the middle, renumbering what remains, capping a range without
saying so. Under this invariant such a read registers exactly the span it
delivered, and the gap stays visibly open.

It follows that when a request exceeds the response budget, the tool should
**refuse and name a range that fits**, not truncate and serve a partial answer.
A refusal the agent must handle beats a short read it may not notice.

What this buys:

- **Orientation** — the resume point survives compaction, interruption, retry.
- **A blocking claim** — the gate can hard-fail an artifact whose source is not
  fully accounted for, converting a silent omission into a stated one.
- **An audit trail** — versioned alongside the artifact, showing progress per
  round.

What it does **not** buy: proof of comprehension. It proves *delivery*. That is a
weaker claim and still the right one, because delivery is what silently fails.

### The marker must also say *stop*

A marker that answers *"where do I resume?"* is only half of what a
compacted agent needs. It must also answer *"am I done?"*

Watch the failure. An agent had covered its whole source, written a complete
artifact, and then lost its memory to condensation. It re-read the marker,
correctly saw full coverage — and proceeded to re-verify and re-edit the
finished artifact anyway. It had no memory of having already checked, so it
checked again, and again. Coverage was complete on every pass; nothing was
wrong; it could not tell that nothing was wrong.

**Resumption is the easy half.** An agent that has lost its place will
happily find it again. What it cannot recover on its own is the knowledge
that there is no more work to do — that state lives only in the memory the
condenser just discarded.

So state the terminal condition where a re-oriented agent will read it, in the
instructions that survive compaction — the prompt itself, not a mid-run
observation:

> If the marker shows the input fully accounted for and the artifact
> satisfies the gate, **finish**. Do not re-derive work already recorded.
> Your context is not the record of your work; the files are, and they are
> already complete.

Without that, a marker built to prevent under-reading funds unbounded
re-reading instead. Both failures burn the budget; only one of them looks
like progress.

### Size the reader against the window, not a fixed budget

Compaction has a pathological regime. When the window is narrow relative to a
single observation, the condenser fires, reclaims a little, and is immediately
over the threshold again — firing every few events, reclaiming a fraction each
time, paying a summarization call for each pass and destroying context it will
need. Progress-per-condensation guards do not catch this: reclaiming 3 of 5
events is a large *fraction*, and still nowhere near enough headroom to stay
under.

The cause is not the condenser. It is a **reader whose chunk size was chosen
independently of the window**. If one tool result is a large share of the
context, no condensation policy can rescue it — the observation alone
re-fills what was just freed.

Derive the read budget from the *resolved context window*, and leave room for
the conversation around it. Two consequences:

- A chunk must be small enough that several fit alongside the prompt and the
  artifact-so-far, not merely small enough to be returned once.
- There is a floor below which the loop cannot run at all. Past it the agent
  spends every turn condensing and none working. If the window is that tight,
  partition the *task* into independently-extractable slices, each read whole,
  and merge on surrogate keys (§5) — rather than shrinking the read further.

**Symptom to watch for:** condensation events interleaved every few tool calls,
with turn count climbing far beyond a comparable un-compacted run. Compare
against a baseline; an order-of-magnitude gap in events for the same input is
thrashing, not thoroughness.

---

## 14. Instrumenting the loop

The driver returns a final artifact and an exit state. Everything about *how the
run got there* — how many rounds it took, how much the mechanical gate had to
push back, how active the judgemental tier actually was — is scattered across
two disjoint places at best, and fully recorded nowhere. The evaluator's
fresh-per-round context discards its own judgemental-activity count the moment
the round ends; the optimizer's persisting conversation may retain a trace of
its own gate rejections, but not in a form any downstream reader can extract
without re-parsing a transcript. Neither side, nor the two together, gives you
the driver's cross-round view. That is also the data you need to answer the
question this whole pattern rests on: is the second agent, and the loop around
it, actually earning its keep, or would a single mechanical-gated pass do just
as well?

Two per-round signals are worth capturing generically, because both already
exist somewhere in the loop's own state and neither requires a new judgement
call to define:

- **Mechanical backpressure.** How many times the finish-gate (§7) rejected the
  optimizer before it produced something clean, per round. A round that took
  zero rejections and a round that hit the cap are very different outcomes that
  a bare round count collapses into the same number.
- **Judgemental activity.** How many judgemental findings the evaluator actually
  raised each round. A loop where the judgemental tier fires on round 1 and
  never again is doing most of its work in the mechanical gate — worth knowing
  before assuming the second agent is pulling its weight every round.

**Capture both by wrapping the bound callables, never by touching the driver.**
This is the same move §13 makes for round-by-round progress reporting, and for
the same reason: the driver's whole value is staying free of any domain import,
and instrumentation is not a special case that earns an exception. Whatever code
already hands `optimizer`/`evaluator` to the driver is the same code that can
wrap them first — record the gate's rejection count after each optimizer call
and the judgemental-tier count after each evaluator call, into a list closed
over by the wrapper, one entry per round. `run_loop` itself takes no metrics
parameter and never sees the wrapper at all.

If the rejection count lives on a private/internal object (the gate executor,
say), give it a small deliberate public read path rather than reaching into
another module's internals from the wrapping site — the same discipline as any
other API boundary, not an exception for something "just" used for metrics.

What this buys, without adding a single parameter to the driver or a single
field to the finding contract: an empirical, per-run trajectory to answer "how
much of the improvement happens in round 1" across many runs, and a specific
run's own trajectory to inspect when one looks like an outlier.

---

## 15. Failure modes to design against

| Failure | Cause | Guard |
|---|---|---|
| Amplified error | miscalibrated criteria | validate criteria before trusting the loop |
| Fabrication | a finding or field the optimizer cannot contest or satisfy honestly | contestability; nullable fields; the mechanical/judgemental test (§8) |
| Re-litigation | fresh-context evaluator forgets its own rejected findings | pass prior `rejected` dispositions into its prompt (§3) |
| Retrying for absent information | no way to report a check as unsatisfiable | `unsatisfiable` + reason, routed to withdrawal (§8) |
| Empty failure | exhaustion discards the best artifact seen | attach best-so-far and outstanding findings (§10) |
| A second agent that does nothing | evaluator built before judgemental findings exist | build the mechanical loop first (§12) |
| Oscillation | hard deletion, or mode mutating mid-loop | withdrawal; mode fixed before the loop |
| False convergence | fixed point reached in disagreement | stalemate as a distinct exit state |
| Ending worse than it started | non-monotonicity | best-so-far tracking |
| Silent degradation | records dropped to satisfy a check | withdrawal with reason; independent evaluator |
| Unbounded cost | no cap | iteration budget; exhaustion is a failure |
| Silent omission | every mechanical check runs artifact → source, so a record never written has nothing to fail | pair them with a source → artifact completeness check (§7) |
| Disorientation after compaction | the artifact records what exists, not how far the agent got | append-only progress marker in the workspace (§13) |
| Fabricated progress | the agent reports its own coverage | write the marker in the tool executor; record what was returned, not requested (§13) |
| Undetected partial read | a reader truncates or caps without saying so | refuse an over-budget request rather than serving a short answer (§13) |
| Re-deriving finished work | a re-oriented agent can find its place but cannot recall that it is done | state the terminal condition in the surviving prompt: marker complete + gate satisfied ⇒ finish (§13) |
| Condensation thrashing | one observation is a large share of the window, so each condensation is undone by the next tool result | size the read budget from the resolved window; below a floor, partition the task (§13) |
| No visibility into whether the loop earns its keep | nothing round-by-round survives past the final result | capture per-round mechanical-rejection and judgemental-finding counts by wrapping the bound callables (§14) |

---

## 16. Maintaining this skill

**Update this skill whenever new information becomes available** — an
implementation contradicts it, a project surfaces a failure mode not listed in
§15, or a design here turns out to be wrong in practice. It was distilled from
one project's design work and has not been proven across many; treat it as the
current best account, not settled fact.

**What belongs here:** anything about the *mechanism* — the loop, the contracts,
the roles, the exit conditions, the failure modes. If a lesson would transfer to
a project with a completely different artifact, it belongs here.

**What does not:** anything true only of one domain. Those stay in the consuming
project's design docs. The test is §4's reuse boundary — if it changes with the
artifact, it is not skill material.

**Record dead ends, not only conclusions.** The highest-value entries here are
the designs that look obviously right and fail on inspection — harness-assigned
keys (§5) and hard deletion (§6). Without the trace of *why* they fail, they get
re-proposed. When you discard an approach for a real reason, write the reason
down.

**Versioning** — bump `version` in the frontmatter:

- **patch** — wording and clarity, no change in guidance
- **minor** — a new section, failure mode, or guard added
- **major** — guidance here is reversed
