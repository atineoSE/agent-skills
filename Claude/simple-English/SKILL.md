---
name: simple-english
version: 1.3.0
description: Write and edit general-purpose text so a reader understands it on the first pass — a lighter, non-technical adaptation of the asd-ste100 skill, itself adapted from ASD-STE100 Simplified Technical English. Use for emails, articles, blog posts, essays, marketing copy, social posts, personal messages, business writing, or any prose aimed at a broad reader — not only documentation. Also use when asked to "simplify this text," "make this easier to read," "tighten this," or "reduce ambiguity" in writing that is not a technical manual.
---

# Simple English (general-purpose clarity)

This skill is the non-technical half of [[asd-ste100]]. That skill adapts ASD-STE100
Simplified Technical English for documentation, procedures, and instructions. This one strips
out everything that only makes sense for manuals — numbered steps, warnings and cautions,
notes, the instruction/description word-count split — and keeps the rules that make *any*
sentence easier to understand, including sentences whose job is to persuade, entertain, or
carry a voice.

> The primary objective is that readers immediately understand each sentence that they read.
> — ASD-STE100, rule 9.1

That objective does not stop applying once the writing has a personality. A joke that is
accidentally ambiguous is not funnier for it. A pitch with a dangling pronoun does not persuade
better. Clarity and voice are not opposites — most of what follows removes *accidental*
confusion while leaving every deliberate choice intact.

---

## How to use this skill

**When writing:** draft the content first, then apply the rules as a revision pass. Do not
try to obey a checklist while you are still deciding what to say.

**When editing (yours or someone else's):** run the [Revision pass](#revision-pass) at the
end of this file, top to bottom.

**When reviewing:** name the issue and give the rewritten sentence. "This is unclear" is not a
review.

**Judgment, always:** every rule below exists to remove *accidental* ambiguity or effort, never
to remove a choice the writer made on purpose. Read
[Judgment: rules vs. voice](#judgment-rules-vs-voice) before you flatten someone's writing.

---

## Rule map

| # | Rule | Section |
|---|------|---------|
| W1 | One word, one meaning — unless variety is the point | [Words](#words) |
| W2 | Use the plain word | [Words](#words) |
| W3 | No unexplained jargon or in-group shorthand | [Words](#words) |
| W4 | Describe actions with verbs, not with nouns | [Words](#words) |
| W5 | Prefer a single verb over a vague phrasal verb | [Words](#words) |
| W6 | Spell out Latin abbreviations | [Words](#words) |
| W7 | Keep noun stacks readable | [Words](#words) |
| S1 | One idea per sentence, by default | [Sentences](#sentences) |
| S2 | Keep an eye on sentence length | [Sentences](#sentences) |
| S3 | Prefer the active voice | [Sentences](#sentences) |
| S4 | Don't reach for a complex tense out of habit | [Sentences](#sentences) |
| S5 | Do not omit words to save space | [Sentences](#sentences) |
| S6 | Condition first, then the consequence | [Sentences](#sentences) |
| S7 | Replace an ambiguous pronoun with its noun | [Sentences](#sentences) |
| P1 | Give information gradually | [Structure](#structure) |
| P2 | One topic per paragraph, topic sentence first | [Structure](#structure) |
| P3 | Watch paragraph length | [Structure](#structure) |
| P4 | Repeat key words instead of varying them, when tracking one thing | [Structure](#structure) |
| P5 | Turn buried lists into vertical lists | [Structure](#structure) |
| P6 | Connect related sentences with connecting words | [Structure](#structure) |
| X1 | Prefer two sentences to a semicolon | [Punctuation](#punctuation) |
| X2 | Hyphenate words that act as one unit | [Punctuation](#punctuation) |
| X3 | Use parentheses for identifiers and short asides only | [Punctuation](#punctuation) |
| C1 | Keep one term per thing | [Consistency](#consistency) |
| C2 | Use neutral, non-gendered language | [Consistency](#consistency) |

---

## Words

### W1 — One word, one meaning — unless variety is the point

*Adapted from STE rules 1.3, 1.11, 9.2.*

Pick one term for one thing when the reader needs to track that thing across a document — a
product name, a technical term, a person's role, a recurring concept. Rotating synonyms for a
thing the reader must track makes them stop and ask whether you switched to something else.

```
DON'T  The service reads the config file. The daemon then validates the settings file
       and the process writes the parsed configuration back to disk.
DO     The service reads the config file. The service validates the config file. Then
       the service writes the config file back to disk.
```

The reverse holds too: do not use one word for two different things in the same piece.

```
DON'T  The client sends the request. The client approved the invoice on Monday.
DO     The app sends the request. The customer approved the invoice on Monday.
```

**Where this doesn't apply:** ordinary descriptive words that carry no tracking burden —
"big," "said," "walked" — can vary freely for rhythm and interest. That's elegant variation,
and it's a legitimate tool in narrative and marketing writing. The rule is about *things the
reader must not lose track of*, not about banning synonyms in general.

---

### W2 — Use the plain word

*Adapted from STE rules 1.1, 9.1.*

Prefer the short, frequent, concrete word. Reach for a longer or fancier word only when it
carries meaning the short word does not — including tone. "Utilize" over "use" rarely earns
its extra length; a deliberately formal or playful register sometimes does.

```
DON'T  Utilize the provided credentials prior to the commencement of the migration.
DO     Use the credentials before you start the migration.

DON'T  This facilitates the identification of duplicate entries.
DO     This finds duplicate entries.

DON'T  We endeavored to ascertain the root cause.
DO     We tried to find the cause.
```

Common swaps:

| Instead of | Write |
|---|---|
| utilize, leverage | use |
| prior to, in advance of | before |
| subsequent to, following | after |
| in order to | to |
| commence, initiate | start |
| terminate, cease | stop |
| ascertain, determine | find, decide |
| facilitate, enable (of a person) | help, let |
| endeavor, attempt | try |
| sufficient | enough |
| approximately | about |
| in the event that | if |
| a number of | some, three, many (say which) |
| is able to, has the capability to | can |
| in close proximity to | near |
| with regard to, in terms of | about, for |
| there is a possibility that | it is possible that |
| due to the fact that | because |

Do not force this into ugliness. If the plain replacement changes the meaning, kills the tone
you're going for, or produces bad English, restructure the sentence instead of swapping one
word.

```
DON'T  Without this change, the lifetime of the token can be uncertain.
DON'T  Without this change, the lifetime of the token cannot be known.   ← swap gives bad English
DO     Without this change, the token can expire sooner than you expect.
```

---

### W3 — No unexplained jargon or in-group shorthand

*Adapted from STE rule 1.10.*

If only people who already know the topic understand a word, and you haven't defined it, the
word fails a reader outside that circle. This includes internal nicknames, niche idiom, and
acronyms nobody has expanded.

```
DON'T  Do not brick the device during the firmware update.
DO     Do not make the device unusable during the firmware update.

DON'T  We punted on the retry logic this sprint.
DO     We put off the retry logic this sprint.
```

Real terms of art are fine when your audience shares them — they're the correct name for the
thing, not jargon. The test: **could a reader outside your immediate circle look this up and
find the meaning you intended?** If you're writing for an audience that already knows the term,
use it; the failure mode is using a term you assume everyone knows when they don't.

```
DO     The Content Delivery Network (CDN) caches the assets. The CDN keeps each asset
       for 24 hours.
```

---

### W4 — Describe actions with verbs, not with nouns

*Adapted from STE rule 3.7.*

A nominalization is a verb turned into a noun ("to decide" → "the decision"; "to install" →
"the installation"). Nominalized text is longer, vaguer, and hides who does what — which is
also why it's a favorite of evasive writing. Undoing it usually sharpens the sentence.

```
DON'T  Before the removal of the disk, make sure that the power is off.
DO     Before you remove the disk, make sure that the power is off.

DON'T  The performance of a validation of the input is required.
DO     Validate the input.
```

Watch for *verb + nominalization* — `perform an analysis`, `do a comparison`, `make an
adjustment`, `provide a summary`. Replace the pair with one verb: `analyze`, `compare`,
`adjust`, `summarize`.

---

### W5 — Prefer a single verb over a vague phrasal verb

*Adapted from STE rule 9.3.*

A phrasal verb (verb + preposition) often carries a concrete meaning and an unrelated
figurative one, and the reader has to guess which. "Put out the cat" and "put out the fire"
share no meaning. Non-native readers stumble here most.

```
DON'T  Put out the fire before you close the valve.
DO     Extinguish the fire before you close the valve.

DON'T  We need to figure out why the job blew up.
DO     We need to find why the job failed.
```

Keep phrasal verbs that are the natural, unambiguous way to say something in everyday
English — "put on" (a coat), "turn on," "log in," "give up," "look forward to." Most phrasal
verbs in ordinary conversational writing are fine; this rule targets the ones doing double duty
between a literal and a figurative sense in the same piece. Don't contort natural sentences to
avoid them.

---

### W6 — Spell out Latin abbreviations

*Adapted from STE GR-6.*

`e.g.`, `i.e.`, `etc.`, `viz.`, `cf.` help nobody who doesn't already know them, and `i.e.` and
`e.g.` are confused constantly even by people who do.

```
DON'T  Bring the basics (e.g., snacks, water, a charger).
DO     Bring the basics — for example, snacks, water, and a charger.

DON'T  Use the primary key, i.e., the record ID.
DO     Use the primary key, which is the record ID.
```

Often the abbreviation marks a list you never finished. Finish it or delete it.

---

### W7 — Keep noun stacks readable

*Adapted from STE rules 2.1, 2.2.*

A run of nouns stacked as modifiers forces the reader to guess which word modifies which,
because the meaning-bearing word (the head noun) usually comes last.

```
DON'T  Update the customer account balance reconciliation report schedule.
DO     Update the schedule for the customer balance reconciliation report.

DON'T  Increase the database connection pool timeout threshold value.
DO     Increase the timeout threshold for the database connection pool.
```

Break a long stack with prepositions (`of`, `for`, `in`, `on`), or hyphenate the words that act
as one unit (`main-gear-door` counts as one word, not three). If the long form is the item's
official name, spell it out once, define a short form, and use the short form after that.

---

## Sentences

### S1 — One idea per sentence, by default

*Adapted from STE rules 4.1, 6.1.*

The default is one subject, one idea. When a sentence carries two subjects stitched together
with a relative clause, consider splitting it — especially in writing meant to inform.

```
DON'T  The queue holds two workers connected together and attached with a supervisor
       between the scheduler and the retry handler.
DO     The queue holds two workers, connected to each other. A supervisor connects the
       workers to the scheduler and to the retry handler.
```

Also prefer a concrete statement over an abstract one when you can make one.

```
DON'T  Different temperatures will change the timing.
DO     When the temperature increases, the timing gets faster.
```

A sentence that pairs two superlatives is also carrying two ideas. The reader has to hold
both and match them up before the claim arrives.

```
DON'T  The industries where concentration rose the most are the industries where the
       share of income going to labour fell the most.
DO     Where a few companies took over an industry, workers in that industry received
       a smaller share of the income.
```

**Where this doesn't apply:** a sentence that deliberately piles up clauses for momentum, or
that holds a long list for rhetorical effect, is a choice — not an accident. The rule targets
sentences that are hard to parse because two unrelated ideas collided, not sentences that are
long on purpose.

---

### S2 — Keep an eye on sentence length

*Adapted from STE rules 5.1, 6.3.*

There's no single hard ceiling for general writing the way there is for maintenance
instructions, but past roughly 25–30 words a sentence usually needs two readings, not one. Use
that as a trigger to check the sentence, not as a rule to enforce mechanically.

```
DON'T  Pour the oil into the unit through the vent hole until the level is approximately
       6 mm below the surface of the flange cover, checking it against the gauge twice.
DO     Pour the oil into the unit through the vent hole. Stop when the level is about
       6 mm below the flange cover. Check it against the gauge twice.
```

When you do count, a number-with-unit, an abbreviation, an identifier, and a quoted phrase
each count as one word, not several — so `Tag "Section 4.2"` is 2 words, not 4.

---

### S3 — Prefer the active voice

*Adapted from STE rule 3.6.*

In the active voice the subject does the action. The passive hides the actor, and a reader who
doesn't know who acted often doesn't know who's responsible or what to do next.

```
DON'T  The circuits are connected by a switching relay.
DO     A switching relay connects the circuits.

DON'T  Mistakes were made.
DO     We made mistakes.
```

**Two legitimate uses of the passive:** when the agent is genuinely unknown or irrelevant
(`The window was broken sometime overnight`), and as a deliberate rhetorical choice — softening
a statement, keeping the focus on the object rather than the actor, or matching a formal
register. Active is the default; passive is a tool you reach for on purpose, not a habit you
fall into.

---

### S4 — Don't reach for a complex tense out of habit

*Adapted from STE rules 3.2, 3.4, 3.5.*

Simple tenses — present, past, future, infinitive, imperative — carry most general writing and
are the easiest to parse. Perfect and progressive tenses ("has adjusted," "will have been
archived," "is running") add length and often add nothing.

```
DON'T  The team has finalized the decision.
DO     The team finalized the decision.

DON'T  When you are running this process, watch the logs.
DO     When you run this process, watch the logs.
```

This is a default, not a ban. Narrative sequencing, hypotheticals, and nuanced timing
legitimately need perfect or progressive tenses — "By the time she arrived, the meeting had
already ended" says something a simple past cannot. Use the complex tense when the timeline
actually requires it; skip it when a simple tense says the same thing shorter.

`-ing` constructions are the most common source of runaway sentences, because they can be a
verb, an adjective, or the start of a dangling clause, and the reader has to work out which.

```
DON'T  Engineers relying on outdated documentation and skipping the review step
       introduce bugs that surface weeks later.
DO     When engineers rely on outdated documentation and skip the review step, they
       introduce bugs that surface weeks later.
```

---

### S5 — Do not omit words to save space

*Adapted from STE rules 4.2, 4.5, GR-1.*

A shorter sentence isn't automatically clearer. Dropped subjects, dropped verbs, and dropped
articles cost the reader more than they save — outside of genres (headlines, captions, notes to
self) where the omission is a known convention.

```
DON'T  Can be a maximum of five inches long.
DO     A crack can have a maximum length of five inches.

DON'T  If installed, remove the shims.
DO     If the shims are installed, remove them.
```

Keep the conjunction **"that"** in formal or informative writing. Dropping it in speech is
natural; in writing it marks exactly where the main clause ends.

```
DON'T  The dashboard shows the queue is empty.
DO     The dashboard shows that the queue is empty.
```

The same applies to a list bolted onto a sentence with a dash. It usually drops the
subject and the verb, and it often mixes grammatical shapes, so the reader has to
assemble the claim out of parts.

```
DON'T  A few companies take most of the sales — very productive, high prices, and
       only a small slice of revenue going out in wages.
DO     A few companies take most of the sales. These companies are very productive,
       they command high prices, and they pay only a small slice of their revenue
       in wages.
```

Contractions are a register choice, not an error — use them freely in conversational writing
(this document uses them) and avoid them where the register is formal.

---

### S6 — Condition first, then the consequence

*Adapted from STE rule 5.4.*

If the reader needs a condition to make sense of what follows, give the condition first. This
is a strong default for informative and instructive writing, where the reader shouldn't act (or
read the payoff) before they have the context.

```
DON'T  Set the switch to NORMAL when the light comes on.
DO     When the light comes on, set the switch to NORMAL.

DON'T  Restart the service if the health check fails three times.
DO     If the health check fails three times, restart the service.
```

**Where this doesn't apply:** narrative and persuasive writing often lead with the outcome or
the hook on purpose — "The deal fell through, and here's why" is a legitimate structure. Use
condition-first as the default for anything the reader must act on or follow logically; treat
it as optional where the *point* is the payoff, not the sequence.

---

### S7 — Replace an ambiguous pronoun with its noun

*Adapted from STE GR-3, GR-4.*

If `it`, `they`, `this`, or `that` could point at more than one thing, the sentence is
ambiguous — in a spec, an email, or a novel alike. This is one of the few rules with no
stylistic exception: an ambiguous pronoun is always a defect, never a choice.

```
DON'T  If you insert the pins into the sockets incorrectly, they can be damaged.
DO     If you insert the pins into the sockets incorrectly, the pins can be damaged.
```

`This` at the start of a sentence, pointing back at a whole previous clause, is the worst
offender. Name what `this` refers to.

```
DON'T  Make sure that the cover is not locked (this can cause damage to the probe).
       ← which state damages the probe: locked, or unlocked?
DO     Make sure that the cover is not locked. A locked cover can damage the probe.
```

---

## Structure

### P1 — Give information gradually

*Adapted from STE rule 6.1.*

Introduce one fact, then build on it. Don't open with a sentence that assumes several things
the reader hasn't been told yet.

```
DON'T  During the approach, deviation pointers in the course indicators give commands to
       fly up or down and left or right, information which comes from the transceivers
       that form part of the Instrument Landing System.
DO     The Instrument Landing System helps the pilot during the approach to the runway.
       It shows the pilot's deviation from the intended course. That course is a fixed
       line to the runway's centerline, at a constant angle of descent.
```

Each sentence should add exactly one new thing, building from something the previous sentence
already established.

---

### P2 — One topic per paragraph, topic sentence first

*Adapted from STE rules 6.4, 6.5.*

The first sentence of a paragraph states the topic; the rest explain it. A new topic means a
new paragraph.

The test: **copy out the first sentence of every paragraph. Do they form a usable outline?** If
not, the topics are in the wrong places.

---

### P3 — Watch paragraph length

*Adapted from STE rule 6.6.*

A paragraph much past six or seven sentences usually has a second topic hiding inside it, or is
just tiring to read in a block. Split it — the split point is almost always where the second
topic starts. (Conversational or narrative writing can run longer for pacing; the test is
whether a reader can still tell what the paragraph is "about" by the end.)

---

### P4 — Repeat key words instead of varying them, when tracking one thing

*Adapted from STE rule 6.2.*

Sentences connect when a later one picks up a word from an earlier one — that's the main
mechanism that makes a paragraph read as one thought. This matters most when the reader must
track a specific thing across sentences (a system, a decision, a person).

```
Sentence 1  The new pricing model rewards early renewal.
Sentence 2  This model gives a 10% discount for renewals booked before day 30.
            ↑ picks up "model" — connected, and adds one new fact
```

This is W1 applied at paragraph scale, with the same exception: ordinary descriptive words can
still vary freely.

---

### P5 — Turn buried lists into vertical lists

*Adapted from STE rule 4.3.*

When a sentence carries several items or several steps, consider a list. Lists are one of the
highest-leverage changes available for dense text, in a report or a blog post alike.

```
DON'T  The plan covers hiring, onboarding, the 30-60-90 review, and the transition to a
       permanent role.
DO     The plan covers:
       - Hiring
       - Onboarding
       - The 30-60-90 review
       - The transition to a permanent role
```

Rules for a clean list:

- End the lead-in sentence with a colon.
- Keep items grammatically parallel (all noun phrases, or all full sentences — not a mix).
- Put a period at the end of an item only if the item is a full sentence; be consistent within
  the list.
- Keep all items at the same level.
- Make every item read correctly against the lead-in text.

---

### P6 — Connect related sentences with connecting words

*Adapted from STE rules 4.4, 6.2.*

Connecting words are traffic signs: `and`, `but`, `then`, `so`, `as a result`, `at the same
time`. They tell the reader whether what's next is more of the same, a contrast, or a
consequence.

```
These numbers look good on their own. But last quarter's were better.
```

Starting a sentence with `And` or `But` is correct and often clearer than welding two clauses
together with a semicolon or a subordinate conjunction.

**This rule is the counterweight to S1.** Splitting every idea into its own sentence and then
leaving the sentences unconnected gives you prose that is correct and lifeless — a list of
facts where an argument should be. The sentences sit side by side instead of developing.

```
DON'T  Workers in that industry received a smaller share of the income. More and more of
       the work moved inside those companies. A job there paid below what the work
       produced.
DO     Workers in that industry received a smaller share of the income. Meanwhile, more
       and more of the work moved inside those companies. So a job there paid below what
       the work produced.
```

For every sentence after the first in a paragraph, you should be able to say which of the
three it is: more of the same, a contrast, or a consequence. If none of them fits, the
sentence probably belongs in a different paragraph.

---

## Punctuation

### X1 — Prefer two sentences to a semicolon

*Adapted from STE rule 8.1.*

Two independent sentences are usually easier to parse than one joined by a semicolon, and the
semicolon is a punctuation mark many writers place incorrectly.

```
DON'T  Examine the removed parts; replace the damaged ones.
DO     Examine the removed parts for damage. Replace the damaged parts.
```

This is a default, not a ban. A semicolon joining two tightly related, parallel clauses is
correct and sometimes exactly the rhythm a sentence needs — use it deliberately, not as a lazy
substitute for a period or a comma splice fix.

### X2 — Hyphenate words that act as one unit

*Adapted from STE rules 8.2, 8.7.*

A hyphen tells the reader which words belong together, and collapses a word stack into one
countable unit. Hyphenate:

- Multi-word adjectives before a noun — `low-latency path`, `up-to-date information`,
  `trial-and-error method`
- Two-word numbers and fractions — `forty-seven`, `three-sixteenths`
- A letter or number plus a noun that gives a shape — `L-shaped bracket`, `3-prong connector`
- A prefix ending in a vowel before a root starting with a vowel — `pre-amplifier`, `de-icing`

A hyphen is not a dash. A dash separates ideas or shows a range; a hyphen binds words.

### X3 — Use parentheses for identifiers and short asides only

*Adapted from STE rule 8.3.*

Legitimate uses: a cross-reference, an item identifier, an abbreviation on first use, a short
aside. If the aside needs more than about ten words, it's a sentence — write it as one, or work
it into the main sentence with a dash instead.

---

## Consistency

### C1 — Keep one term per thing

*Adapted from STE rule 9.4.*

When the reader must track a specific person, product, feature, or concept across a piece, use
the same name for it every time. This is W1 restated as a whole-document habit: pick the term
in the first paragraph, and don't let it drift.

Note the difference from technical procedures, where every *instance of a repeated action* also
gets the same wording (STE rule 9.4 in full) — that level of rigidity isn't generally needed
outside step-by-step instructions, and enforcing it on ordinary prose produces flat, robotic
writing. Apply C1 to **names of things**, not to every sentence shape.

### C2 — Use neutral, non-gendered language

*Adapted from STE GR-7, GR-8.*

Use gender-neutral terms and constructions. Where a person's pronouns are not known, use
`they`. Prefer the role (`the manager`, `the reviewer`, `the customer`) or address the reader as
`you` when that fits the piece.

---

## Revision pass

Run these in order on any general-purpose text. Each check is cheap; the order puts the
highest-value fixes first.

1. **Structure** — Does each paragraph have one topic, with the topic in its first sentence?
   Do the first sentences form an outline? (P1, P2, P3)
2. **Lists** — Is any sentence carrying three or more items? Consider a list. (P5)
3. **Length** — Any sentence well past 25–30 words? Check whether it should split. (S2)
4. **Voice** — Search for `is`, `are`, `was`, `were`, `be`, `been` followed by a past
   participle. Is the passive doing something on purpose here, or just hiding the actor? (S3)
5. **Pronouns** — For every `it`, `they`, `this`, `that`: can it point at more than one noun?
   Replace it with the noun. (S7) — no exceptions on this one.
6. **Terminology** — List every term for every thing the reader must track. One term each,
   used consistently. (W1, C1)
7. **Nominalizations** — Search for `-tion`, `-ment`, `-ance`, `-ing of`. Could it be a verb
   instead? (W4)
8. **Word choice** — Replace inflated words with plain ones and unexplained jargon with a
   defined term, where the register allows it. (W2, W3, W5)
9. **Omissions** — Restore a dropped `that` or a dropped subject where it costs clarity, not
   where the register calls for the shorter form. (S5)
10. **Punctuation** — Check every semicolon: earned, or a lazy period? Spell out stray `e.g.`,
    `i.e.`, `etc.` if the audience won't know them. (X1, W6)

---

## Judgment: rules vs. voice

Every rule above targets *accidental* confusion: a pronoun with two possible referents, a
sentence that collapses two unrelated ideas, a passive that hides who's responsible, a term
that quietly means two different things. That kind of confusion never helps a piece of writing,
no matter its genre — a joke, a pitch, and a spec are all worse when the reader has to stop and
reread a sentence to figure out what it means.

What the rules do **not** target, and what you should leave alone:

- **Voice and register.** A specific person's rhythm, sentence length, quirks, and word choices
  are the point, not a defect. If someone didn't ask you to flatten their writing, don't.
- **Deliberate ambiguity, suspense, or vagueness.** A mystery withholds information on purpose.
  A tagline is vague on purpose. That's different from a reader losing track of what "it"
  refers to.
- **Rhythm-driven length and structure.** A long sentence that builds momentum, a one-word
  sentence for punch, a semicolon that joins two balanced clauses — these are choices, and a
  mechanical word-count or "split every long sentence" pass will kill them.
- **Genre conventions.** Headlines drop articles. Captions drop verbs. Texts use contractions
  and sentence fragments. These aren't errors to fix; they're the register working as intended.

The practical test throughout this skill: **would the writer keep this if they saw the
alternative?** If yes — it's voice, leave it. If the answer is "oh, I didn't mean that" — it's
the kind of accidental confusion these rules exist to catch.

---

## Avoiding AI-writing tells

This applies to everything the skill touches, not a special case for public or named
writing. Every piece of writing should read like a person wrote it, not a model.
Readers now recognise the tells, and recognising them costs the writer credibility
instantly.

Plain first-person sentences beat clever constructions.

### Banned constructions

- The "X — or Y" em-dash antithesis
- Openers that restate the question
- **The negate-then-correct pair**, in every form it takes. "It's not just X,
  it's Y." "You do not need a company town. You need switching to be costly."
  "X is not the point. Y is." "Not because X, but because Y." The softer forms
  count too, and are easier to catch yourself writing: "it is about X rather
  than Y," "less about X and more about Y," "it's Y, not X." Every one of them
  hands the reader a wrong answer to discard before giving them the right one.
  One of these can be a real rhetorical move; as a habit it becomes the
  default rhythm of every paragraph, and a reader who notices the see-saw stops trusting the writer.
  State the true thing on its own. If a contrast matters, the facts will carry
  it without the scaffolding.

  Rewriting the example above: "Employers get this power whenever switching
  jobs is costly, and switching jobs is costly for almost everyone." And a soft
  one: "it is about which firms you work for rather than what you do" becomes
  "A third strand is about the company you work for."

- **Say-it-twice** — an abstract label followed by its own plain-English
  translation. "And the mechanism is mostly reallocation. Work moved to the kind
  of firm that pays out less of what it earns." The first sentence names
  something that the second sentence then has to explain, which means the first
  sentence did no work. A person writes one of the two. Write the plain one, and
  keep the label only where the reader will meet it again later.

- **A closing line that is a compressed metaphor.** "The jobs changed address."
  "The floor moved under them." The end of a paragraph is where the reader is
  handed the point, and a figure of speech there makes them unpack it first.
  Say what happened in the flattest words available, and finish the
  *explanation* rather than the finding — what the mechanism was like for the
  person inside it. "A job there paid well below what the work produced. On its
  own, though, the pay looked fine. There was nothing on a payslip to notice,
  and the gap kept widening."

- **"Worth ___ing" as a signpost.** "The side effect is the part worth
  dwelling on." "There is a counterweight worth naming." "That is worth
  noticing, because..." Each one spends a clause telling the reader that
  something matters instead of showing them why. Delete the frame and make
  the claim: "The side effect matters more than the reason did." Ordinary
  uses of the phrase survive — a thing can still be worth paying for.

### Banned words

Each of these is banned **in a particular use**, not everywhere. The plain,
literal sense of the word is fine, and blanket-banning it produces worse
writing than leaving it alone.

| Word | Banned use | Still fine |
|---|---|---|
| delve | any | — |
| landscape | figurative ("the funding landscape") | actual scenery |
| leverage | as a verb | the noun, in finance or negotiation |
| honest | characterizing your own account or the evidence: "the honest answer is," "two honest caveats," "where the research gets honest and awkward" | when honesty is the actual subject: "they believed one price for everyone was more honest" |
| land, lands | arriving at a result or reaching people: "his model lands on one outcome," "an improvement that lands on everyone" | aircraft, jumps, fish |
| mechanical | characterizing an argument or a process: "almost boringly mechanical," "his point was mechanical rather than moral" | machines, and a mechanic |
| genuinely | as an intensifier: "genuinely mixed," "genuinely helps," "genuinely argued over" — it almost always deletes with no loss | where it separates the real thing from a counterfeit: "a genuinely good car," as against one sold as good |

For the banned uses, say the thing plainly instead. "The honest answer is that
X" is just "X," with a claim to candor bolted on the front — and announcing
candor is weaker than being candid. "His model lands on one outcome" is "his
model produces one outcome." "The mechanism was almost boringly mechanical" is
a promise to explain that never explains; write the simple thing the sentence
was gesturing at.

### Growing these lists

Both lists are meant to grow, and they grow from real complaints rather than
from suspicion. When a reader flags a word or a construction as sounding
machine-written, add a row or a bullet here, with the offending phrase quoted
and the narrower legitimate use named alongside it. Naming the legitimate use
is the part that keeps the rule usable; a rule that bans a word outright will
be either ignored or obeyed into nonsense.

This stacks on top of the rest of the skill, not instead of it. The rules above catch
accidental confusion; this one catches what specifically reads as AI-written. Good
writing has to clear both.

---

## What this skill drops from asd-ste100

This skill removes everything in [[asd-ste100]] that only makes sense for step-by-step
procedures and manuals, since general-purpose text rarely takes that shape:

- **The Instructions section** (imperative-only steps, one action per numbered step, notes vs.
  steps, limits stated with the step). General writing gives instructions in prose, in context,
  woven into sentences — not as a numbered procedure.
- **The Risk and consequence section** (the warning/caution taxonomy, uppercase formatting, the
  aerospace safety apparatus). Where a general piece needs to flag a real risk, say what goes
  wrong and what it costs in plain prose — the underlying instinct survives as ordinary good
  writing, without the manual's formatting.
- **The instruction/description word-count split.** General writing doesn't have that
  structural distinction, so S2 collapses to one loose guideline.
- **The controlled dictionary and the technical noun/verb categories** (already dropped in
  asd-ste100, and still dropped here).

And unlike asd-ste100, this skill does not exempt persuasive, entertaining, or personal-voice
writing from the outset — see [Judgment: rules vs. voice](#judgment-rules-vs-voice) above for
how to apply it there instead of skipping it.

---

## Source

Derived from [[asd-ste100]], itself adapted from ASD-STE100 Simplified Technical English,
Issue 9 (2025-01-15), Part 1 — Writing rules. Published by the AeroSpace and Defence Industries
Association of Europe (ASD), Brussels. Free for non-commercial use from
[asd-ste100.org](https://www.asd-ste100.org).

Rule numbers cited throughout (`STE rule 5.4`, `GR-3`) refer to that document by way of
asd-ste100, so any rule here can be traced back to its source.

---

## Changelog

- **1.3.0** — Removed the ban on rule-of-three lists; threes are allowed
  everywhere, including as a document skeleton. Extended the negate-then-correct
  bullet to cover its softer forms ("X rather than Y", "less about X and more
  about Y"). Added two constructions: say-it-twice (an abstract label followed
  by its own gloss) and a closing line that is a compressed metaphor. Added a
  superlative-pairing example to S1 and a dangling-appositive-list example to
  S5. Strengthened P6 as the stated counterweight to S1 — one idea per sentence,
  pushed unopposed, produces disconnected prose.

- **1.2.1** — Added "worth ___ing" as a signpost construction, and "genuinely"
  as an intensifier, both measured as over-used across a real body of drafted
  work rather than suspected.
- **1.2.0** — Split "Avoiding AI-writing tells" into banned constructions and a
  banned-words table, each banned use paired with the legitimate use it must
  not swallow. Named the negate-then-correct pair in full ("You do not need X.
  You need Y." and relatives). Added "honest" as self-characterization, "land"
  for arriving at a result, and "mechanical" as a description of an argument.
  Added a rule for growing both lists from real complaints.

Bump `version` in the frontmatter and add an entry here whenever this skill's rules
change.

- **1.1.0** — Added "Avoiding AI-writing tells," a skill-wide rule against writing that
  reads as LLM output.
- **1.0.0** — Initial version.
