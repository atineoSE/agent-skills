---
name: anytype
version: 2.0.0
description: Use the local Anytype HTTP API (via the Anytype CLI / anytype-heart server on 127.0.0.1:31012) to manage spaces, objects, properties, types, tags, chats, and search — API v2 (AnyBlock documents, batched PATCH ops) and v1. Use when the user wants to read, create, or update Anytype content programmatically.
user-invocable: true
allowed-tools: Bash, Read
---

# Anytype API

> **Skill version: 2.0.0** — last verified against a live server on **2026-10-26**
> (`anytype-cli v0.5.0`, embedded anytype-heart v0.51.6, API version `2025-11-08`
> for both `/v1` and `/v2`).
>
> **Keep this in sync.** Whenever you discover new endpoints, a changed
> response shape, a new `Anytype-Version`, or any behavior that contradicts
> what's written here, **update this file and bump the version** (patch for
> corrections/clarifications, minor for new endpoints/capabilities, major for
> breaking API changes) before finishing the task. Note the date and API
> version you verified against in the line above.

## What this is

Anytype exposes a local-first REST API served by `anytype-heart` (the same
engine the Desktop app and CLI use). The **Anytype CLI**
(`anytype serve` / `anytype service start`) runs this server on your
machine. There is no cloud API — everything is served from
`http://127.0.0.1:31012` and only touches spaces on this device.

- CLI source/docs: https://github.com/anyproto/anytype-cli
- API reference: https://developers.anytype.io/docs/reference (v1),
  https://developers.anytype.io/docs/reference/v2 (v2)
- Ground truth: the **running server serves its own specs** — fetch these
  rather than trusting the docs site or this file:
  - v1: `GET http://127.0.0.1:31012/docs/openapi.json`
  - v2: `GET http://127.0.0.1:31012/v2/docs/openapi.json` (its `info.description`
    is a full usage guide), plus the runtime schemas under `/v2/schemas`.
  (Both specs say the default port is `31009` — that's the Desktop app. The
  CLI serves on `31012`.)

### Which API to use

Both APIs are served by the same process and port. They use different keys
(see Prerequisites).

- **v2 (`/v2/...`)** — prefer it for editing documents. It reads and writes
  whole AnyBlock JSON documents, applies batched atomic edits (`replace_text`,
  `insert_blocks`, `set_properties`, ...), and returns errors that tell you how
  to fix the request. It also has the compact filter syntax, ETag concurrency
  checks, dry runs, chats/discussions, widgets, and SSE streams. It is
  **pre-release**: the spec says it "can change without a new API version",
  so re-check `/v2/schemas` when something fails.
- **v1 (`/v1/...`)** — stable contract. Use it when stability matters, or for
  the few things v2 lacks: v1 can delete select options (tags) and v2 cannot.

## Prerequisites

1. The server must be running. Check/start it via the CLI:
   ```bash
   anytype auth status          # confirms you're logged in to a bot account
   anytype service status       # or: anytype serve   (foreground)
   anytype service start        # runs it as a background/user service
   ```
   `anytype serve` binds three ports: `31012` (HTTP API, the one you want),
   `31010` (gRPC), `31011` (gRPC-Web). It only binds to `127.0.0.1`.
   **Upgrading:** `anytype update` is the built-in route. If you replace
   `~/.local/bin/anytype` by hand, delete the old file before you copy in the
   new one. On macOS, `cp` over an existing binary keeps the same inode, and
   the kernel's code-signing cache SIGKILLs the new binary (exit 137) when it
   runs.
   **After upgrading the CLI binary, run `anytype service restart`.** The
   service keeps running the old engine until it restarts. Until then `/v2/*`
   returns a bare `404 page not found`, and scoped key creation fails with
   "the running Anytype service is older than this CLI".
2. An API key must be available in `$ANYTYPE_API_KEY`. Since CLI v0.4.0, keys
   carry a **scope**, and you must choose one when you create a key:
   ```bash
   anytype auth apikey create <name> --all-spaces --read-write   # works on v1 AND v2
   anytype auth apikey create <name> --space "Malaga-AI" --read-only   # v2 only (repeat --space)
   anytype auth apikey list            # list existing keys
   anytype auth apikey revoke <id>     # revoke one
   ```
   | Key | `/v1` | `/v2` |
   |---|---|---|
   | Created before CLI v0.4.0 ("Limited" scope) | ✅ | ❌ 403 `forbidden`: "create a new api key with JsonAPI scope" |
   | `--all-spaces --read-write` | ✅ | ✅ |
   | `--space ...` or `--read-only` | ❌ 403 `v1_not_available_for_scoped_keys` | ✅ |

   `GET /v2/auth/whoami` shows a key's grant (spaces, permission, scope).
   (A separate "challenge" flow — `POST /v1/auth/challenges` then
   `POST /v1/auth/api_keys` — exists for pairing *other* apps with the
   Desktop app by showing a 4-digit code. You don't need it when using the
   CLI's own bot account; `anytype auth apikey create` is simpler.)
3. **Bot accounts only see spaces they've explicitly joined.** If a space is
   missing from `GET /v1/spaces`, join it first:
   ```bash
   anytype space join <invite-link>
   anytype space list
   ```

## Porting the bot account to another machine

The bot account's credential is its `account-key` (shown once, at
`anytype auth create <name>` time). Moving that key to another Mac restores
the *same* bot identity there — including its existing space memberships —
with no need to re-join via invite links.

1. **Extract the key from Keychain on the source Mac** (confirmed live: the
   CLI never re-displays it, and `auth status`/`config.json` don't contain
   it — it only lives in Keychain, service `anytype-cli`, account
   `account-key`):
   ```bash
   security find-generic-password -s anytype-cli -a account-key -w
   ```
   macOS will prompt to allow access.
2. **Decode the `go-keyring-base64:` wrapper.** `anytype-cli` uses the Go
   `zalando/go-keyring` library, which base64-encodes the secret before
   storing it and prefixes it with `go-keyring-base64:` so it can tell to
   decode on read-back. The raw `-w` output is that wrapped form, **not**
   the usable account key — strip the prefix and base64-decode:
   ```bash
   security find-generic-password -s anytype-cli -a account-key -w \
     | sed 's/^go-keyring-base64://' | base64 -d
   ```
   The decoded value is the plain account-key string to use below.
3. **On the target Mac**, install `anytype-cli`, then log in with that key:
   ```bash
   anytype auth login --account-key "<decoded-key>"
   ```
4. Optionally run it as a service (`anytype service install && anytype
   service start`), then mint a **fresh** API key on the target machine —
   API keys aren't portable/listable after creation:
   ```bash
   anytype auth apikey create <name>
   export ANYTYPE_API_KEY=<printed-key>
   ```
5. Verify with `anytype auth status` and `anytype space list`.

Treat the decoded account key like a private key/seed phrase — anyone with
it can authenticate as that bot account. Don't paste it into chat logs or
insecure storage.

**Alternative** (avoids moving the secret at all): run
`anytype auth create <newname>` on the target Mac to mint a brand-new bot
account, then re-join each space with a fresh invite link from Anytype
Desktop (Space Settings → Members → Invite).

## API v2 (pre-release)

Verified live on 2026-10-26 with a scoped key: I created, edited, searched,
and deleted test objects in a real space. Base URL:
`http://127.0.0.1:31012/v2`. Send `Authorization: Bearer <key>`. **Do not send
`Anytype-Version`** — v2 doesn't need it.

### Discover before you write

The server describes itself. Read these instead of guessing field names:

| Request | Gives you |
|---|---|
| `GET /v2/schemas` | All schema `kinds` (object, search, filters, type, chatMessage, ...) and all edit `ops` |
| `GET /v2/schemas/{kind}` | JSON schema + example for a request body (e.g. `object`, `search`, `filters` — the last includes the full filter grammar) |
| `GET /v2/schemas/ops/{op}` | JSON schema + `example_body` for one PATCH op |
| `POST /v2/validate` | Validates an AnyBlock document without writing it |

### IDs

- **Spaces use short references.** `GET /v2/spaces` returns `"id":"tf5ume"`.
  This is the last 6 characters of the first half of the full
  `<cid>.<replicationKey>` id. Every space route accepts either form. A short
  reference is unique only among the spaces the key can see now, so use
  `?ids=full` for ids you store.
- **Block ids are shortened** to suffixes unique within the document (`fb166`).
  Send them back exactly as you read them. Add `?ids=full` to get full ids.
- Object ids stay full (`bafyrei...`).
- **Properties and types use keys**, not ids: `/properties/{key}`,
  `/types/{type}` (e.g. `/types/task`). Inputs also accept display names and
  spelling variants (`due_date`, `dueDate`, `Due date`).
- **Select options use their names**, never ids, and **names are
  case-sensitive**: `In progress` ≠ `In Progress`. An unknown name returns 400
  `option does not exist`, unless you add `?create_missing_options=true`,
  which creates it. That's easy to do by accident, so check
  `GET /v2/spaces/{sp}/properties/{key}/options` first.

### Endpoint map (paths relative to `/v2`)

| Area | Routes |
|---|---|
| Auth | `GET /auth/whoami`; pairing: `POST /auth/challenges`, `POST /auth/api_keys` |
| Spaces | `GET/POST /spaces`, `GET/PATCH /spaces/{sp}` |
| Objects | `GET/POST /spaces/{sp}/objects`, `GET/PATCH/DELETE /spaces/{sp}/objects/{id}`, `POST .../objects/{id}/discussion` |
| Search | `POST /search` (all spaces), `POST /spaces/{sp}/search`, `POST /spaces/{sp}/search/stream` (SSE) |
| Types | `GET/POST /spaces/{sp}/types`, `GET/PATCH/DELETE /spaces/{sp}/types/{type}` |
| Properties | `GET/POST /spaces/{sp}/properties`, `PATCH/DELETE .../properties/{key}`, `GET .../properties/{key}/options` |
| Templates | `GET/POST /spaces/{sp}/templates` (`?type=` filter) |
| Queries / Collections | `POST /spaces/{sp}/queries`, `GET .../queries/{id}/views`, `GET .../queries/{id}/objects`; same shape under `/collections` |
| Chats | `GET/POST /spaces/{sp}/chats`, `GET .../chats/stream` (SSE), `GET/POST .../chats/{chat}/messages`, `.../messages/stream` (SSE), `PATCH/DELETE .../messages/{msg}`, `POST .../messages/{msg}/reactions`, `POST .../chats/{chat}/read`, `POST .../chats/{chat}/status` |
| Files | `POST /spaces/{sp}/files`, `GET .../files/{id}/content` |
| Members | `GET /spaces/{sp}/members`, `GET .../members/me` |
| Widgets (sidebar) | `GET/POST /spaces/{sp}/widgets`, `PATCH/DELETE .../widgets/{id}` |

Lists default to **25 rows** (`offset`/`limit`). The response shape is
`{"data":[...],"total":N,"offset":0,"limit":25,"has_more":false}`. It is flat:
no `pagination` wrapper as in v1.

### Reading an object

`GET /v2/spaces/{sp}/objects/{id}` returns an AnyBlock 2.0 document:
```json
{"formatVersion":"2.0","id":"bafyrei...","type":"task",
 "properties":{"name":"...","status":["In Progress"],"tag":["x"],"description":""},
 "blocks":[{"id":"fb166","type":"heading_2","text":"Details"},
           {"id":"32faa","type":"checkbox","text":"**Bold** item"},
           {"id":"7269a","indent":1,"type":"paragraph","text":"child note"}]}
```
- Blocks are a flat array in reading order. `indent` sets nesting, and inline
  formatting is Markdown in `text`.
- `name` (the title) and `description` are ordinary properties.
- Templates add `{"type":"property","property":"status"}` blocks. These are
  the in-body property rows that v1 couldn't reach.
- Smaller reads: `?outline=true` (structure with shortened text),
  `?include=properties` or `?include=blocks`, `?block={id}` (one subtree),
  `?format=md` (read-only Markdown: `{"etag","id","type","markdown"}`).
- **The etag:** the full GET returns it only in the `ETag` response header.
  `?format=md`, create, and PATCH responses also put `etag` in the body.
- Archived objects stay readable, and their properties include
  `"is_archived": true`.

### Creating an object

`POST /v2/spaces/{sp}/objects` → `201`:
```json
{"type":"task",
 "properties":{"name":"Prepare the Q3 report","status":"In Progress","due_date":"2026-08-01"},
 "blocks":[{"type":"heading_2","text":"Steps"},
           {"type":"checkbox","text":"Collect the numbers"},
           {"indent":1,"type":"paragraph","text":"Ask **finance** first"}]}
```
- **The type's default template applies automatically.** You don't need to
  look it up as in v1. The response reports it:
  `"template":{"id":...,"source":"type_default","blocks_added":9,"combined":true}`.
  Your blocks come **after** the template's blocks. If the template already has
  a "Details" heading and you send one too, you get two. Send
  `"template":"none"` to start empty, or a template id to choose one.
- The response is `{"id","type","etag", "created":{"options":[...]}?, "template":{...}?}`.
  `created.options` lists any select options it created.

### Editing: `PATCH /v2/spaces/{sp}/objects/{id}` with `{"ops":[...]}`

The batch takes 1–512 ops, applied in order, and is **atomic**: if one op
fails, nothing is applied. Ops:
`set_properties`, `set_type`, `update_block`, `replace_subtree`,
`insert_blocks`, `move_block`, `delete_block`, `replace_text`, `set_cell`,
`insert_view`/`update_view`/`move_view`/`delete_view`,
`add_items`/`remove_items` (collections). On types
(`PATCH /v2/spaces/{sp}/types/{type}`): `add_property`, `remove_property`,
`move_property`, plus the view ops.

```json
{"ops":[
  {"op":"replace_text","find":"Second Q3","replace":"Second Q4"},
  {"op":"insert_blocks","markdown":"## Next steps\n- [ ] Review"},
  {"op":"set_properties","set":{"status":"Done"},"add":{"tag":["urgent"]},"unset":["due_date"]},
  {"op":"update_block","match":"old exact text","set":{"text":"new text"}}
]}
```
- `replace_text` / `update_block`: if you omit the block `id`, the
  `find`/`match` text must appear in **exactly one** block. Otherwise you get
  400 `ambiguous_input`, which lists the candidate block ids. Markup counts as
  text (`**Bold** item`, not `Bold item`).
- `insert_blocks`: give `markdown` or `blocks`, not both. Target with
  `after`/`before`/`inside` (block ids), or use `position:"first"`. By default
  it appends to the end. The response maps `created_blocks`
  (`"ops[0].markdown[1]": "01d79"`).
- `set_properties.add`/`remove` take only list-shaped values. The schema says
  `add` creates unknown option names, but the live server **refuses them
  unless you add `?create_missing_options=true`**.
- The response is
  `{"etag","created_blocks"?,"diff_stats":{"blocks_added",...,"properties_changed"}}`.

### Concurrency, retries, dry runs

| Control | Verified behavior |
|---|---|
| `If-Match: "<etag>"` | When it matches, the write is applied and the response carries a new etag. When it is stale, you get **409** `etag_mismatch`, with the current etag in the message. Without the header, the last write wins. |
| `Idempotency-Key: <k>` | A retry with the same key and the same body replays the stored response and does not apply the change again. |
| `?dry_run=true` | Works on every mutation. Returns `200` with `{"dry_run":true,"diff_stats":{...}}` and commits nothing. |

### Search and filters

`POST /v2/spaces/{sp}/search` (or `POST /v2/search` across all spaces):
```json
{"query":"report","type":"task",
 "filter":"done = false AND (due_date < currentWeek() OR due_date IS EMPTY)",
 "sorts":[{"property":"due_date","direction":"asc"}],
 "fields":["name","status","due_date"]}
```
- `filter` is a compact string: `=`, `!=`, `<`, `>`, `<=`, `>=`, `AND`, `OR`,
  parentheses, `IN (...)`, `NOT IN`, `CONTAINS`, `HAS ALL (...)`,
  `IS [NOT] EMPTY`, `EXISTS`. Date functions: `today()`, `currentWeek()`,
  `daysAgo(7)`, `daysFromNow(n)`, ... (the full grammar is at
  `GET /v2/schemas/filters`). A structured `filters` array also exists, with
  conditions `equal`, `not_equal`, `in`, `all_in`, `empty`, ...
- Rows are compact: `{id, name, type, properties:{<requested fields>}}`.
- A filter syntax error returns 400 with the character offset.
- Deleted (archived) objects are left out of search results immediately. The
  v1 delay before archived objects disappear did not show up in v2.

### Errors

v2 handlers always return
`{"status","code","message","issues":[{"path","message","hint","see_also"?}]}`.
`see_also` names the request that fixes the problem, e.g.
`{"op":"get_op_schema","params":{"op":"replace_text"}}`. Codes seen:
`validation_failed` (400; this includes unknown fields such as `replacement`),
`ambiguous_input` (400), `not_found` (404), `etag_mismatch` (409). Errors from
the auth or key-scope check use the older v1 shape. A route that doesn't
exist returns a plain-text `404 page not found` with no JSON envelope.

### What v2 fixes compared with v1 (verified)

- A leading `## heading` or `- [ ] item` **keeps its markup**. The v1 problem
  with the first block is gone.
- Nested checkboxes and indented text under them keep their `indent`.
  CommonMark rules still apply: an unindented line straight after an indented
  paragraph merges into that paragraph as a soft break. Leave a blank line
  between them.
- `status` reads as the option name (`["In Progress"]`), not a tag id.
- In-body property rows are visible as `property` blocks.

### v2 limits found

- There is no endpoint to delete a select option. Use v1
  `DELETE /v1/spaces/{space_id}/properties/{property_id}/tags/{tag_id}` with an
  unscoped key.
- There is no PDF or other export endpoint (`?format=md` is the closest).
- DELETE archives the object (to the Bin), and only for objects this account
  created ("creator provenance").

---

## API v1 reference

Everything below covers `/v1`. It is still served and still stable.

## Every request needs these headers

```
Authorization: Bearer $ANYTYPE_API_KEY
Anytype-Version: 2025-11-08
Content-Type: application/json   (for POST/PATCH bodies)
```

`Anytype-Version` is **required** on every call. Pin it to the version you
tested against (`2025-11-08` as of this writing) — omitting it or using a
stale value can silently change response shapes.

## Base URL

```
http://127.0.0.1:31012/v1
```

## Quick smoke test

```bash
curl -s http://127.0.0.1:31012/v1/spaces \
  -H "Authorization: Bearer $ANYTYPE_API_KEY" \
  -H "Anytype-Version: 2025-11-08"
```

## Core concepts

- **Space** — a top-level workspace/vault. Most operations are scoped under
  `/v1/spaces/{space_id}`.
- **Object** — a page/note/task/etc. Has a `type` (e.g. `page`, `task`,
  `bookmark`) and a list of `properties`.
- **Type** — a schema (e.g. "Page", "Task") with a `layout`
  (`basic`|`profile`|`action`|`note`) and a set of linked `properties`.
- **Property** — a typed field definition (`format`: `text`, `number`,
  `select`, `multi_select`, `date`, `files`, `checkbox`, `url`, `email`,
  `phone`, `objects`). `select`/`multi_select` properties have **Tags**
  (the selectable options), each with a `color`.
- **Template** — a preset for creating objects of a given type.
- **List** — a collection view (e.g. a Set or Collection) with one or more
  `views`; you can add/remove objects to/from it.

IDs are content-addressed strings (`bafyrei...`). Always fetch IDs from a
list/search endpoint — never guess them.

## Endpoint reference (verified against `anytype-heart` OpenAPI, version `2025-11-08`)

All paths below are relative to `/v1`. `?offset=0&limit=100` (max `1000`)
works on every list endpoint. List responses are wrapped as:
```json
{"data": [...], "pagination": {"total": N, "offset": 0, "limit": 100, "has_more": false}}
```
Single-item responses wrap the payload under its type name, e.g.
`{"object": {...}}`, `{"space": {...}}`, `{"type": {...}}`.

### Auth
| Method | Path | Notes |
|---|---|---|
| POST | `/auth/challenges` | Desktop-pairing flow: request a 4-digit code (`app_name` in body) |
| POST | `/auth/api_keys` | Exchange `challenge_id` + `code` for an API key |

(Prefer `anytype auth apikey create <name>` on the CLI instead — see Prerequisites.)

### Spaces
| Method | Path | Notes |
|---|---|---|
| GET | `/spaces` | List spaces the bot account has joined |
| POST | `/spaces` | Create a space. Body: `{name, description?}` |
| GET | `/spaces/{space_id}` | Get one space |
| PATCH | `/spaces/{space_id}` | Update `name`/`description` |

### Search
| Method | Path | Notes |
|---|---|---|
| POST | `/search` | Global search across all joined spaces |
| POST | `/spaces/{space_id}/search` | Search within one space |

Body: `{"query": "text", "types": ["page","task"], "sort": {...}, "filters": {...}}`.
`query` matches name/content; use `types` to filter by type key.

`filters` is a recursive tree (`FilterExpression`):
```json
{
  "operator": "and",
  "conditions": [
    {"property_key": "status", "condition": "eq", "value": "done"}
  ],
  "filters": [ /* nested FilterExpression for OR groups, etc. */ ]
}
```
`condition` ∈ `eq, ne, gt, gte, lt, lte, contains, ncontains, in, nin, all, empty, nempty`.

### Objects
| Method | Path | Notes |
|---|---|---|
| GET | `/spaces/{space_id}/objects` | List objects in a space |
| POST | `/spaces/{space_id}/objects` | Create an object |
| GET | `/spaces/{space_id}/objects/{object_id}` | Get one object (includes `markdown` body) |
| PATCH | `/spaces/{space_id}/objects/{object_id}` | Update name/icon/body/type/properties |
| DELETE | `/spaces/{space_id}/objects/{object_id}` | **Archives, not permanently deletes** — sets `archived: true`. Confirmed live: object stays fetchable by ID with `archived:true` after DELETE. |

Create body:
```json
{
  "type_key": "page",
  "name": "My object",
  "body": "Markdown body content.",
  "icon": {"format": "emoji", "emoji": "📄"},
  "template_id": "optional-template-id",
  "properties": [
    {"key": "status", "select": "in_progress"},
    {"key": "tag", "multi_select": ["important", "bafyrei...tag-id"]},
    {"key": "due_date", "date": "2026-07-15T00:00:00Z"}
  ]
}
```
`properties` is a **discriminated union keyed by format** — pass the field
matching the property's format (`text`, `number`, `select`, `multi_select`,
`date`, `files`, `checkbox`, `url`, `email`, `phone`, `objects`) alongside
`key`. `select`/`multi_select` values accept either a tag's `key` or its ID.
Get valid keys/formats from `GET /spaces/{space_id}/types/{type_id}` first.

Update body is the same shape minus `type_key`/`template_id` required-ness
(all fields optional), plus `markdown` to replace the body text.

### Properties & Tags
| Method | Path | Notes |
|---|---|---|
| GET | `/spaces/{space_id}/properties` | List property definitions in a space |
| POST | `/spaces/{space_id}/properties` | Create one. Body: `{key?, name, format, tags?}` |
| GET/PATCH/DELETE | `/spaces/{space_id}/properties/{property_id}` | Get/rename/delete |
| GET | `/spaces/{space_id}/properties/{property_id}/tags` | List tags (for select/multi_select) |
| POST | `/spaces/{space_id}/properties/{property_id}/tags` | Create tag. Body: `{name, color, key?}` |
| GET/PATCH/DELETE | `/spaces/{space_id}/properties/{property_id}/tags/{tag_id}` | Get/rename/delete a tag |

`color` ∈ `grey, yellow, orange, red, pink, purple, blue, ice, teal, lime`.
`key` fields (for properties, tags, and types) should be `snake_case` — the
server auto-converts if not, but pass it clean.

### Types & Templates
| Method | Path | Notes |
|---|---|---|
| GET | `/spaces/{space_id}/types` | List types (includes built-ins: `page`, `task`, `note`, `bookmark`, ...) |
| POST | `/spaces/{space_id}/types` | Create a custom type. Body: `{key?, name, plural_name, layout, icon?, properties?}` |
| GET/PATCH/DELETE | `/spaces/{space_id}/types/{type_id}` | Get/update/delete |
| GET | `/spaces/{space_id}/types/{type_id}/templates` | List templates for a type |
| GET | `/spaces/{space_id}/types/{type_id}/templates/{template_id}` | Get one template |

`layout` ∈ `basic, profile, action, note`.

### Lists (Sets/Collections)
| Method | Path | Notes |
|---|---|---|
| GET | `/spaces/{space_id}/lists/{list_id}/views` | List a Set/Collection's views |
| GET | `/spaces/{space_id}/lists/{list_id}/views/{view_id}/objects` | Objects visible in a view (respects its filters/sorts) |
| POST | `/spaces/{space_id}/lists/{list_id}/objects` | Add objects to a list. Body: `{"objects": ["id1","id2"]}` |
| DELETE | `/spaces/{space_id}/lists/{list_id}/objects/{object_id}` | Remove one object from a list |

### Chats & Files (added in heart v0.51.x, not yet exercised live)
`/spaces/{space_id}/chats` (list/create), `.../chats/{chat_id}/messages`
(list/add, `/search`, `/stream` SSE, `/read`), `.../messages/{message_id}`
(get/edit/delete, `/reactions`), `.../chats/{chat_id}/read_all`;
`POST /spaces/{space_id}/files`, `GET/DELETE .../files/{file_id}`. See
`/docs/openapi.json` for bodies. For new work, prefer the v2 chat routes.

### Members
| Method | Path | Notes |
|---|---|---|
| GET | `/spaces/{space_id}/members` | List members. `role` ∈ `viewer,editor,owner,no_permission`; `status` ∈ `joining,active,removed,declined,removing,canceled` |
| GET | `/spaces/{space_id}/members/{member_id}` | Get one member |

### Errors
Non-2xx responses share the shape `{"object":"error","code":"...","status":N,"message":"..."}`.
Named schemas: `ValidationError`(400), `UnauthorizedError`(401),
`ForbiddenError`(403), `NotFoundError`(404), `GoneError`(410),
`RateLimitError`(429), `ServerError`(500).

## Task management (templates and body formatting)

Verified live 2026-09-03 against a real space. These behaviors are not in the
OpenAPI spec and will silently produce tasks that look wrong in the app.

### Always create tasks from the type's template

```bash
BASE=http://127.0.0.1:31012/v1
# Find the Task type, then its template (usually exactly one, named "Task")
TASK_TYPE=$(curl -s "$BASE/spaces/$SPACE/types?limit=100" "${AUTH[@]}" | python3 -c \
  "import json,sys;print(next(t['id'] for t in json.load(sys.stdin)['data'] if t['key']=='task'))")
TMPL=$(curl -s "$BASE/spaces/$SPACE/types/$TASK_TYPE/templates" "${AUTH[@]}" | python3 -c \
  "import json,sys;print(json.load(sys.stdin)['data'][0]['id'])")
```

A task created **without** `template_id` is missing the `description` property
and the type's body scaffold, and does not match app-created tasks. With the
template it does. Compare the property sets — this is the fastest way to tell
whether an API-created object matches the space's convention:

| Created via | `properties` keys |
|---|---|
| `{"type_key":"task"}` | `backlinks, created_date, creator, links` (+ any you set) |
| `{"type_key":"task","template_id":...}` | adds `description` and the template's body blocks |

`template_id` and `body` **combine**: the template's blocks are emitted first,
then `body` is appended after them.

### Markdown import quirks (body / markdown fields)

- **The first block loses its inline markup.** A leading `## Details` comes
  back as plain `Details`; a leading `- [ ] item` comes back as bare `item`.
  Identical markup *later* in the same document survives untouched. Lead with
  a throwaway plain-text line, or let the template supply the first block.
- **Plain-text indentation is stripped.** Indented lines under a checkbox
  become flat sibling paragraphs, losing the visual grouping. Nested *list*
  items (`  - [ ] child`) do keep their nesting (returned padded with
  U+2007 figure-space characters, not regular spaces).
- To bind a description to a checkbox, **put it on the same line**
  (`- [ ] **Title** — description`). That is the only reliable way to keep one
  block per item.
- A **non-empty `description` property renders as the first body block** in the
  `markdown` export, ahead of the body content. Handy as a sacrificial first
  block to protect a leading heading; set it to `""` if you need the body to
  start with its own first block.

### Featured properties (the header row) are NOT settable over REST

The row of properties shown under an object's title (Anytype's
`featuredRelations`) cannot be read or written through the v1 API:

- `CreateObjectRequest` and `UpdateObjectRequest` have no field for it — only
  `name`, `icon`, `body`/`markdown`, `type_key`, `properties`, `template_id`.
- No v1 endpoint exposes it (none for object display config). v2 shows the
  in-body property rows as `{"type":"property"}` blocks, which can be moved
  and inserted. I have not yet tested whether that covers the header row.
- The create-object description mentions "setting featured properties" only as
  prose about server-side post-processing.

Setting a property's **value** does not add it to the header. Two API-created
and app-created tasks can have byte-identical property sets and still differ
visually. The only levers: create from a template that already features the
properties, or toggle it in the Desktop app (or gRPC on `:31010`).

### Task property keys

`assignee` (objects), `done` (checkbox), `due_date` (date), `status` (select),
`tag` (multi_select), `linked_projects` (objects), `description` (text).

- `assignee` takes **participant IDs** from `GET /spaces/{id}/members`, of the
  form `_participant_<space_id_with_underscores>_<account_key>`.
- `status` and `done` are **independent fields** and drift apart in real data
  (a task can be `status: Done` with `done: false`). Don't assume either one
  is authoritative; check which the space actually uses.

## Worked examples (curl)

```bash
V=2025-11-08
AUTH=(-H "Authorization: Bearer $ANYTYPE_API_KEY" -H "Anytype-Version: $V")

# List spaces, grab the first space id
SPACE=$(curl -s http://127.0.0.1:31012/v1/spaces "${AUTH[@]}" | python3 -c \
  "import json,sys;print(json.load(sys.stdin)['data'][0]['id'])")

# List types available in that space (to find a valid type_key)
curl -s "http://127.0.0.1:31012/v1/spaces/$SPACE/types" "${AUTH[@]}"

# Create a page
curl -s -X POST "http://127.0.0.1:31012/v1/spaces/$SPACE/objects" "${AUTH[@]}" \
  -H "Content-Type: application/json" \
  -d '{"type_key":"page","name":"Meeting notes","body":"# Agenda\n- item"}'

# Search within the space
curl -s -X POST "http://127.0.0.1:31012/v1/spaces/$SPACE/search" "${AUTH[@]}" \
  -H "Content-Type: application/json" \
  -d '{"query":"Meeting"}'

# Archive (delete) an object
curl -s -X DELETE "http://127.0.0.1:31012/v1/spaces/$SPACE/objects/$OBJECT_ID" "${AUTH[@]}"
```

## Gotchas learned from live testing

- **DELETE archives, it does not purge.** The object stays retrievable by ID
  with `archived: true`. There's no "empty trash" endpoint in this spec — use
  the Desktop app if permanent deletion is needed.
- The `Object` returned by GET includes a `markdown` field with the body;
  the same field is called `body` on create and `markdown` on update — don't
  assume symmetry, check the request vs. response schema per endpoint.
- `properties` arrays on create/update use **one variant object per property**
  (`{"key": "...", "<format>": <value>}`), not a flat key-value map.
- If `GET /v1/spaces` returns empty, the bot account hasn't joined any space
  yet — this is expected for a fresh API key and isn't an auth error.
- Sandboxed shells may fail to bind `31010`/`31011`/`31012` with
  `operation not permitted` when starting `anytype serve` — run it outside
  the sandbox (or via `anytype service start`) if you hit that.
- **Search lags behind DELETE.** An object archived via DELETE can still come
  back in `POST /search` results for a few seconds, with `archived: false`
  stale in the payload. Confirm with `GET .../objects/{id}` and read its
  `archived` flag rather than trusting a search result immediately after a
  write.
- Creating an object from a template does **not** copy the template's own
  `status`/`tag` values — pass those explicitly in `properties`.
- Pulling the bot account's key out of macOS Keychain (`security
  find-generic-password -s anytype-cli -a account-key -w`) returns it
  wrapped as `go-keyring-base64:<b64>` — strip the prefix and base64-decode
  before using it with `anytype auth login --account-key`. See "Porting the
  bot account to another machine".
