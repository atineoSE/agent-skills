---
name: educational-piece
description: Turns a dense source document (a research map, article, report, or paper) into a spoken narration script for a single narrator. Use when the user wants a document turned into something meant to be read aloud — a podcast-style explainer, a voiced summary, an audio piece — not when they want written prose, a blog post, slides, or bullet notes. Produces a script file only; it does not generate audio.
version: 1.6.0
---

# Educational piece: narration scripts

This skill turns a dense source document into a script a single narrator can
read aloud. It writes the script and stops, and it never produces audio.
Narration costs money once it becomes audio, and a script is faster to check
by eye than a finished recording is to check by ear. Reading, editing, and
narrating are the human's job.

## Procedure

1. **Read the source document** the user names. This comes first. You cannot
   propose what the piece should be about — and the user cannot judge your
   proposal — until one of you knows what is actually in the material.

2. **Propose the frame, and wait for a yes.** In one short message, propose
   three things:
   - **Who the piece is for**, and what they already know going in.
   - **The single question the piece exists to answer**, written in that
     audience's own terms. One question, not a topic and not a list.
   - **Whether it fits in one piece.** If answering that question well needs
     more than one sitting, say so and propose numbered episodes on a common
     thread instead of compressing.

   Name what you are cutting, in a clause — and mean it, because an idea you
   decided not to take is one the script must never open in passing (see
   `Loops`). Arrive with a proposal, not a
   questionnaire — you have read the source and the user has not, so choosing
   is your job and confirming is theirs. Do not start writing until they
   agree or adjust.

3. **Before writing, read `reference/worked-example.md`** in this skill's
   directory. It shows one source paragraph and the spoken opening and
   section it became, with notes on which move serves which part of the
   framework below. Also skim `reference/examples.md` for concrete
   before/after fixes from past runs — treat it as a running style guide, not
   required reading in full.

4. **Write a single-narrator spoken script** — one voice, not a
   conversation or a two-host dialogue — to a file next to the source, named
   `<source-stem>-script.txt`. When the piece became episodes, write one file
   per episode: `<source-stem>-script-01.txt`, `-02.txt`, and so on. The
   extension is `.txt` and not `.md` on purpose — the file must contain no
   markdown, and a narration tool speaks its bytes verbatim, so an `.md` name
   invites headings and bullets into a file where they would be read aloud.
   Use the writing spine and constraints below.

5. **Revise the draft against the `simple-English` skill**, whose rules this
   skill assumes rather than restates. Run its revision pass over the script,
   and give particular weight to its "Avoiding AI-writing tells" section —
   see `Sounding like a person` below for why that section matters more here
   than in written prose.

6. **Stop, and settle the narration cost before anyone spends.** Tell the
   user the path to the script, and that the next steps are theirs: read it,
   edit it, then narrate it themselves. Do not generate audio as part of this
   skill.

   Narration is usually priced per character, and a finished piece is tens of
   thousands of characters. So check what the narration tool currently costs
   rather than assuming — free tiers carry expiry dates, and a model that was
   free last month may not be this month. Where a free or already-paid-for
   voice is available and good enough, say which one and why. Where narrating
   would cost money, say what it will cost and ask which model to use. Never
   pick the model on the user's behalf, and never let a first run be the way
   they find out there was a bill.

## The writing spine: RENT

Four things a script needs, all at once, not in sequence. Check every
paragraph against all four, not just the opening.

- **Relatability.** The named audience has to see itself in the piece within
  the first few sentences. Open in *their* world — a question they've asked,
  a situation they recognize — not in the source document's world (its
  authors, its dataset, its abstract). If the audience wouldn't say "that's
  me" or "that's my problem" in the first breath, rewrite the opening.

- **Ease.** No jargon the audience doesn't already use going in — if the
  source uses a term of art, either replace it or earn it with a plain-language
  explanation before leaning on it. The hook has to land in the first three
  seconds, not after throat-clearing or a preamble about what the piece is
  about. Order matters: give the listener each fact only once they have what
  they need to make sense of it, never before.

- **Novelty.** Lead with what's surprising, contested, or counterintuitive —
  not with the settled, textbook framing. A source document's own structure
  (background, then findings, then caveats) is usually the wrong order for a
  listener; find the twist and open there instead.

- **Tension.** Name the gap between what the audience currently believes and
  what the evidence actually shows, and keep that gap open. Don't resolve it
  once in the introduction and coast — reopen it at each section so a
  listener has a reason to keep listening. The largest of these gaps is the
  piece's own question, and `The one question` below governs how it opens and
  closes.

## The one question

RENT is a paragraph-level check. This is the structural one, and it is what
stops a script becoming a competent tour of its source.

A piece answers exactly **one** question — the one agreed at step 2 — and
everything in it either moves toward that answer or is cut. A source document
usually contains five or ten interesting ideas. Narrating all of them means
two minutes each, which is not enough time for any of them to land, and the
listener finishes having half-heard several things instead of understanding
one. When the material genuinely carries more than one question, that is what
episodes are for.

**The hook opens the question the ending answers.** The opening may start
somewhere warmer than the question itself — the listener's own world, personal
and concrete — but it has to arrive at the piece's actual question inside the
first minute, and it must be *that* question. An on-ramp is fine. Advertising
one question and answering a different one is not: the listener spends the
piece waiting for a loop that never closes. A script that opens on personal
willpower and ends on how institutions are designed has made this mistake,
however good both halves are.

**The ending answers it in one sentence.** Close with a single plain sentence
that answers the question, phrased so a listener could repeat it to someone
the next day. Anything reflective — a callback, a wider implication, a
question to leave them with — comes *after* that sentence, never instead of
it. Ending on a fresh question feels elegant and leaves the listener holding
nothing.

**Answer without taking sides.** The closing sentence says what the evidence
supports, not what the listener should do. Where the research is genuinely
contested, the answer says so and names the disagreement rather than quietly
picking a winner. Honest and useful are compatible; honest and preachy are not.

**Give the payoff room.** The answer to a good question is often a list —
features, conditions, principles. Do not narrate the list. Pick the **three**
items that actually carry the answer, give each one a real example with time
to land, and say the rest exist without enumerating them. A listener leaves
with three; nobody leaves with eight, however slowly they are read. The
enumerated version also opens a loop per item and closes none — see `Loops`. Every
example must be grounded in the source document — if the source cannot support
an example for one of your three, drop that item and pick another rather than
inventing material to fill it.

The failure this prevents is specific and easy to miss on the page: the piece
spends fifteen minutes building toward something, then delivers it in forty
seconds as a run of one-line assertions. Read it back and it looks complete.
Heard once, at speaking speed, it is gone.

## Loops

A loop is any question the script opens in the listener's mind. The piece's
own question is the largest one. Every other one you open is a promise, and a
listener hears an unkept promise as unease rather than as a loose end they
have chosen to forgive.

**Never more than two loops open at once.** The piece's question is always one
of them. That leaves room for exactly one other at any moment. A listener
holding three unanswered questions stops following the argument and starts
waiting for you to catch up.

**Never open a loop in passing.** This is the failure that survives every
other check, because on the page it reads as a single harmless clause. A
sentence saying that a good used car "gets taken off the market" opens three
questions at once — why would the owner do that, where does the car go, what
happens to it — and then moves on. The listener is still holding those when
the next paragraph starts. Either answer it where it stands, or write the
sentence so it never gets asked.

**A list longer than three items opens a loop per item.** Naming six things
that rebuild trust in a market, or four other factors researchers have
studied, promises six or four explanations and delivers none. Cut to two or
three and give each one a real example, or say plainly that more exist and
that you are leaving them alone. Declining out loud closes the loop; trailing
off leaves it open.

**Decide each loop at step 2, not while drafting.** When you propose the
frame, every large idea in the source gets sorted into one of three piles: it
is the piece's question; it is a supporting loop this piece will open and
close; or it is not taken at all, and the writing must then be careful never
to open it. An idea that deserves its own loop but cannot be closed here is
the signal for a separate episode. Naming the third pile is as much a part of
the proposal as naming the question, and it is what the "what I am cutting"
clause is actually for.

The check: read the script and mark every place a listener could reasonably
ask "wait, why?" or "what happened to that?". Each mark is a loop. If one is
not answered within a paragraph or two, or explicitly declined, fix it.

## Pacing and pauses

A piece read at one unbroken speed exhausts a listener, however good the
sentences are. The script has to build in the silence where the listener
needs a moment to absorb what was just said.

Ask the narration tool what it supports before drafting, and use the longest
pause it offers where the listener has something to digest — not merely where
the script changes subject. A number that reframes the argument, a reveal,
the sentence before the payoff, and the closing answer all earn one. Roughly
ten to twelve long pauses in a fifteen-minute piece is right; ordinary
paragraph breaks already carry a beat of their own, and making everything a
long pause is the same as making nothing one.

Where a tool offers no pause control at all, sentence length and paragraph
breaks are the only pacing left, and the script has to carry the rhythm in
its own prose. Do not reach for ellipses, dashes or stage directions to buy a
pause: whether those do anything is a property of the specific speech model,
and assuming they work produces a script whose pacing silently disappears.

## Opening and closing the piece

Every script opens with its own title and part number as the first paragraph,
spoken plainly and followed by the longest pause in the piece: `When
Bargaining Power Concentrates. Part one. Why the person who can walk away
wins.` A listener arriving mid-feed has to know what this is and where it
sits in a series.

Every script ends with a one-line sign-off after the reflective close: `That
was part one of When Bargaining Power Concentrates.`

The spoken title and sign-off are the script's own job, and they have to work
on their own. Where the narration tool also marks the boundaries with an
audio cue, that cue is a bonus on top of the words, never a substitute for
them.

## Constraints on the script

Assume the narration tool speaks the file verbatim, with no editorial pass of
its own. Anything on the page is something the listener hears.

- **English only.**
- **No expression tags, no SSML, no bracketed stage directions.** A speech
  model either strips markup it recognizes or reads it out as text, and which
  one you get is a property of that model. Either way the script loses:
  the instruction vanishes silently, or the listener hears "open bracket
  excited". There is no delivery channel outside the words themselves, so
  emphasis and tone have to come from sentence length and punctuation.
- **No markdown headings, bullets, tables, or link syntax** in the script
  body. A `#` or a `-` list marker would be spoken text, not formatting.
  Write it as plain paragraphs.
- **Spell out anything that doesn't read aloud cleanly.** Numerals ("552"
  becomes "five hundred fifty-two"), symbols, abbreviations, and citation
  parentheticals ("(Shoda, Mischel & Peake 1990)") either become spoken
  phrases ("a nineteen-ninety study by Shoda, Mischel, and Peake") or get
  cut if they don't earn their place spoken aloud.

## Sounding like a person

A narrator says these words in a human voice, so a sentence that reads as
machine-written on the page is far more obvious out loud.

The `simple-English` skill's "Avoiding AI-writing tells" section holds the
rules, including its banned constructions and its banned-words table, and it
is the only place they live. Read it before drafting, and add anything new to
that section. Two of its entries cost more spoken
than written. The negate-then-correct pair becomes the script's default
rhythm, and a listener hearing the same see-saw four times in twenty minutes
stops trusting the narrator. Stacked sentence fragments, which merely look
punchy on the page, come out of a narrator's mouth sounding like advertising.

Also cut asides that only tell the listener how to react — "sit with that for
a second," "read that again," "let that sink in." An aside that announces
real content is fine and often good ("here's what usually gets left out");
an aside that stands in for the content is not.

The check: read a paragraph aloud. If two sentences in a row have the same
shape, one of them is doing rhythm instead of work.

## Varying the shape

The same check applies one level up. A paragraph can be delivered in more than
one shape, and a script that uses one shape throughout drones however clear the
individual sentences are. Naming the shapes is what makes it possible to ask for
a different one.

- **Ladder** — step, step, step, then an abstract label, then a gloss of the
  label. This is what a draft falls into on its own, so it is the one to watch
  for.
- **Scene-first** — the picturable thing first, the pattern named after it.
- **Investigator** — the researchers are the subject: they went looking, and
  they found.
- **Verdict-first** — the conclusion in the opening line, in the plainest words
  available, with the evidence behind it.
- **Chronicle** — a sequence of events in time, with no summary sentence at all.

None of these is better than the others, and none of them is a rule about
sentences. Pick one per section, and do not use the same one in two sections
running.

Attribution has shapes too, and it defaults just as hard. "David Autor and his
co-authors documented what they call superstar firms." "What happened next got
named by the economists Claudia Goldin and Robert Margo. They called it the
Great Compression." "Joan Robinson gave a name to the situation. She called it
monopsony." That is one two-step used three times in a single script:
researchers named a thing, here is the name, always as its own sentence, always
before any content arrives. Keep the attribution, because it matters in a piece
that cites this much, and vary how it attaches. It can ride inside the sentence
that carries the content: "A few very productive companies, which Autor and his
co-authors call superstar firms, now take most of the sales."

## Keep this skill current

This skill improves by editing itself, not by accumulating exceptions.

- **Bump `version:`** in this file's frontmatter whenever you change it:
  patch (e.g. `1.0.1`) for a wording tweak, minor (e.g. `1.1.0`) for a new or
  materially changed rule.
- **Prefer replacing a rule over adding to it.** If a new instruction
  contradicts or refines an old one, edit the old one in place rather than
  appending a caveat.
- **Update after any of these:**
  - the user rewrote part of a handed-over script by hand — treat their edit
    as a correction and add the before/after pair to `reference/examples.md`
    (see that file's own instructions for the format and the twelve-entry
    cap);
  - a piece didn't hold attention, or the user said so;
  - the audience question landed badly (confusing, too broad, answered with
    "I don't know");
  - a phrasing or structural move worked notably well and is worth
    repeating on purpose next time.

## Changelog

- **1.6.0** — Added `Varying the shape`: five named shapes a paragraph can be
  delivered in (Ladder, Scene-first, Investigator, Verdict-first, Chronicle),
  one per section and never twice running, plus the same rule for attribution,
  which defaults to "<researchers> named a thing, here is the name" and repeats
  across a whole script.

- **1.5.0** — Step 6 now settles narration cost before anyone spends: check
  what the tool currently charges rather than assuming, prefer a free or
  already-paid-for voice where one is good enough, and ask which model to use
  when narrating would cost money.

- **1.4.0** — Decoupled the skill from any particular narration tool. Pacing,
  boundary cues and the markup constraints are now stated as craft rules that
  ask what the tool supports, rather than as descriptions of one speech
  model's behaviour. The tool that does the narrating documents its own
  capabilities.

- **1.3.1** — `Sounding like a person` now points at the `simple-English`
  tells section instead of restating two of its rules, so the banned lists
  have one home and cannot drift apart.

- **1.3.0** — Added `Loops`: at most two open at once, never one opened in
  passing, lists over three items open a loop per item, and every large idea
  gets sorted at step 2 into the question, a loop this piece closes, or a pile
  the script must not touch. Added `Pacing and pauses` (blank lines are the
  only reliable pacing control) and `Opening and closing the piece` (spoken
  title and part number, one-line sign-off).

- **1.2.0** — Reordered the procedure to read the source *before* asking
  anything, and replaced the audience question with a frame proposal the user
  confirms: audience, the single question the piece answers, and whether the
  material needs episodes. Added `The one question` — hook and ending as one
  loop, a one-sentence answer that doesn't take sides, and the rule that a
  list-shaped payoff is cut to three grounded examples. Script files are now
  `<stem>-script.txt`, numbered per episode.
- **1.1.0** — Added a `simple-English` revision pass to the procedure and a
  `Sounding like a person` section banning the antithesis pair and fragment
  lists.
- **1.0.0** — Initial version.
