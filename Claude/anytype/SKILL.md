---
name: anytype
version: 1.3.0
description: Use the local Anytype HTTP API (via the Anytype CLI / anytype-heart server on 127.0.0.1:31012) to manage spaces, objects, properties, types, tags, and search. Use when the user wants to read, create, or update Anytype content programmatically.
user-invocable: true
allowed-tools: Bash, Read
---

# Anytype API

> **Skill version: 1.3.0** — last verified against a live server on **2026-09-03**
> (`anytype-cli v0.3.6`, API version `2025-11-08`).
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
- API reference: https://developers.anytype.io/docs/reference
- Full OpenAPI spec (ground truth, more reliable than the docs site):
  `https://raw.githubusercontent.com/anyproto/anytype-heart/main/core/api/docs/openapi.json`

## Prerequisites

1. The server must be running. Check/start it via the CLI:
   ```bash
   anytype auth status          # confirms you're logged in to a bot account
   anytype service status       # or: anytype serve   (foreground)
   anytype service start        # runs it as a background/user service
   ```
   `anytype serve` binds three ports: `31012` (HTTP API, the one you want),
   `31010` (gRPC), `31011` (gRPC-Web). It only binds to `127.0.0.1`.
2. An API key must be available in `$ANYTYPE_API_KEY`. If you don't have one:
   ```bash
   anytype auth apikey create <name>   # prints a new key for the logged-in bot account
   anytype auth apikey list            # list existing keys
   anytype auth apikey revoke <id>     # revoke one
   ```
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
- No endpoint exposes it (22 paths total; none for object display config).
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
