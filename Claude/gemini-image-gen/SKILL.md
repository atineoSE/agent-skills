---
name: gemini-image-gen
version: 1.0.0
description: Best practices for prompting Gemini image-generation models (the gemini-3.x-flash-image family, "Nano Banana") — how to reference multiple input images so the model knows which is which, lock character/object identity across a shot, structure a multi-image request, and avoid common drift or multi-panel failures. Use when writing, reviewing, or debugging a prompt that generates or edits images with a Gemini image model, especially any request carrying more than one reference image.
---

# Gemini image generation — prompting best practices

Sourced from Google's own prompting guidance ([Developers Blog](https://developers.googleblog.com/en/how-to-prompt-gemini-2-5-flash-image-generation-for-the-best-results/), [API docs](https://ai.google.dev/gemini-api/docs/image-generation)) plus clause wording adapted from a production pipeline that hardened it against specific, observed failure modes — each clause below says what it prevents, not just what it says.

## The one rule

**Describe the scene, don't list keywords.** These models understand narrative language; a coherent descriptive paragraph consistently beats a comma-separated tag list. Be hyper-specific rather than generic — "ornate elven plate armor, etched with silver leaf patterns, high collar, pauldrons shaped like falcon wings" gives real control; "fantasy armor" doesn't. Phrase constraints positively: "an empty, deserted street" works better than "no cars."

## Referencing multiple input images

- **Request order is images first, prompt text last.** Every reference image goes in before the text part, in the order you want them addressed.
- **Address images by position, in natural language**: "the first image," "the second image." This is Google's own documented pattern — their example prompt is literally *"Take the blue floral dress from the first image and let the woman from the second image wear it."* Combine position with a name/description for clarity: *"Reference image 1 shows George. Reference image 2 shows Rufus."*
- **Official per-call caps for `gemini-3.1-flash-image`: 14 reference images total, split as 10 "object" references + 4 "character" references.** Don't exceed 4 character references on this model — it's a documented, hard consistency limit, not a soft guideline.

## Locking identity across a shot

A minimal, production-validated clause set, in the order it should appear:

1. **Name every reference explicitly, position + identity together**: `Reference image 1 shows <Name>. Reference image 2 shows <Name>.` Don't rely on position alone or description alone — combine them.
2. **Cap the cast to what's referenced**: `Render only these referenced characters because the selected shot names them; never add another referenced character.` Prevents the model inventing an extra figure that wasn't attached.
3. **Separate identity from scale/composition**: `Reference images are close-up identity guides only, never size or composition guides. Preserve every size relationship stated in the selected scene exactly.` Needed because these models (and FLUX-family models even more so) will treat a close-up reference portrait as a *composition* hint if not told otherwise — observed failure: a thumb-sized companion character enlarged to head/torso scale because its reference image was itself a close-up.
4. **For a genuinely ground-truth reference** (a real photo, not an AI-drawn portrait) that must override conflicting text: say so explicitly, and use the word "OVERRIDES." *"The attached image is the ground truth for the characters shown in it and OVERRIDES any conflicting wording below."* Without that word, models tend to fall back to the text description and effectively ignore the attached image.

## Composition guardrails

- **One scene, one image**: `One single scene in one single image. Never panels, never a comic strip, never a sequence.` Without this, a model will sometimes render a 3-panel comic strip into a single illustration slot when the prompt describes an action with multiple beats.
- **Freeze one instant**: `Freeze one exact instant. Never combine an earlier action with its later result.` Prevents the model blending a "before" and "after" state into one composite image (e.g. a door shown both open and shut, or an object mid-transformation and finished at once).

## Handling drift across iterative edits

Treat generation as conversational for small adjustments ("make the lighting warmer") — that's the intended workflow and it holds consistency well for a few turns. But once a character's features visibly drift after repeated edits, don't keep patching the same thread: **restart a new conversation with a full, detailed re-description** of the character. Long threads accumulate small deviations that compound; a fresh start with a complete description resets to the intended identity.

## Worked example

Request: two reference images (hero portrait, companion portrait) attached in that order, then this text:

```
Reference image 1 shows Mira. Reference image 2 shows Pip. Render only these
referenced characters because the selected shot names them; never add another
referenced character. Keep their faces, hair, and outfits identical to their
respective references. Reference images are close-up identity guides only,
never size or composition guides. Preserve every size relationship stated in
the selected scene exactly.

One single scene in one single image. Never panels, never a comic strip, never
a sequence. Freeze one exact instant.

Mira crouches at the cave mouth, torch raised, as Pip peers around her leg at
the glowing crystals ahead. [... scene description continues ...]
```

## Sources

- [How to prompt Gemini 2.5 Flash Image Generation for the best results](https://developers.googleblog.com/en/how-to-prompt-gemini-2-5-flash-image-generation-for-the-best-results/) — Google Developers Blog
- [Gemini API: Image generation](https://ai.google.dev/gemini-api/docs/image-generation) — official API docs (reference caps, request structure)

## Changelog

- **1.0.0** (2026-08-10) — Initial version. Google guidance cross-checked against a production Gemini image pipeline's own clause library, which independently converged on the same position+name referencing pattern and had already set its per-call reference cap to match the documented 4-character limit.
