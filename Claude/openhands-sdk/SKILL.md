---
name: openhands-sdk
version: 1.1.0
description: How to configure LLM and Agent classes with the OpenHands SDK
---

# OpenHands Agent SDK Guide

How to use the OpenHands SDK (`openhands.sdk` + `openhands.tools`) to build an `LLM`,
run an `Agent`, define custom tools, get **structured output**, and **test without real
LLM calls**.

> Source-verified against `github.com/OpenHands/software-agent-sdk` (`main`, commit
> `ac0b663`, 2026-09-04). Earlier versions of this guide documented APIs that DO NOT
> EXIST — the following do **not** work and are corrected below:
> `agent.run("...")`, `agent.run_stream(...)`, `Tool(name=..., description=..., callable=fn)`,
> `get_default_tools` / `get_default_agent` / `register_default_tools`, `resolve_tool` as shown,
> and any `Agent(response_format=...)` / `output_type=` structured-output param.
>
> **Maintenance:** this SDK moves fast (new LLM fields, new tools, new Agent options land
> often). When you next have a local `software-agent-sdk` checkout open, or use/rely on an
> API documented here, diff the claims in this file against the current source before
> trusting them, and bump `version` + the commit/date above when you update it. Don't let
> this file silently go stale the way the pre-1.0.0 version did.

## Install

```bash
pip install -U openhands-sdk openhands-tools
```

Both are on PyPI and are **version-locked** (install/upgrade together in one command).
`openhands-sdk` gives the `openhands.sdk` namespace (LLM, Agent, Conversation, events, tool
base classes). `openhands-tools` gives concrete tools (`openhands.tools.*`).

---

## 1. LLM

```python
from openhands.sdk import LLM, Message, TextContent
from pydantic import SecretStr

llm = LLM(
    model="litellm_proxy/minimax-m2.7",          # any litellm model id
    api_key=SecretStr("..."),
    base_url="https://llm-proxy.app.all-hands.dev/",  # optional custom endpoint
    usage_id="agent",                            # label for metrics
)
```

Real fields (pydantic model, `openhands-sdk/openhands/sdk/llm/llm.py`): `model`, `api_key`
(`SecretStr`), `base_url`, `api_version`, `num_retries` (5), `timeout` (300), `temperature`,
`top_p`, `top_k`, `max_input_tokens`, `max_output_tokens`, `native_tool_calling` (True),
`reasoning_effort` (`"low"|"medium"|"high"|"xhigh"|"none"|None`), `drop_params` (**True**),
`modify_params`, `extra_headers`, `litellm_extra_body` (dict, forwarded to litellm),
`usage_id`, plus AWS fields. The SDK does NOT auto-read env vars — construct explicitly
(e.g. from `os.getenv`).

Newer fields worth knowing about: `api_mode` (`"auto"|"chat"|"responses"`, forces the
OpenAI Responses API path), `auth_type` (`"api_key"|"subscription"`) + `subscription_vendor`
for logging in with a vendor subscription instead of an API key (see
`examples/01_standalone_sdk/35_subscription_login.py`), `fallback_strategy` for
automatic model fallback on failure (`examples/01_standalone_sdk/39_llm_fallback.py`),
`seed`, `reasoning_summary`, `extended_thinking_budget`, `prompt_cache_retention`,
`model_canonical_name`, `capability_overrides`. The model has grown a lot of fields —
check `llm.py` for the current full list rather than assuming this doc is exhaustive.

### One-shot, non-agentic completion

`LLM.completion()` returns an **`LLMResponse`**, not a raw litellm response:

```python
resp = llm.completion(
    messages=[Message(role="user", content=[TextContent(text="Say hello in one word.")])]
)
msg = resp.message                  # an openhands.sdk Message
text = "".join(c.text for c in msg.content if isinstance(c, TextContent))
# resp also has: .metrics (MetricsSnapshot), .raw_response (litellm), .id
```

- **Messages are typed objects** (`Message` + `TextContent`/`ImageContent`), NOT plain dicts.
  `Message(role=..., content=[...])`, role ∈ `"user"|"system"|"assistant"|"tool"`.
- **Structured output via `response_format` is best-effort, not first-class.** `completion(**kwargs)`
  forwards unknown kwargs to litellm, so you *can* pass
  `response_format={"type":"json_schema","json_schema":{...}}` — but `drop_params=True`
  (default) makes litellm **silently drop** it for models that don't support it. For reliable
  structured output, use the custom-tool pattern in §4, not `response_format`.
- `completion()` raises `ValueError` if you ask it to return a stream; stream via `on_token=`.

### Build an LLM (or whole Agent) from `~/.openhands/agent_settings.json`

```python
import json
from openhands.sdk import LLM, OpenHandsAgentSettings

data = json.load(open("/path/to/agent_settings.json"))
llm = LLM.model_validate(data["llm"])               # just the model

settings = OpenHandsAgentSettings.model_validate(data)
agent = settings.create_agent()                     # full Agent (llm + tools + condenser)
```

---

## 2. Agent + Conversation

```python
import os
from openhands.sdk import LLM, Agent, Conversation, Tool
from openhands.tools.terminal import TerminalTool

agent = Agent(llm=llm, tools=[Tool(name=TerminalTool.name)])  # tools=[] is also valid

conversation = Conversation(agent=agent, workspace=os.getcwd())
conversation.send_message("What is 2+2? Answer in one word.")  # str or Message
conversation.run()                                              # drives the agent loop
```

- **Tools are attached by NAME** via `Tool(name="...")` specs, resolved from a registry —
  not as callables. `FinishTool` (`finish`) and `ThinkTool` (`think`) are auto-added to
  every agent (controlled by `include_default_tools`, see below).
- `Agent` fields: `llm` (required), `tools` (list of `Tool` specs), `system_prompt`,
  `system_prompt_kwargs`, `condenser`, `critic`, `mcp_config`, `filter_tools_regex`,
  `tool_concurrency_limit`, `include_default_tools`, `agent_context`.
- **`include_default_tools`** (`list[str]`, default `["FinishTool", "ThinkTool"]`) controls
  which default tools get auto-injected. Pass `[]` to disable both, or a subset to keep only
  some — e.g. `include_default_tools=["ThinkTool"]` to skip the default `FinishTool` when you
  register your own schema-bound one (see §4).

### Reading the agent's answer

There is no return value from `run()`. Read events off `conversation.state.events`
(an iterable `EventLog`):

```python
from openhands.sdk import MessageEvent, TextContent

agent_msgs = [e for e in conversation.state.events
              if isinstance(e, MessageEvent) and e.source == "agent"]
final = agent_msgs[-1].llm_message
final_text = "".join(c.text for c in final.content if isinstance(c, TextContent))
```

Or collect live via a callback: `Conversation(agent=agent, callbacks=[fn])` where `fn(event)`
receives each `Event` as it happens.

**Stateless one-off:** `conversation.ask_agent("...") -> str` answers a side question without
touching state. **Returns `str` only** — not for structured extraction.

---

## 3. Custom tools

Four pieces: an `Action` (input schema), an `Observation` (what the LLM sees back), a
`ToolExecutor`, and a `ToolDefinition`. Register it, then reference by name.

```python
from collections.abc import Sequence
from pydantic import Field
from openhands.sdk import Action, Observation, ToolDefinition, TextContent, ImageContent
from openhands.sdk.tool import Tool, ToolExecutor, register_tool

class GrepAction(Action):
    pattern: str = Field(description="Regex to search for")
    path: str = Field(default=".", description="Directory to search")

class GrepObservation(Observation):
    matches: list[str] = Field(default_factory=list)
    count: int = 0

    @property
    def to_llm_content(self) -> Sequence[TextContent | ImageContent]:
        if not self.count:
            return [TextContent(text="No matches found.")]
        return [TextContent(text="\n".join(self.matches))]

class GrepExecutor(ToolExecutor[GrepAction, GrepObservation]):
    def __call__(self, action: GrepAction, conversation=None) -> GrepObservation:
        # ... do the work using action.pattern / action.path ...
        return GrepObservation(matches=[...], count=...)

class GrepTool(ToolDefinition[GrepAction, GrepObservation]):
    @classmethod
    def create(cls, conv_state, **params) -> Sequence[ToolDefinition]:
        return [cls(
            description="Search files with a regex.",
            action_type=GrepAction,
            observation_type=GrepObservation,
            executor=GrepExecutor(),
        )]

register_tool(GrepTool.name, GrepTool)            # GrepTool.name == "grep"
agent = Agent(llm=llm, tools=[Tool(name="grep")])
```

- **`ToolExecutor.__call__(self, action, conversation=None)`** — second arg is the conversation.
- **`ToolDefinition.create(cls, conv_state, **params)`** is a classmethod returning a
  `Sequence[ToolDefinition]` (one registered name can expand into several tools). `conv_state`
  exposes e.g. `conv_state.workspace.working_dir`.
- **`.name` is auto-derived** from the class name (`CamelCase` → `snake_case`, trailing
  `_tool` removed): `GrepTool` → `grep`. Override by setting `name = "..."` on the class.
- `Observation.to_llm_content -> Sequence[TextContent | ImageContent]`. Helpers:
  `Observation.from_text(text, is_error=False)`, `.text`.

### Built-in tools (`openhands.tools.*`)

| Class | import | `.name` |
|---|---|---|
| `TerminalTool` | `openhands.tools.terminal` | `terminal` |
| `FileEditorTool` | `openhands.tools.file_editor` | `file_editor` |
| `GrepTool` | `openhands.tools.grep` | `grep` |
| `GlobTool` | `openhands.tools.glob` | `glob` |
| `TaskTrackerTool` | `openhands.tools.task_tracker` | `task_tracker` |
| `BrowserToolSet` | `openhands.tools.browser_use` | `browser_tool_set` (+14 sub-tools) |

SDK built-ins: `FinishTool` (`finish`), `ThinkTool` (`think`) from `openhands.sdk.tool`.

There are more `openhands.tools.*` packages beyond this table now — `apply_patch`,
`ask_oracle`, `delegate` (sub-agent delegation), `gemini`, `planning_file_editor`, `preset`,
`task`, `tom_consult`, `workflow`. List `openhands-tools/openhands/tools/` in the SDK repo
for the current set rather than assuming this table is complete.

**There is NO native web-search tool.** Web fetch exists only via `BrowserToolSet` (requires
Chromium / the `browser-use` dep). The OpenHands way to do search/fetch is **MCP servers**:

```python
agent = Agent(llm=llm, tools=[], mcp_config={"mcpServers": {
    "tavily": {"command": "npx", "args": ["-y", "tavily-mcp@0.2.1"],
               "env": {"TAVILY_API_KEY": "..."}},          # -> tavily_search
    "fetch":  {"command": "uvx", "args": ["mcp-server-fetch"]},  # -> fetch (URL->text)
}})
```

For self-contained/offline search+fetch (e.g. your own Serper + scraping API), wrap them as
custom `ToolDefinition`s (§3) instead of MCP — no Chromium, no subprocess.

---

## 4. Structured output

There is still **no** `Agent(output_type=...)`. There are now **two** supported patterns —
prefer the first; it needs no new tool class.

### 4a. `response_schema` on an existing `Tool` spec (preferred)

Attach any Pydantic `BaseModel` to **any** tool's spec via `params={"response_schema": ...}`.
The SDK merges those fields into the tool's JSON-schema parameters, so the LLM must populate
them alongside the tool's own fields, and they come back validated. This works on your own
tools *and* on built-ins — including the default `FinishTool`, which is how you get a typed
final answer instead of a bare string:

```python
from typing import cast
from pydantic import BaseModel, Field
from openhands.sdk import LLM, Agent, Conversation
from openhands.sdk.event import ActionEvent
from openhands.sdk.tool import Tool, register_tool
from openhands.sdk.tool.builtins.finish import FinishTool

class ProjectFacts(BaseModel):
    description: str = Field(description="One-paragraph description of the project.")
    facts: list[str] = Field(description="Three concise, distinct facts.")

register_tool("FinishTool", FinishTool)   # needed to attach a response_schema to it

agent = Agent(
    llm=llm,
    tools=[Tool(name="FinishTool", params={"response_schema": ProjectFacts})],
    include_default_tools=["ThinkTool"],  # skip the auto-injected plain FinishTool
)

conversation = Conversation(agent=agent, workspace=os.getcwd())
conversation.send_message("Inspect the repo, then finish with three facts about it.")
conversation.run()

finish_tool = agent.tools_map["finish"]
facts = cast(ProjectFacts | None, finish_tool.parse_last_response(conversation.state.events))
# facts.description / facts.facts -> pydantic-validated
```

- `response_schema` field names must not collide with the tool's own fields or the reserved
  names `kind`, `security_risk`, `structured_output`, `summary` — collisions raise at
  resolution time.
- Any `ActionEvent` for that tool can be decoded the same way:
  `tool.parse_response(event.action)`.
- Full worked example (also shows attaching a schema to `TerminalTool` to force a rationale
  on every command): `examples/01_standalone_sdk/56_structured_output.py`.

### 4b. Custom `Action`-as-schema tool (for a brand-new tool with real side effects)

If you're building a genuinely new tool (not just annotating an existing one), define a tool
whose **`Action` is your output schema**, tell the agent to call it, then read the parsed
object off the `ActionEvent`:

```python
from openhands.sdk import Action, Observation, ToolDefinition, Agent, Conversation, Tool
from openhands.sdk.event import ActionEvent
from openhands.sdk.tool import Tool as ToolSpec, ToolExecutor, register_tool

class SubmitReferences(Action):           # <-- this IS your output schema
    references: list[Reference]

class _Ack(Observation):
    @property
    def to_llm_content(self):
        return [TextContent(text="Recorded.")]

class _Exec(ToolExecutor[SubmitReferences, _Ack]):
    def __call__(self, action, conversation=None) -> _Ack:
        return _Ack()                     # data is already on the event; just ack

class SubmitReferencesTool(ToolDefinition[SubmitReferences, _Ack]):
    @classmethod
    def create(cls, conv_state, **params):
        return [cls(description="Submit the extracted references.",
                    action_type=SubmitReferences, observation_type=_Ack, executor=_Exec())]

register_tool(SubmitReferencesTool.name, SubmitReferencesTool)
agent = Agent(llm=llm, tools=[ToolSpec(name=SubmitReferencesTool.name)])

conversation = Conversation(agent=agent, workspace=os.getcwd())
conversation.send_message(prompt + "\nCall submit_references with the result.")
conversation.run()

result = None
for event in conversation.state.events:
    if isinstance(event, ActionEvent) and event.tool_name == SubmitReferencesTool.name:
        result = event.action             # a validated `SubmitReferences` instance
# result.references -> list[Reference], pydantic-validated for you
```

`ActionEvent.action` is your `Action` subclass, already parsed/validated from the LLM's tool
arguments. (`openhands-sdk/openhands/sdk/event/llm_convertible/action.py`.)

---

## 5. Testing without real LLM calls — `TestLLM`

The SDK ships a real `LLM` subclass that replays scripted responses. No mocking/patching, and
it works anywhere an `LLM` is accepted (`Agent(llm=...)`, condensers, routers).

```python
from openhands.sdk.testing import TestLLM, TestLLMExhaustedError
from openhands.sdk import Agent, Conversation, Message, TextContent
from openhands.sdk.llm import MessageToolCall

# Plain scripted text replies:
llm = TestLLM.from_messages([
    Message(role="assistant", content=[TextContent(text="Done")]),
])

# Drive an agent through a tool call (e.g. your submit-tool) then finish:
def _tc(call_id, name, arguments_json):
    return MessageToolCall(id=call_id, name=name, arguments=arguments_json, origin="completion")

llm = TestLLM.from_messages([
    Message(role="assistant", content=[TextContent(text="submitting")],
            tool_calls=[_tc("c0", "submit_references", '{"references": []}')]),
    Message(role="assistant", content=[TextContent(text="done")],
            tool_calls=[_tc("c1", "finish", '{"message": "ok"}')]),
])
agent = Agent(llm=llm, tools=[Tool(name="submit_references")])
conversation = Conversation(agent=agent)
conversation.send_message("Extract references and submit them.")
conversation.run()
```

- `from_messages([...])` is an ordered queue; each `completion()` pops the next item.
- `arguments` is a JSON string; the agent parses it into your `Action` and exposes it on
  `ActionEvent.action`.
- Interleave `Exception` instances to script errors at specific steps.
- Exhausting the queue raises `TestLLMExhaustedError` (signals your script was too short).
- You may subclass `TestLLM` and override `completion()` for custom behavior.

No `FakeLLM`/`MockLLM`/vcr/cassette infra exists — `TestLLM` is the supported path.

---

## Key source references (`software-agent-sdk` / `main`)

- LLM + `completion`: `openhands-sdk/openhands/sdk/llm/llm.py`
- Message / TextContent: `openhands-sdk/openhands/sdk/llm/message.py`
- ActionEvent (structured read-back): `openhands-sdk/openhands/sdk/event/llm_convertible/action.py`
- MessageEvent: `openhands-sdk/openhands/sdk/event/llm_convertible/message.py`
- Tool base classes: `openhands-sdk/openhands/sdk/tool/{tool.py,schema.py}`, builtins in `.../tool/builtins/`
- `TestLLM`: `openhands-sdk/openhands/sdk/testing/test_llm.py`
- Examples: `examples/01_standalone_sdk/` (`01_hello_world.py`, `02_custom_tools.py`,
  `05_use_llm_registry.py`, `07_mcp_integration.py`, `28_ask_agent_example.py`,
  `39_llm_fallback.py`, `46_agent_settings.py`, `56_structured_output.py`) — there are 50+
  numbered examples in this directory now; browse it for anything not covered here
  (delegation, hooks, streaming, forking, security policies, etc).
- Docs: https://docs.openhands.dev/sdk/getting-started
