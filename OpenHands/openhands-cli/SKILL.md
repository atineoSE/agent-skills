---
name: openhands-cli
description: Analyze CLI environment for the OpenHands agent. Use when reporting about the agent conversation.
triggers:
- openhands-cli
- cli
---



# OpenHands CLI Knowledge Base

> **Version:** Updated based on code analysis - January 2025
> **Purpose:** Knowledge base for debugging and interpreting results

## Overview

OpenHands CLI is a terminal interface (Textual TUI) for interacting with the OpenHands agent. It provides multiple modes of operation:
- **Terminal (TUI):** Interactive terminal UI using Textual
- **ACP Mode:** Agent Communication Protocol for IDE integration
- **Headless:** Non-interactive mode for CI/CD
- **Web Interface:** Browser-based TUI via `textual-serve`
- **GUI Server:** Full web GUI via Docker

---

## 1. Main Data Structures

### 1.1 Core State Management

#### `ConversationContainer` (in `tui/core/state.py`)
The central reactive state holder in the TUI. Key reactive properties:

| Property | Type | Description |
|----------|------|-------------|
| `running` | `var[bool]` | Whether the conversation is currently processing |
| `conversation_id` | `var[uuid.UUID \| None]` | Active conversation ID (None during switching) |
| `conversation_title` | `var[str \| None]` | Title (first user message) |
| `confirmation_policy` | `var[ConfirmationPolicyBase]` | Current confirmation policy |
| `pending_action_count` | `var[int]` | Pending actions awaiting confirmation |
| `elapsed_seconds` | `var[int]` | Seconds since conversation started |
| `metrics` | `var[Metrics \| None]` | Combined conversation metrics |
| `loaded_resources` | `var[LoadedResourcesInfo \| None]` | Loaded skills, hooks, MCPs |

**Thread-safe state update methods:**
- `set_running(value: bool)`
- `set_conversation_id(conversation_id: uuid.UUID | None)`
- `set_metrics(metrics: Metrics)`
- `set_pending_action_count(count: int)`
- `set_loaded_resources(resources: LoadedResourcesInfo)`

### 1.2 Conversation Models

#### `ConversationMetadata` (in `conversations/models.py`)
```python
@dataclass
class ConversationMetadata:
    id: str
    created_at: datetime
    title: str | None = None
    last_modified: datetime | None = None
```

#### `ConversationStore` Protocol (in `conversations/protocols.py`)
Abstract interface for conversation storage:
- `list_conversations(limit: int) -> list[ConversationMetadata]`
- `get_metadata(conversation_id: str) -> ConversationMetadata | None`
- `get_event_count(conversation_id: str) -> int`
- `load_events(conversation_id: str, limit, start_from_newest) -> Iterator[Event]`
- `exists(conversation_id: str) -> bool`
- `create(conversation_id: str | None = None) -> str`

### 1.3 User Actions

#### `UserConfirmation` Enum (in `user_actions/types.py`)
```python
class UserConfirmation(Enum):
    ACCEPT = "accept"
    REJECT = "reject"
    DEFER = "defer"
    ALWAYS_PROCEED = "always_proceed"
    CONFIRM_RISKY = "confirm_risky"
```

#### `ConfirmationResult` (in `user_actions/types.py`)
```python
class ConfirmationResult(BaseModel):
    decision: UserConfirmation
    policy_change: ConfirmationPolicyBase | None = None
    reason: str = ""
```

### 1.4 Messages (Events)

Core messages for TUI communication (`tui/core/conversation_manager.py`):

| Message | Purpose |
|---------|---------|
| `SendMessage` | Request to send user message to conversation |
| `CreateConversation` | Request to create new conversation |
| `SwitchConversation` | Request to switch to different conversation |
| `PauseConversation` | Request to pause running conversation |
| `CondenseConversation` | Request to condense conversation history |
| `SetConfirmationPolicy` | Request to change confirmation policy |
| `SwitchConfirmed` | Internal: User confirmed switch in modal |
| `ShowConfirmationPanel` | Request UI to show confirmation panel |
| `ConfirmationDecision` | User's confirmation decision |

State-level messages (`tui/core/state.py`):
- `ConversationFinished`: Emitted when conversation finishes
- `ConfirmationRequired`: Emitted when actions need user confirmation

---

## 2. Code Organization

### 2.1 Module Structure

```
openhands_cli/
├── entrypoint.py              # Main CLI entry point
├── setup.py                   # Agent/conversation setup utilities
├── utils.py                   # Shared utilities
├── theme.py                   # CLI theming
├── locations.py               # Path configuration
├── version_check.py           # Version checking
│
├── argparsers/                # Command-line argument parsing
│   ├── main_parser.py
│   ├── acp_parser.py
│   ├── auth_parser.py
│   ├── cloud_parser.py
│   ├── mcp_parser.py
│   ├── serve_parser.py
│   ├── view_parser.py
│   └── web_parser.py
│
├── auth/                      # Authentication
│   ├── api_client.py
│   ├── device_flow.py
│   ├── http_client.py
│   ├── login_command.py
│   ├── logout_command.py
│   ├── token_storage.py
│   └── utils.py
│
├── stores/                    # Configuration & storage
│   ├── agent_store.py         # Agent configuration storage
│   └── cli_settings.py        # CLI preferences
│
├── conversations/             # Conversation management
│   ├── models.py              # Data models
│   ├── protocols.py           # Storage protocols
│   ├── display.py             # Conversation listing display
│   ├── viewer.py              # Conversation viewer
│   └── store/                 # Conversation storage implementation
│
├── tui/                       # Textual TUI
│   ├── textual_app.py         # Main TUI application
│   ├── serve.py               # Web server launcher
│   ├── messages.py            # TUI-specific messages
│   ├── theme.py               # TUI theming
│   │
│   ├── core/                  # Core TUI logic
│   │   ├── state.py           # ConversationContainer
│   │   ├── conversation_manager.py  # Message router
│   │   ├── conversation_runner.py   # Conversation execution
│   │   ├── runner_factory.py        # Runner creation
│   │   ├── runner_registry.py       # Runner lifecycle
│   │   ├── events.py               # Event definitions
│   │   ├── commands.py              # TUI commands
│   │   ├── user_message_controller.py
│   │   ├── conversation_crud_controller.py
│   │   ├── conversation_switch_controller.py
│   │   ├── confirmation_flow_controller.py
│   │   └── confirmation_policy_service.py
│   │
│   ├── widgets/               # TUI widgets
│   │   ├── main_display.py
│   │   ├── input_area.py
│   │   ├── splash.py
│   │   ├── status_line.py
│   │   └── richlog_visualizer.py
│   │
│   ├── content/              # Content display
│   ├── modals/               # Modal dialogs
│   ├── panels/               # Panel widgets
│   └── utils/                # TUI utilities
│
├── acp_impl/                  # Agent Communication Protocol
│   ├── main.py               # ACP entry point
│   ├── runner.py             # ACP conversation runner
│   ├── confirmation.py       # ACP confirmation handling
│   ├── slash_commands.py     # Slash command handlers
│   ├── agent/                # ACP agent implementation
│   └── events/               # ACP events
│
├── cloud/                     # OpenHands Cloud integration
│   ├── command.py
│   └── conversation.py
│
├── mcp/                       # MCP server support
│   ├── mcp_commands.py
│   ├── mcp_utils.py
│   └── mcp_display_utils.py
│
└── user_actions/              # User action handling
    └── types.py              # Confirmation types
```

### 2.2 Key Entry Points

1. **`entrypoint.py`** - Main CLI entry point
   - Routes to different commands (serve, web, acp, login, logout, mcp, cloud, view)
   - Handles resume logic
   - Launches TUI or runs headless

2. **`tui/textual_app.py`** - Main TUI application
   - Composes the full UI with ConversationManager

3. **`acp_impl/main.py`** - ACP server entry point

---

## 3. Main Abstractions and Design Patterns

### 3.1 Architecture: Reactive State Management

The TUI uses a **reactive state management pattern** with clear separation:

```
┌─────────────────────────────────────────────────────────────┐
│                    OpenHandsApp (Textual App)               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│            ConversationManager (Message Router)             │
│  - Routes messages to controllers                          │
│  - Owns RunnerRegistry, controllers, services              │
└─────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────┼───────────────────┐
          ▼                   ▼                   ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│    Controllers  │  │   Services      │  │  RunnerRegistry │
│                 │  │                 │  │                 │
│ - UserMessage   │  │ - Confirmation  │  │ - create()      │
│ - Conversation   │  │   PolicyService  │  │ - get_current() │
│   CRUD          │  │                  │  │ - cache by ID   │
│ - Conversation   │  │                  │  │                 │
│   Switch        │  │                  │  └────────┬────────┘
│ - Confirmation  │  │                  │           │
│   Flow          │  │                  │           ▼
└────────┬────────┘  └─────────────────┘  ┌─────────────────┐
         │                                  │ ConversationRunner│
         │                                  │ - conversation   │
         │                                  │ - visualizer      │
         │                                  │ - execute loop    │
         └──────────────────────────────────┴────────┬────────┘
                                                   │
                                                   ▼
┌─────────────────────────────────────────────────────────────┐
│              ConversationContainer (Reactive State)         │
│  Properties: running, conversation_id, metrics, etc.        │
│  Widgets bind via data_bind() and auto-update              │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Controller Pattern

Each controller has single responsibility:

| Controller | Responsibility |
|------------|----------------|
| `UserMessageController` | Handles user input, renders messages, queues/processes with runner |
| `ConversationCrudController` | Creates new conversations, resets state |
| `ConversationSwitchController` | Orchestrates switching (pause current, prepare new) |
| `ConfirmationFlowController` | Shows confirmation panel, handles user decisions |
| `ConfirmationPolicyService` | Syncs policy to conversations |

### 3.3 Runner Pattern

`ConversationRunner` encapsulates:
- Conversation lifecycle (start, pause, resume, condense)
- Confirmation handling
- Event visualization
- Metrics collection

Factory pattern via `RunnerFactory` creates runners with dependencies.

### 3.4 Message-Based Communication

Components communicate via Textual messages that bubble up:
- Widgets post messages (e.g., `UserInputSubmitted`)
- `ConversationManager` listens and delegates to controllers
- Controllers post messages to trigger UI updates

### 3.5 Confirmation Modes

Three confirmation policies (from `openhands.sdk.security.confirmation_policy`):

1. **`AlwaysConfirm`** - Ask for confirmation on every action
2. **`NeverConfirm`** - Auto-approve all actions (`--always-approve`)
3. **`ConfirmRisky`** - LLM-based security analyzer (`--llm-approve`)

### 3.6 Storage Abstraction

`ConversationStore` protocol allows different storage backends:
- `LocalFileStore` - File-based storage (default)
- Future: Cloud storage, database, etc.

---

## 4. Key Integration Points

### 4.1 Agent Creation Flow

```
entrypoint.py
    │
    ▼
setup.py::load_agent_specs()
    │
    ▼
AgentStore::load_or_create()
    │
    ▼
Agent (from openhands.sdk)
    │
    ▼
setup_conversation() → Conversation
    │
    ▼
ConversationRunner
```

### 4.2 Conversation Execution Flow

```
User Input → InputField → UserInputSubmitted
    │
    ▼
ConversationManager::_on_user_input_submitted()
    │
    ▼
UserMessageController::handle_user_message()
    │
    ▼
ConversationRunner::process_message_async()
    │
    ▼ (run in executor thread)
conversation.send_message() → conversation.run()
    │
    ▼
Events generated → Visualizer → UI
    │
    ▼ (if confirmation needed)
ShowConfirmationPanel → ConfirmationFlowController
    │
    ▼
User decision → ConversationRunner::resume_after_confirmation()
```

### 4.3 ACP Protocol Flow

```
ACP Client connects
    │
    ▼
run_acp_server() in acp_impl/main.py
    │
    ▼
setup_conversation() - same as TUI
    │
    ▼
run_conversation_with_confirmation() in runner.py
    │
    ▼ (async loop)
conversation.run() → wait for status
    │
    ▼ (if WAITING_FOR_CONFIRMATION)
ask_user_confirmation_acp() → ACP permission request
    │
    ▼
User decision → continue/pause/reject
```

---

## 5. Configuration Files

| File | Location | Purpose |
|------|----------|---------|
| `agent_settings.json` | `~/.openhands/` | Agent configuration (LLM settings, condenser config) |
| `cli_config.json` | `~/.openhands/` | CLI/TUI preferences |
| `mcp.json` | `~/.openhands/` | MCP server configuration |
| `hooks.json` | `~/.openhands/` or `{working_dir}/.openhands/` | Runtime hooks |

---

## 6. Debugging Tips

### 6.1 Viewing Conversations

```bash
# List recent conversations
openhands --resume

# View specific conversation
openhands view <conversation_id>
```

### 6.2 Logging

- Set `DEBUG=1` or `DEBUG=true` for verbose logging
- Check `~/.openhands/` for logs

### 6.3 Common Issues

1. **Missing LLM settings:** Run `openhands` initially to configure
2. **Confirmation not working:** Check `--always-approve` or `--llm-approve` flags
3. **Conversation not resuming:** Verify conversation ID exists in store

---

## 7. Dependencies (Key External)

- **Textual:** TUI framework
- **Rich:** Terminal rendering
- **openhands (SDK):** Agent and conversation management
- **Pydantic:** Data validation
- **uv:** Dependency management

---

*Last Updated: Based on code analysis - January 2025*
