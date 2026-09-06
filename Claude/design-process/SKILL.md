---
name: design-process
description: Run a design conversation one decision at a time — short turns, plain language, side-threads parked in writing instead of raised in the moment. Use during the interactive design phase before implementation, when scoping changes and locking in decisions, or when the user says "let's design this", "one thing at a time", or asks to slow down / narrow the conversation.
version: 1.3.0
---

# Design, one thing at a time

This skill governs the **interactive design phase**: the conversation where you
and the user scope a change, understand its implications, and lock in decisions —
*before* any implementation plan is produced or any code is written.

The failure mode this exists to prevent is a good one: you investigate well, find
five real things, and put all five in one message. Every finding is true and
worth knowing. But the user now holds five open threads, answers one, and the
other four either die silently or resurface three turns later out of context.
Both of you end up carrying the whole design in working memory.

**The tension is real and you should not pretend it away.** Good design *is*
system-wide, and decisions *do* have downstream consequences. This skill does not
ask you to stop seeing them. It asks you to **write them down instead of saying
them now.** Breadth moves from the conversation into a file. That is the whole
trick.

## The four rules

1. **One thing at a time.** Each turn resolves or advances exactly one question,
   and ends with exactly one question. Never a menu of open items.
2. **Plain language.** Describe things by what they *do*, not by what they are
   called in the code.
3. **No unrequested implementation detail.** The user reviews code but does not
   live in it. Internals appear only when they change the answer.
4. **Short.** Target ~120 words. Hard ceiling ~200. If it doesn't fit, you are
   answering more than one question.

Rule 2 has a second half. A design turn is prose the user reads, so the
`simple-English` skill's "Avoiding AI-writing tells" section applies here in
full — its banned constructions and its banned-words table are the only place
those rules live. Read it before writing a turn, and add anything new to that
section. Brevity sharpens the tells: at a hundred words, one see-saw or one
compressed metaphor is a large share of everything the user sees. Rule 4 is
satisfied by cutting content, never by compressing meaning into a figure of
speech.

## The design file

Create one file at the start and keep it current — it is what makes rule 1
survivable.

**It does not belong in the project repo.** These notes are process artifacts,
not source; they belong beside the plan they will become. The conventional home
is the **ola agent folder** — a sibling of the project repo, usually `../agent`,
which ola owns and where the implementation plan will be written:

```
workspace/
  <project>/            # the source repo — design notes do NOT go here
  agent/                # ← design-notes.md, alongside the plan it becomes later
```

Look for that sibling folder first. If it already exists, write
`agent/design-notes.md` and say so in one clause. **If it does not exist, ask
where the notes should live before creating anything** — propose the sibling
`agent/` as the default, but do not conjure the folder unprompted. If the user
names somewhere else, use it.

The file holds two lists:

```markdown
# <topic> — design notes

## Decided
- <decision, one line, in plain language> — <why, one clause>

## Parked
- <the thing you noticed but did not raise> — <why it might matter, one clause>
```

Rules for the file:

- **Every finding you don't raise goes to Parked, immediately, in the same turn
  you found it.** Nothing gets dropped; it gets queued.
- **Every settled decision goes to Decided, immediately.** Not at the end.
- Tell the user in one clause when you park something ("parked two things about
  cost"). Do not list them.
- Parked items are one line each. If a parked item needs a paragraph, it needs
  its own turn later, not a longer line now.
- This file is the handoff artifact. When design is done, `Decided` is what the
  implementation plan is built from (by whichever planning skill takes over) —
  which is why it sits in the agent folder: the plan lands next to it, in the
  same place.

## Shape of a turn

```
<answer or finding — 1–3 sentences, plain>
<optional: one sentence on why it matters to the user's goal>

<one question, with a recommendation>
```

That's it. No headings, no tables, no phase lists, no code blocks — unless the
user asked for one, or a table genuinely *is* the answer (a cost comparison, a
before/after).

**Always recommend.** The user often cannot judge an internals question on its
merits, and a bare menu shifts a burden onto them that is yours to carry. Say
what you'd do and why, in one clause. Make "you pick" always a valid reply — if
they say it, decide, log it under Decided, and move on.

For a genuine fork with 2–4 clean options, `AskUserQuestion` is a good fit: one
question, recommended option first. Use it for forks, not for gathering
preferences in bulk.

## Sweeps

Breadth is not banned — it is **scheduled**.

Propose a sweep when any of these is true:

- the user asks for one
- 3 or more items are parked
- a decision just made contradicts or invalidates something already Decided
- you've been inside one narrow question for several turns and the surrounding
  shape hasn't been checked

Proposing is one sentence: *"Five things are parked — want to sweep them before
we go further?"* Do not sweep unilaterally.

A sweep is the **one place a list is allowed**. Output the parked items, one line
each, and ask which to pick up first. Then close the sweep and return to
one-at-a-time. Kill parked items that the intervening decisions have made moot —
say which, in one clause, don't re-argue them.

## Investigation

Investigate as deeply as you need to — depth of *research* is not what
overwhelms. Depth of *reporting* is.

After investigating, report only the part that bears on the open question. Park
the rest. If what you found changes a decision already in `Decided`, that
outranks the current question: say so plainly in one sentence, and make *that*
the one question on the table.

**Check the premise before you make it a fork.** A question built on an
unverified assumption is worse than no question: the user has to argue with the
framing before they can answer, and the framing is yours to get right. Before
presenting options, confirm the system does not already handle the thing —
read the code path, not just its neighbours. Most "how should we handle X"
questions dissolve on contact with the implementation, and the ones that survive
are the real design.

## Anti-patterns

Drawn from real transcripts. If you catch yourself writing any of these, stop and
cut the turn down.

- "Three details worth settling before I build" / "Three forks I'd rather you
  decide than me" — this is the core anti-pattern. Pick the most consequential
  one, park the rest.
- A turn with `##` headings for `Architecture`, `Sequencing`, and `What changes` —
  that's three turns wearing a coat.
- Naming a function, file path, or type as the *subject* of a question. "Should
  `_scrapfly_scrape` return `context.cost.total`?" → "Should we record what each
  fetch actually cost?"
- Explaining a consequence three hops downstream before the first hop is settled.
- Restating a settled decision to show your reasoning. It's in the file.
- A numbered implementation plan appearing mid-design. That comes after.

## Worked example

Real turn, condensed. The investigation behind both is identical.

**Before** (~600 words, five threads opened):

> ## Where cost is reported
> Both places, and we're already parsing the object that has it:
> - `context.cost.total` — plus `context.cost.details`, itemized by charge code…
> - `X-Scrapfly-Api-Cost` header, and critically `X-Scrapfly-Remaining-Api-Credit`…
>
> ## What our flags actually cost
> | Config | Credits | Breakdown |
> …
> ## The finding that changes things
> …six-month window with ~2 weeks left, and 881 credits in it…
>
> ## Regrouping — what I think changes
> 1. Thread cost out of `_scrapfly_scrape` …
> 2. Cheap-first scrape escalation …
> 3. Remaining-credit as a first-class dashboard tile …
> 4. Worker pool default 3, capped at 5.
>
> Item 2 wasn't in the original plan and is the one with real leverage. Where do
> you want to take it?

**After** (~90 words, one thread):

> Found a hard limit: you have ~880 fetch credits left, and the way we fetch
> today burns 6 per page. That's ~145 pages — your corpus is bigger than that, so
> a full run doesn't currently fit.
>
> The expensive part is rendering the page in a browser, which most pages don't
> need. Trying the cheap fetch first and only escalating when it comes back empty
> would stretch that to several hundred.
>
> Worth designing that in now, or leave it and accept the smaller run? I'd design
> it in — it's small and it's the difference between fitting and not.
>
> *(Parked: where cost is reported, and how many pages we fetch at once.)*

Same research. One decision on the table, no identifiers, and the two dropped
findings are safe in the file rather than gone.

## Keep this skill current

This skill is a working draft, not a finished rule set — it will not be right the
first time, and the way to improve it is to notice, in the middle of a real
design conversation, where it failed.

Update it whenever new knowledge arrives:

- a turn overwhelmed the user, or a question landed as unanswerable → the rule
  that should have caught it is missing or too weak
- the user pushes back on pace, length, or vocabulary → that correction is a rule
- a parked item turned out to have been urgent, or a sweep came too late → the
  sweep triggers need adjusting
- a phrasing worked notably well → consider promoting it to the worked example
- the surrounding process changes (what comes before or after this phase)

When you edit, **bump `version:` in the frontmatter** — patch for wording, minor
for a new or changed rule. Prefer replacing a rule over accumulating rules: this
file has to stay short enough to actually be followed, and a skill about brevity
that sprawls has refuted itself. Say in one line what changed and why.

## Ending the phase

Design is done when nothing is parked that the user wants to pursue, and
`Decided` reads as a coherent whole. Say so in a sentence and offer to turn
`Decided` into an implementation plan — that's where `ola-plan` (or an equivalent
planning skill) takes over. Do not start implementing from inside this skill.
