---
name: openhands-events
description: Extract and analyze key information from OpenHands conversation event JSON files. Use when inspecting, debugging, or summarizing agent conversations stored in the conversations/ directory.
triggers:
- openhands events
- conversation event
- activated_skills
- analyze conversation
---

# Event Analysis

Guide for extracting key information from OpenHands conversation event JSON files stored under `conversations/<conversation_id>/events/`.

## Event Kinds

Every event has a `kind` field. There are four kinds:

| `kind` | `source` | Description |
|--------|----------|-------------|
| `SystemPromptEvent` | `agent` | Always event-00000. Contains system prompt, tools, and available skills listing. |
| `MessageEvent` | `user` or `agent` | A text message. User messages may carry skill activations. Agent messages are responses. |
| `ActionEvent` | `agent` | A tool call (bash command, file edit, etc). Paired with an ObservationEvent. |
| `ObservationEvent` | `environment` | Result of an action. Linked back via `action_id` and `tool_call_id`. |

## Common Top-Level Fields

All events share:
- `id` (UUID) -- unique event identifier
- `timestamp` (ISO 8601)
- `source` -- `"user"`, `"agent"`, or `"environment"`
- `kind` -- event type discriminator

## Extracting Skill Activation

Skill activation data lives on **user `MessageEvent`** events only.

### Key fields

- **`activated_skills`**: Array of skill name strings triggered by keyword matching against the user's message. Empty `[]` means no skills fired.
- **`extended_content`**: Array of injected content blocks from activated skills. Each block contains the skill's SKILL.md guidance text wrapped in `<EXTRA_INFO>` tags.

### How to check

```python
import json, glob

events_dir = "conversations/<id>/events/"
for path in sorted(glob.glob(f"{events_dir}/*.json")):
    event = json.loads(open(path).read())
    if event.get("kind") == "MessageEvent" and event.get("source") == "user":
        skills = event.get("activated_skills", [])
        if skills:
            print(f"{path}: activated_skills = {skills}")
```

### How activation works

Skills define `triggers` keywords in their SKILL.md frontmatter. The system does **case-insensitive substring matching** of each trigger keyword against the full user message text. If `keyword.lower() in message.lower()`, the skill fires. This means:
- A trigger of `"git"` will match any message containing "git", "gitignore", "github", etc.
- Skills with no `triggers` field are listed in the system prompt but never appear in `activated_skills`.
- Once a skill fires in a conversation, it won't re-fire (tracked in state via `activated_knowledge_skills`).

### Agent MessageEvents

Agent-sourced `MessageEvent`s always have `activated_skills: []` and `extended_content: []`. They carry `llm_response_id` and `llm_message.role: "assistant"`.

## Extracting Actions and Observations

`ActionEvent` and `ObservationEvent` always appear in pairs.

### ActionEvent key fields

- **`thought`**: Array of text blocks with the agent's reasoning before acting.
- **`action`**: Object with the action details. Check `action.kind`:
  - `TerminalAction` -- has `command` (the bash command string), `is_input`, `reset`
  - `FileEditorAction` -- has `command` (`"view"`, `"create"`, `"str_replace"`), `path`, `file_text`, `old_str`, `new_str`
- **`tool_name`**: `"terminal"`, `"file_editor"`, etc.
- **`tool_call_id`**: Links to the corresponding ObservationEvent.
- **`security_risk`**: `"LOW"`, `"MEDIUM"`, or `"HIGH"`.
- **`summary`**: Brief human-readable description of the action.

### ObservationEvent key fields

- **`observation`**: Object with results. Check `observation.kind`:
  - `TerminalObservation` -- has `content`, `exit_code`, `is_error`, `timeout`, `metadata` (includes `working_dir`, `username`, `hostname`)
  - `FileEditorObservation` -- has `content`, `is_error`, `command`, `path`, `prev_exist`
- **`action_id`**: UUID of the ActionEvent this responds to.
- **`tool_call_id`**: Matches the action's `tool_call_id`.

## Extracting the System Prompt and Available Skills

From `SystemPromptEvent` (event-00000):

- **`system_prompt.text`**: The full agent system prompt.
- **`tools`**: Array of tool definitions with `action_type`, `description`, and `annotations` (hints like `readOnlyHint`, `destructiveHint`).
- **`dynamic_context.text`**: Contains the `<available_skills>` XML block listing every skill's name, description, and SKILL.md file path.

## Event Sequencing

Events follow a strict pattern per conversation turn:

```
SystemPromptEvent (agent)           -- event-00000 (once)
MessageEvent (user)                 -- new user turn, may have activated_skills
  ActionEvent (agent)               -- tool call
  ObservationEvent (environment)    -- tool result
  ActionEvent (agent)               -- another tool call
  ObservationEvent (environment)    -- another tool result
  ...                               -- repeats as needed
MessageEvent (agent)                -- final response to user
MessageEvent (user)                 -- next user turn
  ...
```

Action/Observation pairs are linked by `tool_call_id`. Multiple pairs can occur per turn as the agent chains tool calls.

## Quick Analysis Script

```python
import json, glob, os

def analyze_conversation(conv_dir):
    events_dir = os.path.join(conv_dir, "events")
    for path in sorted(glob.glob(f"{events_dir}/*.json")):
        event = json.loads(open(path).read())
        idx = os.path.basename(path).split("-")[1]  # event number
        kind = event["kind"]
        source = event["source"]

        if kind == "MessageEvent":
            role = event["llm_message"]["role"]
            text = event["llm_message"]["content"][0]["text"][:80]
            skills = event.get("activated_skills", [])
            skills_str = f"  skills={skills}" if skills else ""
            print(f"[{idx}] {kind} ({role}): {text}...{skills_str}")

        elif kind == "ActionEvent":
            action_kind = event["action"]["kind"]
            summary = event.get("summary", "")
            print(f"[{idx}] {kind} ({action_kind}): {summary}")

        elif kind == "ObservationEvent":
            obs_kind = event["observation"]["kind"]
            is_err = event["observation"].get("is_error", False)
            err_str = " [ERROR]" if is_err else ""
            print(f"[{idx}] {kind} ({obs_kind}){err_str}")

        elif kind == "SystemPromptEvent":
            print(f"[{idx}] {kind}: system prompt initialized")
```
