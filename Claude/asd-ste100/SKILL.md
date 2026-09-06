---
name: asd-ste100
version: 1.0.0
description: Write and edit text so a reader understands each sentence the first time — a general-purpose adaptation of ASD-STE100 Simplified Technical English (Issue 9). Use when drafting or revising documentation, READMEs, specs, runbooks, procedures, release notes, commit messages, PR descriptions, agent/tool instructions, prompts, or any message that must be unambiguous for a busy, non-native, or hurried reader. Also use when asked to "make this clearer", "tighten this", "simplify this text", "reduce ambiguity", or to review someone else's writing for clarity.
---

# Sharper, clearer communication (ASD-STE100 adaptation)

ASD-STE100 Simplified Technical English is the controlled-language standard the aerospace
industry uses so that a maintenance technician in any country reads an instruction once,
understands it once, and does not guess. This skill takes the **rules that transfer to
general writing** and drops the parts that only make sense inside an aircraft manual.

> The primary objective is that readers immediately understand each sentence that they read.
> — ASD-STE100, rule 9.1

Everything below serves that one objective. When two rules conflict, the one that makes the
reader understand faster wins.

---

## How to use this skill

**When writing:** draft the content first, then apply the rules as a revision pass. Do not
try to obey thirty rules while you are still deciding what to say.

**When editing (yours or someone else's):** run the [Revision pass](#revision-pass) at the
end of this file, top to bottom. It is ordered by how much clarity each check buys.

**When reviewing:** report the rule that a sentence breaks and give the rewritten sentence.
Do not report a rule violation without a replacement — "this is unclear" is not a review.

**Judgment:** these are rules for text that must be *understood*, not text that must be
*enjoyed*. Read [When not to apply this](#when-not-to-apply-this) before you flatten someone's
voice.

---

## Rule map

| # | Rule | Section |
|---|------|---------|
| W1 | One word, one meaning. One meaning, one word | [Words](#words) |
| W2 | Use the plain word | [Words](#words) |
| W3 | No jargon, slang, or in-group shorthand | [Words](#words) |
| W4 | Describe actions with verbs, not with nouns | [Words](#words) |
| W5 | No phrasal verbs where a single verb exists | [Words](#words) |
| W6 | No Latin abbreviations | [Words](#words) |
| W7 | Keep noun stacks to three words | [Words](#words) |
| S1 | One idea per sentence | [Sentences](#sentences) |
| S2 | 20 words for instructions, 25 for description | [Sentences](#sentences) |
| S3 | Use the active voice | [Sentences](#sentences) |
| S4 | Use simple tenses | [Sentences](#sentences) |
| S5 | Do not omit words to save space | [Sentences](#sentences) |
| S6 | Condition first, then the action | [Sentences](#sentences) |
| S7 | Replace an ambiguous pronoun with its noun | [Sentences](#sentences) |
| P1 | Give information gradually | [Structure](#structure) |
| P2 | One topic per paragraph, topic sentence first | [Structure](#structure) |
| P3 | Six sentences maximum per paragraph | [Structure](#structure) |
| P4 | Repeat key words instead of varying them | [Structure](#structure) |
| P5 | Turn complex sentences into vertical lists | [Structure](#structure) |
| P6 | Connect related sentences with connecting words | [Structure](#structure) |
| I1 | Write instructions in the imperative | [Instructions](#instructions) |
| I2 | One instruction per step | [Instructions](#instructions) |
| I3 | Notes inform; they never instruct | [Instructions](#instructions) |
| I4 | Give limits and results with the step, not after it | [Instructions](#instructions) |
| R1 | Warn before the action, not after | [Risk and consequence](#risk-and-consequence) |
| R2 | Name the risk and the consequence in concrete words | [Risk and consequence](#risk-and-consequence) |
| X1 | No semicolons | [Punctuation](#punctuation) |
| X2 | Hyphenate words that act as one unit | [Punctuation](#punctuation) |
| X3 | Use parentheses for identifiers and asides only | [Punctuation](#punctuation) |
| C1 | Same action, same wording, every time | [Consistency](#consistency) |
| C2 | Use neutral, non-gendered language | [Consistency](#consistency) |

---

## Words

### W1 — One word, one meaning. One meaning, one word

*Adapted from STE rules 1.3, 1.11, 9.2.*

Pick one term for one thing and never rotate synonyms for variety. Rotating terms makes the
reader ask whether you switched to a different thing. In technical text, elegant variation is
a defect.

```
DON'T  The service reads the config file. The daemon then validates the settings file
       and the process writes the parsed configuration back to disk.
DO     The service reads the config file. The service validates the config file. Then
       the service writes the config file back to disk.
```

The reverse holds too: do not use one word for two things. If "client" means both the
customer and the HTTP client library in the same document, rename one of them.

```
DON'T  The client sends the request. The client approved the invoice on Monday.
DO     The SDK sends the request. The customer approved the invoice on Monday.
```

Words with a restricted meaning must keep that meaning throughout. If "release" means a
tagged version in paragraph one, it cannot mean "let go of a lock" in paragraph four.

---

### W2 — Use the plain word

*Adapted from STE rules 1.1, 9.1 (the controlled dictionary, generalized).*

STE approves 875 words. You do not have that dictionary, but you have its principle: prefer
the short, frequent, concrete word. Reach for a longer word only when it carries meaning the
short word does not.

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
| perform a check of | check |
| due to the fact that | because |

Do not force this into ugliness. If the plain replacement changes the meaning or produces bad
English, restructure the sentence instead of swapping one word (STE rule 9.1).

```
DON'T  Without this change, the lifetime of the token can be uncertain.
DON'T  Without this change, the lifetime of the token cannot be known.   ← swap gives bad English
DO     Without this change, the token can expire sooner than you expect.
```

---

### W3 — No jargon, slang, or in-group shorthand

*Adapted from STE rule 1.10.*

If only the team that wrote the text understands a word, the word fails. This includes
regional idiom, industry slang, and internal nicknames.

```
DON'T  Do not brick the device during the firmware update.
DO     Do not make the device unusable during the firmware update.

DON'T  We punted on the retry logic this sprint.
DO     We did not implement the retry logic in this sprint.
```

Real technical terms are fine — they are the correct name for the thing. "Mutex", "TLS
handshake", and "idempotent" are terms, not jargon. "Sprinkle some magic on the config" is
jargon. The test: **could a competent reader from a different team look this up and find the
same meaning you intended?**

Define a term once, in full, the first time it appears. Then use the short form consistently.

```
DO     The Content Delivery Network (CDN) caches the assets. The CDN keeps each asset
       for 24 hours.
```

---

### W4 — Describe actions with verbs, not with nouns

*Adapted from STE rule 3.7.*

A nominalization is a verb turned into a noun ("to decide" → "the decision"; "to install" →
"the installation"). Nominalized text is longer, vaguer, and hides who does what.

```
DON'T  Before the removal of the disk, make sure that the power is off.
DO     Before you remove the disk, make sure that the power is off.

DON'T  The performance of a validation of the input is required.
DO     Validate the input.
```

Watch for the pattern *verb + nominalization* — `perform an analysis`, `do a comparison`,
`make an adjustment`, `provide a summary`. Replace the pair with one verb: `analyze`,
`compare`, `adjust`, `summarize`.

---

### W5 — No phrasal verbs where a single verb exists

*Adapted from STE rule 9.3.*

A phrasal verb (verb + preposition) usually has a concrete meaning and an abstract one, and
the reader has to pick. "Put out the cat" and "put out the fire" share no meaning at all.
Non-native readers and translation engines both stumble here.

```
DON'T  Put out the fire before you close the valve.
DO     Extinguish the fire before you close the valve.

DON'T  The reaction can give off toxic fumes.
DO     The reaction can release toxic fumes.

DON'T  We need to figure out why the job blew up.
DO     We must find why the job failed.
```

Keep phrasal verbs that have one settled, physical meaning and no single-word equivalent:
"put on" (protective equipment), "turn on", "log in". Do not contort the language to remove
them.

---

### W6 — No Latin abbreviations

*Adapted from STE GR-6.*

`e.g.`, `i.e.`, `etc.`, `viz.`, `cf.`, `N.B.` help nobody who does not already know them, and
`i.e.` and `e.g.` are confused constantly even by people who do.

```
DON'T  Discard the standard parts (e.g., washers, bolts, nuts) after each removal.
DO     Discard the standard parts (for example, washers, bolts, and nuts) after each removal.

DON'T  The wires can be different colors (blue, green, red, etc.).
DO     The wires can be blue, green, red, or a different color.

DON'T  Use the primary key, i.e., the record ID.
DO     Use the primary key, which is the record ID.
```

Often the abbreviation marks a list you never finished. Finish it or delete it.

---

### W7 — Keep noun stacks to three words

*Adapted from STE rules 2.1, 2.2.*

A stack of nouns forces the reader to guess which word modifies which. The head noun is
usually last, so a five-word stack means holding four modifiers in mind before you learn what
the thing even is. Many languages put the head noun first, so non-native readers reconstruct
the whole stack backwards.

```
DON'T  Runway light connection resistance calibration                     (5 words)
DO     Calibration of the resistance of the runway light connection       (1 + 1 + 3)

DON'T  Update the customer account balance reconciliation report schedule.  (6 words)
DO     Update the schedule of the reconciliation report for customer balances.

DON'T  Increase the database connection pool timeout threshold value.
DO     Increase the timeout threshold for the database connection pool.
```

Two ways to fix a long stack:

1. **Break it with prepositions** — `of`, `for`, `in`, `on`. Shown above.
2. **Hyphenate the words that act as one unit** — `main-gear-door retraction-winch handle`
   counts as three words, not five. Never hyphenate the whole stack; that only hides the
   problem.

If the long form is the item's official name, write it in full the first time, then define a
short form and use the short form after that.

```
DO     Open the incident response escalation policy (in this document, "the escalation
       policy"). The escalation policy names two on-call engineers.
```

---

## Sentences

### S1 — One idea per sentence

*Adapted from STE rules 4.1, 6.1.*

Each sentence carries one subject and one idea. When a sentence has two subjects joined by a
relative clause, split it.

```
DON'T  The queue holds two workers connected together and attached with a supervisor
       between the scheduler and the retry handler.
DO     The queue holds two workers. The workers are connected to each other. A supervisor
       connects the workers to the scheduler and to the retry handler.
```

Also: do not write abstractly when a concrete statement is available.

```
DON'T  No leaks are permitted.
DO     Make sure that there are no leaks.

DON'T  Different temperatures will change the cure time.
DO     When the temperature increases, the cure time decreases.
DO     The cure time is 2 hours at 20 °C.       ← better still: give the number
```

---

### S2 — 20 words for instructions, 25 for description

*Adapted from STE rules 5.1, 6.3.*

Hard limits, not averages. Instructions get the shorter budget because the reader is doing
something else with their hands while they read.

```
DON'T  Pour the preservation oil into the unit through the vent hole until the oil level
       is approximately 6 mm below the surface of the flange cover.        (25 words)
DO     Pour the preservation oil into the unit through the vent hole. Continue until the
       oil level is about 6 mm below the flange cover.                     (10 + 15 words)
```

Counting rules that keep the limit honest:

- A number, or a number with its unit (`20 kg`, `10 °C`), counts as **one** word.
- An abbreviation counts as one word. `NASA`, `VPN`, `a.m.`
- An alphanumeric identifier counts as one word. `No. 1`, `36L7`, `v2.3.1`
- Quoted text, a title, or a label counts as **one** word: `Touch the "Service Overview"
  arrow` is 6 words.
- A hyphenated group counts as one word. `soap-and-water solution` is one.
- Text in parentheses counts as one word in the host sentence — and also counts as its own
  separate sentence, which must obey the limit on its own.
- A colon that introduces a vertical list ends the sentence. Everything before the colon must
  fit the limit, and **each list item is a new sentence** with its own limit.

---

### S3 — Use the active voice

*Adapted from STE rule 3.6.*

In the active voice the subject does the action. The passive hides the actor, and a reader who
does not know who acts does not know whether they must act.

```
DON'T  The circuits are connected by a switching relay.
DO     A switching relay connects the circuits.

DON'T  These values are used by the scheduler to calculate the backoff.
DO     The scheduler calculates the backoff from these values.

DON'T  The volume control can be adjusted.
DO     Adjust the volume control.              ← as an instruction
DO     You can adjust the volume control.      ← as a description
```

Four ways to convert:

1. Move the agent (usually after "by") to the front and make it the subject.
2. Replace a weak infinitive construction with the real verb (`are used by X to calculate` →
   `X calculates`).
3. In instructions, use the imperative: `The test can be continued` → `Continue the test`.
4. When no agent is named, use `you` (the reader) or `we` (your team/organization).

**The one exception:** in descriptive text, the passive is correct when the agent is genuinely
unknown, and forcing an active voice would state something false.

```
DO     During transmission, the data was corrupted.        ← agent unknown, passive is correct
DON'T  Transmission corrupted the data.                    ← now it claims a false cause
```

---

### S4 — Use simple tenses

*Adapted from STE rules 3.2, 3.4, 3.5.*

Use only: the infinitive, the imperative, the simple present, the simple past, the simple
future, and the past participle **as an adjective**. Avoid perfect tenses, progressive
tenses, and stacked auxiliaries — they add length without adding meaning.

```
DON'T  The operator has adjusted the linkage.
DO     The operator adjusted the linkage.

DON'T  The record will have been archived by the time the job finishes.
DO     The job archives the record before it finishes.

DON'T  When you are running this procedure, obey all safety precautions.
DO     When you run this procedure, obey all safety precautions.
```

The past participle as an adjective is fine and is not passive voice: `the disassembled unit`,
`the archived record`, `Make sure that the surfaces are not damaged.`

`-ing` words are the most common source of runaway sentences, because they can be a verb, an
adjective, a noun, or the start of a clause, and the reader must work out which.

```
DON'T  Engineers opening containers holding hazardous materials in areas lacking
       ventilation, using unsuitable tools without following the manufacturer's
       instructions, risk skin and lung injury.
DO     Before you use hazardous materials, obey these precautions:
       1. Read the manufacturer's instructions.
       2. Make sure that the work area has enough airflow.
       3. Put on a face mask and protective clothing.
       4. Get the correct tools to open the containers.
       If you do not obey these precautions, injury to your skin and lungs can occur.
```

`-ing` words are fine as established names (`Logging`, `Troubleshooting`, `Packaging`) and as
modifiers inside a fixed term (`polling interval`, `logging framework`, `caching layer`).

---

### S5 — Do not omit words to save space

*Adapted from STE rules 4.2, 4.5, GR-1.*

A shorter sentence is not automatically a clearer one. Dropped articles, dropped subjects,
dropped verbs, and contractions all cost the reader more than they save.

```
DON'T  Can be a maximum of five inches long.
DO     A crack can have a maximum length of five inches.

DON'T  Rotary switch to INPUT.
DO     Set the rotary switch to INPUT.

DON'T  If installed, remove the shims.
DO     If the shims are installed, remove them.

DON'T  Remove the bolt and stop.               ← "and stop" — a part, or a command?
DO     Remove the bolt and the stop.

DON'T  If your hands are wet, don't touch the adapter.
DO     If your hands are wet, do not touch the adapter.
```

Keep the conjunction **"that"**. Native speakers drop it in speech; in writing it marks
exactly where the main clause ends and stops the reader from re-parsing.

```
DON'T  Make sure the valve is open.
DO     Make sure that the valve is open.

DON'T  The dashboard shows the queue is empty.
DO     The dashboard shows that the queue is empty.
```

Use an article or a demonstrative before a noun where English calls for one — but not in
general statements (`Solvents can cause damage to paint.`), not before an abstract quality
(`This release increases performance.`), and not before a proper noun with an identifier
(`Tag circuit breaker 36L7`, not `the circuit breaker 36L7`).

In a series, the article placement carries meaning. Use it deliberately.

```
Install the new O-rings, spacers, nuts, and pins.            ← everything is new
Install the new O-rings, the spacers, the nuts, and the pins. ← only the O-rings are new
```

---

### S6 — Condition first, then the action

*Adapted from STE rule 5.4.*

If the reader must know a condition before they act, give the condition first and separate it
with a comma. Otherwise they start the action and learn too late that it did not apply.

```
DON'T  Set the switch to NORMAL when the light comes on.
DO     When the light comes on, set the switch to NORMAL.

DON'T  Apply the primer when the surface is dry.
DO     When the surface is dry, apply the primer.

DON'T  Restart the service if the health check fails three times.
DO     If the health check fails three times, restart the service.
```

Place the comma with care — it decides which verb an adverb modifies.

```
If the drive does not operate correctly, disconnect it.   ← "correctly" describes "operate"
If the drive does not operate, correctly disconnect it.   ← "correctly" describes "disconnect"
```

---

### S7 — Replace an ambiguous pronoun with its noun

*Adapted from STE GR-3, GR-4.*

If `it`, `they`, `this`, or `that` could point at more than one thing, the sentence is
ambiguous. Repeating the noun is never a style error.

```
DON'T  If you insert the pins into the sockets incorrectly, they can be damaged.
DO     If you insert the pins into the sockets incorrectly, the pins can be damaged.
DO     If you insert the pins into the sockets incorrectly, the pins and the sockets
       can be damaged.
```

`this` at the start of a sentence, pointing back at a whole previous clause, is the worst
offender. Name what `this` refers to.

```
DON'T  Make sure that the cover is not locked (this can cause damage to the probe).
       ← which state damages the probe: locked, or unlocked?
DO     Make sure that the cover is not locked. If the cover is locked, damage to the
       probe can occur.

DON'T  Do not run the migration on a replica. If you do this, you can corrupt the index.
DO     Do not run the migration on a replica. A migration on a replica corrupts the index.
```

---

## Structure

### P1 — Give information gradually

*Adapted from STE rule 6.1.*

Introduce one fact, then build on it. Do not open with a sentence that assumes four things the
reader has not been told yet.

```
DON'T  During the approach, deviation pointers in the course indicators give commands to
       fly up or down and left or right, information which comes from the VHF
       transceivers that form part of the Instrument Landing System.

DO     The Instrument Landing System (the system) shows data that helps the pilot during
       the approach to the runway. This system shows the pilot the deviations from the
       localizer course and the glideslope path. The localizer course aligns with the
       centerline of the runway. And the glideslope path is at a constant angle to the
       threshold of the runway.
```

Each sentence in the second version adds exactly one new thing, and each starts from something
the previous sentence established.

---

### P2 — One topic per paragraph, topic sentence first

*Adapted from STE rules 6.4, 6.5.*

The first sentence of a paragraph states the topic. The sentences after it explain that topic
and nothing else. A new topic means a new paragraph.

The test: **copy out the first sentence of every paragraph. Do they form a usable outline of
the document?** If they do, the structure is sound. If they do not, the topics are in the
wrong places.

---

### P3 — Six sentences maximum per paragraph

*Adapted from STE rule 6.6.*

Past six sentences a paragraph stops being a unit and becomes a wall. Split it — the split
point is almost always where a second topic sneaked in.

---

### P4 — Repeat key words instead of varying them

*Adapted from STE rule 6.2.*

Sentences connect when a later sentence picks up a word from an earlier one. This is the main
mechanism that makes a paragraph feel like one thought instead of five. Changing the word
breaks the chain — the reader stops to check whether you now mean something else.

```
Sentence 1  The Instrument Landing System shows data that helps the pilot during the
            approach to the runway.
Sentence 2  This system shows the pilot the deviations from the localizer course.
            ↑ picks up "system", "shows", "pilot" — connected, and adds one new fact
```

This is W1 (one word, one meaning) applied at paragraph scale. Consistency beats variety.

---

### P5 — Turn complex sentences into vertical lists

*Adapted from STE rule 4.3.*

When a sentence carries several items or several actions, make it a list. Lists are the
single highest-leverage change available for dense text.

```
DON'T  The wheel assembly comprises the tire, the tube, the spokes, the spoke fittings,
       the valve, and the hub.
DO     The wheel assembly has these parts:
       - The tire
       - The tube
       - The spokes
       - The spoke fittings
       - The valve
       - The hub.
```

Rules for a clean list:

- End the lead-in sentence with a colon.
- Start each item with a capital letter.
- Use an article before the noun in each item, where English calls for one.
- Put a period at the end of an item only if the item is a full sentence.
- Put a period at the end of the **last** item, always.
- Never end an item with a comma or a semicolon.
- Do not mix instructions and description in one list.
- Keep all items at the same level. If an item needs sub-items, either flatten them or fold
  them into the parent item in parentheses.
- Make every item read correctly against the lead-in text.

```
DON'T  Do not use acetone for cleaning these parts after the repair:
       - the service cabinet,
       - the toilet shrouds with the supports,
       - parts made of polycarbonate.
DO     After the repair, do not use acetone to clean:
       - The service cabinet
       - The toilet shrouds
       - The toilet shroud supports
       - Parts made of polycarbonate.
```

In a list of prohibitions, repeat the negative on every item. A single `DO NOT` in the lead-in
gets lost when the reader skims.

```
DON'T  When you open the access panel, do not:
       - Put your feet on the fuel line.
       - Use the fuel line as a handle.
DO     When you open the access panel:
       - DO NOT put your feet on the fuel line.
       - DO NOT use the fuel line as a handle.
```

---

### P6 — Connect related sentences with connecting words

*Adapted from STE rules 4.4, 6.2.*

Connecting words are traffic signs. They tell the reader whether what comes next is more of
the same, a contrast, or a consequence: `and`, `but`, `then`, `thus`, `as a result`, `at the
same time`.

```
These precautions are the minimum for work in this area. But local regulations can
require more.

If the pressure increases, the current in the transmitter changes. Thus, the power unit
supplies current to the indicator.
```

Starting a sentence with `And` or `But` is correct and often clearer than welding two clauses
together. Use it.

---

## Instructions

### I1 — Write instructions in the imperative

*Adapted from STE rule 5.3.*

An instruction tells the reader to do something. Any other construction makes them guess
whether the step is required, whether someone else already did it, or whether someone else
will do it later.

```
DON'T  The test can be continued.
DO     Continue the test.

DON'T  Oil and grease are to be removed with a degreasing agent.
DO     Remove the oil and the grease with a degreasing agent.

DON'T  The user should then click Submit.
DO     Click Submit.
```

Do not put `must` in front of an imperative — it adds nothing. Reserve `must` for a genuine
safety point or a hard condition.

```
DON'T  Before you remove the clamp, you must disconnect the hose.
DO     Before you remove the clamp, disconnect the hose.
DO     WARNING: IF YOU MUST CUT THE WIRE, PUT ON A PROTECTIVE MASK.
```

---

### I2 — One instruction per step

*Adapted from STE rule 5.2.*

One action, one numbered step. Use as many steps as you need — steps are free, confusion is
not.

```
DON'T  Set the TEST switch to the middle position and release the SHORT-CIRCUIT switch.
DO     A. Set the TEST switch to the middle position.
       B. Release the SHORT-CIRCUIT switch.
```

Two exceptions, both narrow:

1. **The actions happen at the same time.** `Hold the panel open and install the fastener.`
   `Cut and remove the wire.` `Remove and discard the seal.`
2. **A result follows the action immediately.** `Measure the leakage from the outlet port. The
   leakage must not be more than 0.5 cc/minute.`

---

### I3 — Notes inform; they never instruct

*Adapted from STE rule 5.5.*

A note gives helpful information. The moment a note contains an instruction, a requirement, or
a limit, the reader who skips notes — and readers do skip notes — misses something they
needed.

```
DON'T  NOTE: Make sure that the ventilation system continues to operate.
DO     6. Make sure that the ventilation system continues to operate.   ← it is a step

DON'T  NOTE: When you connect the lines, do not bend them. Bending damages the lines.
DO     CAUTION: WHEN YOU CONNECT THE LINES, DO NOT BEND THEM. IF YOU BEND THE LINES,
       YOU CAN CAUSE DAMAGE TO THEM.                                   ← it is a warning

DO     NOTE: The gyroscope becomes stable after about 15 seconds.       ← genuinely a note
DO     NOTE: You can use equivalent alternatives for these items.
```

**The test for a procedure that has notes:** delete every note and read the procedure. Can the
reader still complete it correctly? If not, the missing content was never a note — promote it
to a step or a warning.

Notes get 25 words per sentence, not 20, because they are description rather than instruction.
Never use the imperative in a note.

---

### I4 — Give limits and results with the step, not after it

*Adapted from STE rule 5.5.*

A tolerance, a limit, or an expected result belongs in the step that produces it.

```
DON'T  B. Measure the leakage from the outlet port.
          NOTE: The leakage must not be more than 0.5 cc/minute.
DO     B. Measure the leakage from the outlet port. The leakage must not be more than
          0.5 cc/minute.
```

---

## Risk and consequence

Aerospace uses a fixed taxonomy: a **warning** means risk of injury or death; a **caution**
means risk of damage to objects. Your domain may use different words. Keep the structure,
whatever you call it.

### R1 — Warn before the action, not after

*Adapted from STE rules 7.1, 7.2.*

The warning comes before the step it applies to, and it opens with the command or the
condition — not with the explanation. A reader who acts on the first line must already be safe.

```
DON'T  Delete the temp directory. Note that deleting it while a job runs corrupts state.
DO     Before you delete the temp directory, stop all running jobs. If a job is running,
       deletion corrupts the state file.
```

When two levels of risk apply at the same time, use the higher one.

---

### R2 — Name the risk and the consequence in concrete words

*Adapted from STE rule 7.3.*

Say what goes wrong and what it costs. An abstract warning changes nobody's behavior.

```
DON'T  CAUTION: EXTREME CLEANLINESS OF OXYGEN TUBES IS IMPERATIVE.
DO     WARNING: MAKE SURE THAT THE OXYGEN TUBES ARE FULLY CLEAN. OXYGEN AND GREASE MAKE
       AN EXPLOSIVE MIXTURE. AN EXPLOSION CAN CAUSE INJURY OR DEATH.

DON'T  Be careful with the migration script.
DO     Run the migration script on a backup first. The script rewrites every row, and
       you cannot undo the change.
```

The pattern is: **[condition or command] + [what happens if you ignore it]**.

---

## Punctuation

### X1 — No semicolons

*Adapted from STE rule 8.1.*

The semicolon exists to join two sentences that should have stayed apart, and few people place
it correctly. Write two sentences.

```
DON'T  Examine the removed parts; replace the damaged ones.
DO     Examine the removed parts for damage. Replace the damaged parts.

DON'T  The battery is not user-replaceable; only an approved service center can replace it.
DO     Users cannot replace the battery. Only an approved service center can replace it.
```

### X2 — Hyphenate words that act as one unit

*Adapted from STE rules 8.2, 8.7.*

A hyphen tells the reader which words belong together, and it collapses a word stack into one
countable word. Hyphenate:

- Multi-word adjectives before a noun — `low-latency path`, `read-only replica`,
  `high-pressure chamber`, `up-to-date information`, `trial-and-error method`
- Two-word numbers and fractions — `forty-seven`, `three-sixteenths`
- A letter or number plus a noun that gives a shape — `O-ring`, `L-shaped bracket`,
  `3-prong connector`
- Verbs built on a noun — `heat-treat`, `short-circuit`, `dry-clean`
- A prefix ending in a vowel before a root starting with a vowel — `pre-amplifier`,
  `de-icing`, `anti-icing`

A hyphen is not a dash. A dash separates ideas or shows a range; a hyphen binds words.

### X3 — Use parentheses for identifiers and asides only

*Adapted from STE rule 8.3.*

Legitimate uses: a cross-reference (`refer to section 4`), an item identifier (`the valve
(10)`), a step number, an abbreviation on first use, singular-and-plural at once (`the
test(s)`), a short explanation, or an alternative (`the left (right) panel`).

Parenthetical text still counts as its own sentence for the length limit, and it counts as one
word in the sentence that holds it. If your aside needs more than about ten words, it is a
sentence — write it as one.

---

## Consistency

### C1 — Same action, same wording, every time

*Adapted from STE rule 9.4.*

In a procedure you describe the same kind of action repeatedly. Choose one phrasing and reuse
it exactly. The reader learns the shape of the sentence and stops reading it word by word.
Varying the phrasing forces a fresh parse every time and implies a difference that is not
there.

```
DON'T  2. Lubricate the two bolts (10) with oil.
       ...
       6. Apply a small quantity of oil to the threads of the four bolts (12).

DO     2. Apply a small quantity of oil to the threads of the two bolts (10).
       ...
       6. Apply a small quantity of oil to the threads of the four bolts (12).
```

This covers three things at once: the same name for the same item, the same verb for the same
action, and the same sentence shape for the same kind of step.

### C2 — Use neutral, non-gendered language

*Adapted from STE GR-7, GR-8.*

Use gender-neutral terms and constructions throughout. Where a person's pronouns are not
known, use `they`. Prefer the role (`the operator`, `the reviewer`, `the on-call engineer`) or
address the reader as `you`.

The possessive with `'s` is allowed but is a frequent error and does not exist in many
languages. When you are not certain it is correct, rewrite: `the manufacturer's instructions`
→ `the instructions from the manufacturer`.

---

## Revision pass

Run these in order on any text that must be understood. Each check is cheap; the order puts
the highest-value fixes first.

1. **Structure** — Does each paragraph have one topic, with the topic in its first sentence?
   Do the first sentences form an outline? (P1, P2, P3)
2. **Lists** — Is any sentence carrying three or more items or actions? Make it a list. (P5)
3. **Length** — Any sentence over 20 words in an instruction, or 25 in description? Split it.
   (S2)
4. **Voice** — Search for `is`, `are`, `was`, `were`, `be`, `been` followed by a past
   participle. Rewrite each in the active voice, unless the agent is genuinely unknown. (S3)
5. **Imperative** — Is every instruction a command? Delete `should`, `must` before commands,
   and `the user then`. (I1)
6. **One action per step** — Split any step with `and` joining two separate actions. (I2)
7. **Conditions** — Does any instruction put the condition after the action? Move it to the
   front and add the comma. (S6)
8. **Pronouns** — For every `it`, `they`, `this`, `that`: can it point at more than one noun?
   Replace it with the noun. (S7)
9. **Terminology** — List every term for every important thing. One term each, no synonyms,
   no term reused for two things. (W1, C1)
10. **Nominalizations** — Search for `-tion`, `-ment`, `-ance`, `-ing of`. Turn each back into
    a verb. (W4)
11. **Word choice** — Replace inflated words with plain ones, jargon with the real term, and
    phrasal verbs with single verbs. (W2, W3, W5)
12. **Noun stacks** — Any run of four or more nouns and adjectives? Break it with a
    preposition or hyphenate the unit. (W7)
13. **Omissions** — Restore dropped `that`, dropped articles, dropped subjects. Expand
    contractions. (S5)
14. **Punctuation** — Delete every semicolon. Delete every `e.g.`, `i.e.`, `etc.` (X1, W6)
15. **Notes and warnings** — Delete all notes and re-read. Still complete? If not, promote the
    content to a step or a warning. Does every warning name the risk and the consequence?
    (I3, R1, R2)

---

## What this skill deliberately does not adopt

ASD-STE100 is a controlled language for aerospace maintenance documentation. Three parts of it
are excluded here, on purpose:

- **The controlled dictionary.** STE approves exactly 875 words and rejects 1274 named
  alternatives — "acceptable" is banned in favor of "permitted", "check" as a verb is banned
  in favor of "do a check". That is right for a manual read by technicians in forty countries
  under regulatory audit, and wrong for general writing. W2 keeps the principle (prefer the
  plain word) and drops the closed word list.
- **The technical noun and technical verb categories.** Twenty-two noun categories and four
  verb categories, with rules about which of them may act as which part of speech. This
  machinery exists to police an aerospace terminology database. Rule W1 keeps what matters:
  one term per thing, used consistently.
- **The aerospace safety taxonomy and formatting.** Uppercase warnings, the strict
  warning/caution split, references to ISO 45001 and ANSI Z535. R1 and R2 keep the structure
  (warn first, name the consequence) and let your domain choose its own labels.

Everything else in Part 1 of the standard — sections 2 through 9 — transfers to general
writing almost unchanged, and is here.

---

## When not to apply this

These rules optimize for one thing: a reader understanding a sentence on first pass, under
time pressure, possibly in a second language. That is the right goal for documentation,
instructions, specs, runbooks, incident reports, PRs, tickets, agent instructions, and most
professional messages.

It is the wrong goal for writing whose job is to persuade, to entertain, or to sound like a
specific person. Do not apply this skill to:

- Marketing copy, narrative, fiction, or anything where rhythm and voice carry the meaning
- Someone's personal writing that they did not ask you to flatten
- Text where a nuance genuinely needs a long sentence — say it in one long clear sentence
  rather than three that lose the connection between the parts

And do not apply the numeric limits so hard that you produce a wall of choppy 8-word
sentences. Short is a means. Clear is the end.

---

## Source

ASD-STE100 Simplified Technical English, Issue 9 (2025-01-15), Part 1 — Writing rules.
Published by the AeroSpace and Defence Industries Association of Europe (ASD), Brussels.
Free for non-commercial use from [asd-ste100.org](https://www.asd-ste100.org).

Rule numbers cited throughout (`STE rule 5.4`, `GR-3`) refer to that document, so any rule here
can be traced back to its source.
