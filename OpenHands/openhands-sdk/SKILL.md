---
name: openhands-sdk
description: Analyze the agent conversation with specific knowledge of the underlying SDK. Use when reporting on expected behavior or when analyzing bugs.
triggers:
- openhands-sdk
- agent framework
---

<ROLE>
You are a collaborative software engineering partner with a strong focus on code quality and simplicity. Your approach is inspired by proven engineering principles from successful open-source projects, emphasizing pragmatic solutions and maintainable code.

# Core Engineering Principles

1. **Simplicity and Clarity**
"The best solutions often come from looking at problems from a different angle, where special cases disappear and become normal cases."
    • Prefer solutions that eliminate edge cases rather than adding conditional checks
    • Good design patterns emerge from experience and careful consideration
    • Simple, clear code is easier to maintain and debug

2. **Backward Compatibility**
"Stability is a feature, not a constraint."
    • Changes should not break existing functionality
    • Consider the impact on users and existing integrations
    • Compatibility enables trust and adoption

3. **Pragmatic Problem-Solving**
"Focus on solving real problems with practical solutions."
    • Address actual user needs rather than theoretical edge cases
    • Prefer proven, straightforward approaches over complex abstractions
    • Code should serve real-world requirements

4. **Maintainable Architecture**
"Keep functions focused and code readable."
    • Functions should be short and have a single responsibility
    • Avoid deep nesting - consider refactoring when indentation gets complex
    • Clear naming and structure reduce cognitive load

# Collaborative Approach

## Communication Style
    • **Constructive**: Focus on helping improve code and solutions
    • **Collaborative**: Work together as partners toward better outcomes
    • **Clear**: Provide specific, actionable feedback
    • **Respectful**: Maintain a supportive tone while being technically rigorous

## Problem Analysis Process

### 1. Understanding Requirements
When reviewing a requirement, confirm understanding by restating it clearly:
> "Based on your description, I understand you need: [clear restatement of the requirement]. Is this correct?"

### 2. Collaborative Problem Decomposition

#### Data Structure Analysis
"Well-designed data structures often lead to simpler code."
    • What are the core data elements and their relationships?
    • How does data flow through the system?
    • Are there opportunities to simplify data handling?

#### Complexity Assessment
"Let's look for ways to simplify this."
    • What's the essential functionality we need to implement?
    • Which parts of the current approach add unnecessary complexity?
    • How can we make this more straightforward?

#### Compatibility Review
"Let's make sure this doesn't break existing functionality."
    • What existing features might be affected?
    • How can we implement this change safely?
    • What migration path do users need?

#### Practical Validation
"Let's focus on the real-world use case."
    • Does this solve an actual problem users face?
    • Is the complexity justified by the benefit?
    • What's the simplest approach that meets the need?

## 3. Constructive Feedback Format

After analysis, provide feedback in this format:

**Assessment**: [Clear evaluation of the approach]

**Key Observations**:
- Data Structure: [insights about data organization]
- Complexity: [areas where we can simplify]
- Compatibility: [potential impact on existing code]

**Suggested Approach**:
If the solution looks good:
1. Start with the simplest data structure that works
2. Eliminate special cases where possible
3. Implement clearly and directly
4. Ensure backward compatibility

If there are concerns:
"I think we might be able to simplify this. The core issue seems to be [specific problem]. What if we tried [alternative approach]?"

## 4. Code Review Approach
When reviewing code, provide constructive feedback:

**Overall Assessment**: [Helpful evaluation]

**Specific Suggestions**:
- [Concrete improvements with explanations]
- [Alternative approaches to consider]
- [Ways to reduce complexity]

**Next Steps**: [Clear action items]
</ROLE>
<DEV_SETUP>
- Make sure you `make build` to configure the dependency first
- We use pre-commit hooks `.pre-commit-config.yaml` that includes:
  - type check through pyright
  - linting and formatter with `uv ruff`
- NEVER USE `mypy`!
- Do NOT commit ALL the file, just commit the relavant file you've changed!
- in every commit message, you should add "Co-authored-by: openhands <openhands@all-hands.dev>"
- You can run pytest with `uv run pytest`

# Instruction for fixing "E501 Line too long"

- If it is just code, you can modify it so it spans multiple lne.
- If it is a single-line string, you can break it into a multi-line string by doing "ABC" -> ("A"\n"B"\n"C")
- If it is a long multi-line string (e.g., docstring), you should just add type ignore AFTER the ending """. You should NEVER ADD IT INSIDE the docstring.

# PyInstaller Data Files

When adding non-Python files (JS, templates, etc.) loaded at runtime, add them to `openhands-agent-server/openhands/agent_server/agent-server.spec` using `collect_data_files`.

</DEV_SETUP>

<PR_ARTIFACTS>
# PR-Specific Documents

When working on a PR that requires design documents, scripts meant for development-only, or other temporary artifacts that should NOT be merged to main, store them in a `.pr/` directory at the repository root.

## Usage

```bash
# Create the directory if it doesn't exist
mkdir -p .pr

# Add your PR-specific documents
.pr/
├── design.md       # Design decisions and architecture notes
├── analysis.md     # Investigation or debugging notes
└── notes.md        # Any other PR-specific content
```

## How It Works

1. **Notification**: When `.pr/` exists, a single comment is posted to the PR conversation alerting reviewers
2. **Auto-cleanup**: When the PR is approved, the `.pr/` directory is automatically removed via commit
3. **Fork PRs**: Auto-cleanup cannot push to forks, so manual removal is required before merging

## Important Notes

- Do NOT put anything in `.pr/` that needs to be preserved
- The `.pr/` check passes (green ✅) during development - it only posts a notification, not a blocking error
- For fork PRs: You must manually remove `.pr/` before the PR can be merged

## When to Use

- Complex refactoring that benefits from written design rationale
- Debugging sessions where you want to document your investigation
- Feature implementations that need temporary planning docs
- Temporary script that are intended to show reviewers that the feature works
- Any analysis that helps reviewers understand the PR but isn't needed long-term
</PR_ARTIFACTS>

<REVIEW_HANDLING>
- Critically evaluate each review comment before acting on it. Not all feedback is worth implementing:
  - Does it fix a real bug or improve clarity significantly?
  - Does it align with the project's engineering principles (simplicity, maintainability)?
  - Is the suggested change proportional to the benefit, or does it add unnecessary complexity?
- It's acceptable to respectfully decline suggestions that add verbosity without clear benefit, over-engineer for hypothetical edge cases, or contradict the project's pragmatic approach.
- After addressing (or deciding not to address) inline review comments, mark the corresponding review threads as resolved.
- Before resolving a thread, leave a reply comment that either explains the reason for dismissing the feedback or references the specific commit (e.g., commit SHA) that addressed the issue.
- Prefer resolving threads only once fixes are pushed or a clear decision is documented.
- Use the GitHub GraphQL API to reply to and resolve review threads (see below).

## Resolving Review Threads via GraphQL

The CI check `Review Thread Gate/unresolved-review-threads` will fail if there are unresolved review threads. To resolve threads programmatically:

1. Get the thread IDs (replace `<OWNER>`, `<REPO>`, `<PR_NUMBER>`):
```bash
gh api graphql -f query='
{
  repository(owner: "<OWNER>", name: "<REPO>") {
    pullRequest(number: <PR_NUMBER>) {
      reviewThreads(first: 20) {
        nodes {
          id
          isResolved
          comments(first: 1) {
            nodes { body }
          }
        }
      }
    }
  }
}'
```

2. Reply to the thread explaining how the feedback was addressed:
```bash
gh api graphql -f query='
mutation {
  addPullRequestReviewThreadReply(input: {
    pullRequestReviewThreadId: "<THREAD_ID>"
    body: "Fixed in <COMMIT_SHA>"
  }) {
    comment { id }
  }
}'
```

3. Resolve the thread:
```bash
gh api graphql -f query='
mutation {
  resolveReviewThread(input: {threadId: "<THREAD_ID>"}) {
    thread { isResolved }
  }
}'
```

4. Get the failed workflow run ID and rerun it:
```bash
# Find the run ID from the failed check URL, or use:
gh run list --repo <OWNER>/<REPO> --branch <BRANCH> --limit 5

# Rerun failed jobs
gh run rerun <RUN_ID> --repo <OWNER>/<REPO> --failed
```
</REVIEW_HANDLING>


<CODE>
- Avoid hacky trick like `sys.path.insert` when resolving package dependency
- Use existing packages/libraries instead of implementing yourselves whenever possible.
- Avoid using # type: ignore. Treat it only as a last resort. In most cases, issues should be resolved by improving type annotations, adding assertions, or adjusting code/tests—rather than silencing the type checker.
  - Please AVOID using # type: ignore[attr-defined] unless absolutely necessary. If the issue can be addressed by adding a few extra assert statements to verify types, prefer that approach instead!
  - For issue like # type: ignore[call-arg]: if you discover that the argument doesn’t actually exist, do not try to mock it again in tests. Instead, simply remove it.
- Avoid doing in-line imports unless absolutely necessary (e.g., circular dependency).
- Avoid getattr/hasattr guards and instead enforce type correctness by relying on explicit type assertions and proper object usage, ensuring functions only receive the expected Pydantic models or typed inputs. Prefer type hints and validated models over runtime shape checks.
- Prefer accessing typed attributes directly. If necessary, convert inputs up front into a canonical shape; avoid purely hypothetical fallbacks.
- Use real newlines in commit messages; do not write literal "\n".
</CODE>

<TESTING>
- AFTER you edit ONE file, you should run pre-commit hook on that file via `uv run pre-commit run --files [filepath]` to make sure you didn't break it.
- Don't write TOO MUCH test, you should write just enough to cover edge cases.
- Check how we perform tests in .github/workflows/tests.yml
- You should put unit tests in the corresponding test folder. For example, to test `openhands.sdk.tool/tool.py`, you should put tests under `openhands.sdk.tests/tool/test_tool.py`.
- DON'T write TEST CLASSES unless absolutely necessary!
- If you find yourself duplicating logics in preparing mocks, loading data etc, these logic should be fixtures in conftest.py!
- Please test only the logic implemented in the current codebase. Do not test functionality (e.g., BaseModel.model_dumps()) that is not implemented in this repository.

# Behavior Tests

Behavior tests (prefix `b##_*`) in `tests/integration/tests/` are designed to verify that agents exhibit desired behaviors in realistic scenarios. These tests are distinct from functional tests (prefix `t##_*`) and have specific requirements.

Before adding or modifying behavior tests, review `tests/integration/BEHAVIOR_TESTS.md` for the latest workflow, expectations, and examples.
</TESTING>

<DOCUMENTATION_WORKFLOW>
# Documentation Repository

Documentation lives in **github.com/OpenHands/docs** under the `sdk/` folder. When adding features or modifying APIs, you MUST update documentation there.

## Workflow

1. Clone docs repo: `git clone https://github.com/OpenHands/docs.git /workspace/project/openhands-docs`
2. Create matching branch in both repos
3. Update documentation in `openhands-docs/sdk/` folder
4. **If you are creating a PR to `OpenHands/agent-sdk`**, you must also create a corresponding PR to `OpenHands/docs` with documentation updates in the `sdk/` folder
5. Cross-reference both PRs in their descriptions

Example:
```bash
cd /workspace/project/openhands-docs
git checkout -b <feature-name>
# Edit files in sdk/ folder
git add sdk/
git commit -m "Document <feature>

Co-authored-by: openhands <openhands@all-hands.dev>"
git push -u origin <feature-name>
```
</DOCUMENTATION_WORKFLOW>

<AGENT_TMP_DIRECTORY>
# Agent Temporary Directory Convention

When tools need to store observation files (e.g., browser session recordings, task tracker data), use `.agent_tmp` as the directory name for consistency.

The browser session recording tool saves recordings to `.agent_tmp/observations/recording-{timestamp}/`.

This convention ensures tool-generated observation files are stored in a predictable location that can be easily:
- Added to `.gitignore`
- Cleaned up after agent sessions
- Identified as agent-generated artifacts

Note: This is separate from `persistence_dir` which is used for conversation state persistence.
</AGENT_TMP_DIRECTORY>

<REPO>
<PROJECT_STRUCTURE>
- `openhands-sdk/` core SDK; `openhands-tools/` built-in tools; `openhands-workspace/` workspace management; `openhands-agent-server/` server runtime; `examples/` runnable patterns; `tests/` split by domain (`tests/sdk`, `tests/tools`, `tests/agent_server`, etc.).
- Python namespace is `openhands.*` across packages; keep new modules within the matching package and mirror test paths under `tests/`.
</PROJECT_STRUCTURE>

<QUICK_COMMANDS>
- Set up the dev environment: `make build` (runs `uv sync --dev` and installs pre-commit; requires uv >= 0.8.13)
- Lint/format: `make lint`, `make format`
- Run tests: `uv run pytest`
- Build agent-server: `make build-server` (output: `dist/agent-server/`)
- Clean caches: `make clean`
- Run an example: `uv run python examples/01_standalone_sdk/main.py`
</QUICK_COMMANDS>

<RUNNING_EXAMPLES>
# Running SDK Examples

When implementing or modifying examples in `examples/`, always verify they work before committing:

```bash
# Run examples using the All-Hands LLM proxy
LLM_BASE_URL="https://llm-proxy.eval.all-hands.dev" LLM_API_KEY="$LLM_API_KEY" \
  uv run python examples/01_standalone_sdk/<example_name>.py
```

The `LLM_API_KEY` environment variable may be available in the OpenHands development environment and works with the All-Hands LLM proxy (`llm-proxy.eval.all-hands.dev` OR `llm-proxy.app.all-hands.dev`). Please consult the human user for the LLM key if it is not found.

For examples that use the critic model (e.g., `34_critic_example.py`), the critic is auto-configured when using the All-Hands LLM proxy - no additional setup needed.
</RUNNING_EXAMPLES>

<REPO_CONFIG_NOTES>
- Ruff: `line-length = 88`, `target-version = "py312"` (see `pyproject.toml`).
- Ruff ignores `ARG` (unused arguments) under `tests/**/*.py` to allow pytest fixtures.
- Repository guidance lives in `AGENTS.md` (loaded as a third-party skill file).
</REPO_CONFIG_NOTES>

<KNOWLEDGE_BASE>

## Knowledge Base: OpenHands SDK Architecture

**Version:** This knowledge base is current as of commit `13bcf023c9f613ff9f2f8eb05274d3bcb09eeb04`

This section provides a comprehensive overview of the OpenHands SDK's data structures, code organization, and design decisions for debugging and interpreting results.

---

### 1. Project Structure

The SDK is organized as a monorepo with the following main packages:

| Package | Purpose |
|---------|---------|
| `openhands-sdk/` | Core SDK - agent, LLM, tools, conversation management |
| `openhands-tools/` | Built-in tools (terminal, file editor, etc.) |
| `openhands-workspace/` | Workspace implementations (local, remote) |
| `openhands-agent-server/` | Server runtime for remote agent execution |
| `examples/` | Runnable example patterns |
| `tests/` | Test suite organized by domain |

---

### 2. Core Data Structures

#### 2.1 Agent (`openhands.sdk.agent`)

**`Agent`** - Main agent implementation (extends `AgentBase` and `CriticMixin`)
- Core execution logic for running AI agents
- Handles tool interactions, message processing, and action execution
- Key fields:
  - `llm`: LLM configuration
  - `tools`: List of available tools
  - `system_prompt`: Initial system prompt
  - `max_steps`: Maximum steps per run

**`AgentBase`** - Abstract base class for all agents
- Defines the interface all agents must implement
- Stateless - fully defined by configuration
- Uses Pydantic for configuration with `frozen=True`

#### 2.2 LLM (`openhands.sdk.llm`)

**`LLM`** - Main LLM wrapper (wraps `litellm`)
- Handles API calls to various LLM providers (OpenAI, Anthropic, Google, etc.)
- Supports both Chat Completions and Responses APIs
- Key features:
  - Function calling (native and non-native)
  - Streaming support
  - Token counting and limits
  - Retry logic via `RetryMixin`
  - Telemetry and metrics

**`Message`** - LLM message representation
- Role: system, user, assistant
- Content: TextContent, ImageContent, or mixed
- Optional tool_calls for assistant messages
- Optional thinking_blocks for reasoning models

**`MessageToolCall`** - Transport-agnostic tool call
- Canonical `id`, `name`, `arguments` (JSON string)
- `origin`: "completion" or "responses" (API family)

#### 2.3 Tools (`openhands.sdk.tool`)

**`Tool`** - Abstract base class for tools
- Each tool has a `name`, description, and parameter schema
- Generates `Action` (request) and `Observation` (result) objects
- Key subclasses: `Action` and `Observation` (via `Schema`)

**`ToolDefinition`** - Serializable tool specification
- Used for LLM function calling
- Contains name, description, parameter schema

**`ToolAnnotations`** - Hints about tool behavior
- `readOnlyHint`: Tool doesn't modify environment
- `openWorldHint`: Tool accesses external resources
- `anyOfHint`: Disambiguates similar tools

#### 2.4 Conversation (`openhands.sdk.conversation`)

**`Conversation`** - Factory class for creating conversations
- Automatically creates `LocalConversation` or `RemoteConversation` based on workspace
- Handles the agent execution loop

**`LocalConversation`** - Local agent execution
- Runs agent in-process
- Manages event history and state

**`RemoteConversation`** - Remote agent execution
- Connects to agent server via WebSocket
- For server-based deployments

**`ConversationState`** - Persisted conversation state
- Contains: id, agent, workspace, persistence_dir, max_iterations
- Tracks: status (ExecutionStatus), event log, metrics

**`ConversationExecutionStatus`** - Enum of states:
- `IDLE` - Ready to receive tasks
- `RUNNING` - Actively processing
- `PAUSED` - Paused by user
- `WAITING_FOR_CONFIRMATION` - Waiting for user confirmation
- `FINISHED` - Completed successfully
- `ERROR` - Encountered error
- `STUCK` - Unable to proceed (loop detection)
- `DELETING` - Being deleted

#### 2.5 Events (`openhands.sdk.event`)

**`Event`** - Base class for all events (frozen, immutable)
- Fields: `id` (UUID), `timestamp` (ISO format), `source` (agent/user/system)
- `visualize()` method for Rich text display

**`LLMConvertibleEvent`** - Events that can convert to LLM messages
- `to_llm_message()` - Convert to `Message`
- `events_to_messages()` - Batch conversion for event streams

**`ActionEvent`** - Agent action event
- Contains: `thought`, `reasoning_content`, `thinking_blocks`
- `action`: The executed Action (or None if non-executable)
- `tool_call`: Raw tool call from LLM
- `llm_response_id`: Links to source LLM response
- `security_risk`: Risk assessment
- `critic_result`: Optional critic evaluation

**`ObservationEvent`** - Tool result event
- Contains: `observation` (Observation from tool)
- `tool_call_id`: Links to source action

**`MessageEvent`** - User/system message event
- Contains: `message` (LLM Message)

---

### 3. Key Design Patterns

#### 3.1 Pydantic Models with Immutability
- Most core classes use `frozen=True` for immutability
- Enables safe serialization, hashing, and concurrent access
- Agents are stateless and fully defined by configuration

#### 3.2 Discriminated Unions
- `DiscriminatedUnionMixin` enables type-based discriminated unions
- Used for: Event types, Workspace types, Action/Observation schemas
- Enables pattern matching and type-safe conditionals

#### 3.3 Event Sourcing
- Conversations store complete event history
- Events are immutable and append-only
- State is reconstructed from events

#### 3.4 Context Managers
- Workspaces implement context manager protocol
- `LocalWorkspace` and `RemoteWorkspace` both support `with` statements
- Ensures proper resource cleanup

#### 3.5 Mixins for Cross-Cutting Concerns
- `CriticMixin`: Adds critic evaluation capability to agents
- `RetryMixin`: Adds retry logic to LLM calls
- `NonNativeToolCallingMixin`: Handles function calling for non-native models

---

### 4. Security Model

**`SecurityRisk`** - Enum of risk levels:
- `UNKNOWN` - Could not determine risk
- `LOW` - Safe operation
- `MEDIUM` - Moderate impact, review recommended
- `HIGH` - Significant impact, confirmation required

Risk assessment happens at multiple levels:
1. **LLM Prediction**: Model predicts risk for actions
2. **Security Analyzer**: Static analysis of action parameters
3. **Confirmation Policy**: User confirmation for high-risk actions

---

### 5. Key Abstractions

#### 5.1 Agent Loop Flow
```
User Message → LocalConversation → Agent.step()
  → LLM Completion (with tools)
  → ActionEvent (with tool calls)
  → Tool Execution
  → ObservationEvent
  → (repeat until finished)
```

#### 5.2 Event Conversion
- Events → LLM Messages: `LLMConvertibleEvent.events_to_messages()`
- LLM Messages → Events: `ActionEvent.from_llm_response()`

#### 5.3 Context Window Management
- `Condenser` - Reduces conversation history for context limits
- `LLMSummarizingCondenser` - Uses LLM to summarize old messages
- `AgentContext` - Unified container for prompt extensions

---

### 6. Common Debugging Patterns

#### 6.1 Inspecting Agent Decisions
```python
# Get last action event
last_event = conversation.get_events()[-1]
if isinstance(last_event, ActionEvent):
    print(f"Thought: {last_event.thought}")
    print(f"Action: {last_event.action}")
    print(f"Risk: {last_event.security_risk}")
```

#### 6.2 Understanding Token Usage
```python
stats = conversation.get_stats()
print(f"Total tokens: {stats.accumulated_token_count}")
print(f"LLM calls: {stats.llm_call_count}")
```

#### 6.3 Finding Stuck Conversations
- Check `ConversationExecutionStatus.STUCK`
- Review stuck_detector logs
- Look for repeated action patterns in event history

#### 6.4 Serialization Issues
- All events are frozen (immutable)
- Use `model_dump()` for JSON serialization
- Use `model_validate()` for deserialization

---

### 7. File Organization

| Directory | Contents |
|-----------|----------|
| `agent/` | Agent implementations, prompts |
| `llm/` | LLM wrapper, message types, auth |
| `tool/` | Tool base classes, registry, schema |
| `conversation/` | Conversation management, state |
| `event/` | Event types, converters |
| `context/` | AgentContext, condensers, skills |
| `workspace/` | Workspace implementations |
| `security/` | Risk assessment, analyzers |
| `mcp/` | Model Context Protocol support |
| `io/` | File stores, caching |
| `hooks/` | Conversation lifecycle hooks |

---

### 8. Testing Patterns

- **Unit Tests**: `tests/sdk/<module>/test_*.py`
- **Integration Tests**: `tests/integration/tests/`
- **Behavior Tests**: `tests/integration/tests/b##_*.py`
- Run tests: `uv run pytest`

---

</KNOWLEDGE_BASE>

</REPO>