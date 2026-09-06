---
name: eventbrite
version: 1.0.0
description: Use the Eventbrite v3 REST API (via the private token in $EVENTBRITE_API_KEY) to read and manage events, ticket classes, attendees, orders, venues, and webhooks. Use when the user wants to look up, create, or update Eventbrite events/tickets/attendees/orders programmatically.
user-invocable: true
allowed-tools: Bash
---

# Eventbrite API

> **Skill version: 1.2.0** — last verified against a live account on **2026-07-01**
> (API `v3`, base `https://www.eventbriteapi.com/v3/`).
>
> **Keep this in sync.** Whenever you discover a new endpoint, a changed
> response shape, a new deprecation, or any behavior that contradicts what's
> written here, **update this file and bump the version** (patch for
> corrections/clarifications, minor for new endpoints/capabilities, major for
> breaking API changes) before finishing the task. Note the date you verified
> against in the line above. Eventbrite's own docs portal
> (`eventbrite.com/platform/docs/*`) is a JS-rendered SPA that most fetch
> tools can't scrape — prefer live-testing an endpoint with curl over trying
> to re-read the docs site, and prefer the legacy static mirror at
> `eventbrite.com/developer/v3/...` when you do need prose docs.

## What this is

Eventbrite exposes a single evergreen REST API, **v3** (no v4; the older v1
API was shut off in 2015). It's organized around **Organizations** (a
workspace with one Owner and optional Members/roles) that own Events, which
in turn own Ticket Classes, Attendees, and Orders.

- API landing page: https://www.eventbrite.com/platform/api
- Docs hub (JS-rendered, hard to scrape): https://www.eventbrite.com/platform/docs
- Legacy static docs (still resolves, useful for prose): https://www.eventbrite.com/developer/v3/
- Manage/create OAuth apps & private tokens: https://www.eventbrite.com/account-settings/apps

## Prerequisites

An API key/private token must be available in `$EVENTBRITE_API_KEY`. This is
a long-lived personal OAuth token tied to one Eventbrite account — no OAuth
dance needed for single-account use. (A full Authorization Code flow exists
for acting on behalf of *other* users — authorize at
`https://www.eventbrite.com/oauth/authorize`, exchange at
`https://www.eventbrite.com/oauth/token` with `client_id`/`client_secret` —
but you don't need it for this skill.)

There are **no granular OAuth scopes**. What the token can see/do is
entirely determined by the token owner's **role in each Organization**
(Owner, Admin, Check-in, ...) — permissions are per-org, not per-request.

## Every request needs this header

```
Authorization: Bearer $EVENTBRITE_API_KEY
Content-Type: application/json   (for POST bodies)
```

## Base URL

```
https://www.eventbriteapi.com/v3
```

## Quick smoke test

```bash
curl -s -H "Authorization: Bearer $EVENTBRITE_API_KEY" \
  "https://www.eventbriteapi.com/v3/users/me/"
```

## Core concepts

- **User** — the token owner. `GET /users/me/` returns their profile.
- **Organization** — a workspace owning Events/Venues/Members. Get yours via
  `GET /users/me/organizations/` — almost everything else is scoped under
  `/organizations/{organization_id}/...` or `/events/{event_id}/...`.
- **Event** — has `name`, `start`/`end` (timezone-triple objects), `status`
  (`draft`|`live`|`started`|`ended`|`completed`|`canceled`, etc.), `currency`,
  a `category_id`/`subcategory_id`/`format_id`, and a `venue_id`.
- **Ticket Class** — a ticket type on an event (price, quantity, on-sale
  window). Non-free/non-donation ticket classes **require a `cost`**.
- **Attendee** — one registration (possibly for `quantity` > 1 seats) on an
  event, with a `profile` (name/email) and `barcodes`.
- **Order** — one checkout transaction, linking a buyer to one or more
  attendees on an event.
- **Venue** — a physical location, owned by an Organization, reusable across
  events.

IDs are numeric strings (e.g. `"834787671397"`). Fetch them from a
list/search endpoint or the Eventbrite web UI URL — don't guess.

## Request/response conventions

**Pagination** — list responses wrap the array in a `pagination` object:
```json
{
  "pagination": {
    "object_count": 65, "page_number": 1, "page_size": 50,
    "page_count": 2, "has_more_items": true, "continuation": "eyJwYWdlIjogMn0"
  },
  "attendees": [ ... ]
}
```
Page with `?continuation=<token>` (preferred for deep pagination) or
`?page=N`.

**Expansions** — `?expand=venue,ticket_classes,organizer` inlines related
objects on a `GET` instead of requiring separate calls. Verified expansions:
`venue`, `organizer`, `ticket_classes`, `ticket_availability`, `category`,
`subcategory`, `format`.

**Date/time** — every date field is a triple:
```json
"start": {"timezone": "Europe/Madrid", "local": "2024-03-07T18:00:00", "utc": "2024-03-07T17:00:00Z"}
```

**Money** — every cost field is a multi-representation object:
```json
{"display": "$0.00", "currency": "USD", "value": 0, "major_value": "0.00"}
```
`value` is in minor units (cents), `major_value` a decimal string.

## Rate limits

Exposed via a response header (not documented on the current site, but
observed live) — no need to guess, just read it:
```
x-rate-limit: token:<your-token> 3/2000 reset=3594s
```
`used/limit reset=<seconds until window resets>`. Exceeding it returns
HTTP 429 with `{"error":"HIT_RATE_LIMIT", ...}`. Limits are per-token, not
per-IP, and Eventbrite states they're subject to change — read the live
header rather than hardcoding a number.

## Errors

Every non-2xx response has this shape:
```json
{"status_code": 404, "error": "NOT_FOUND", "error_description": "The event you requested does not exist."}
```
Validation failures (`ARGUMENTS_ERROR`) add a per-field `error_detail`:
```json
{"status_code": 400, "error": "ARGUMENTS_ERROR",
 "error_description": "There are errors with your arguments: scope - MISSING",
 "error_detail": {"ARGUMENTS_ERROR": {"scope": ["MISSING"]}}}
```
Observed codes: `NO_AUTH`(401, missing token), `INVALID_AUTH`(400, bad
token), `NOT_AUTHORIZED`(403), `NOT_FOUND`(404), `ARGUMENTS_ERROR`(400),
`HIT_RATE_LIMIT`(429), `INTERNAL_ERROR`(500).

## Endpoint reference (verified live against a real account, 2026-07-01)

All paths relative to `/v3`. Trailing slashes are required.

### Current user
| Method | Path | Notes |
|---|---|---|
| GET | `/users/me/` | Authenticated user's profile |
| GET | `/users/me/organizations/` | Organizations this token belongs to |
| GET | `/users/me/orders/` | Orders *placed by* this user (as a buyer) |

`GET /users/me/owned_events/` **does not work with a private token** (404s
`"The user_id you requested does not exist."`) — it was effectively replaced
by the Organizations model in 2020. Use the org-scoped events endpoint below
instead.

### Organizations
| Method | Path | Notes |
|---|---|---|
| GET | `/organizations/{organization_id}/events/` | List events owned by the org. `?status=all` to include drafts/past/canceled (default is live/upcoming only) |
| POST | `/organizations/{organization_id}/events/` | Create an event |
| GET | `/organizations/{organization_id}/orders/` | Orders across every event in the org |
| GET | `/organizations/{organization_id}/venues/` | List venues |
| POST | `/organizations/{organization_id}/venues/` | Create a venue |
| GET/POST | `/organizations/{organization_id}/webhooks/` | List / create webhooks |
| GET/POST | `/organizations/{organization_id}/discounts/?scope=event&event_id={id}` | List / create discounts (see Discounts below) |

### Events
| Method | Path | Notes |
|---|---|---|
| GET | `/events/{event_id}/` | Get one event. `?expand=venue,ticket_classes,organizer` is very useful |
| POST | `/events/{event_id}/` | Update event fields (partial update via POST, not PATCH) |
| POST | `/events/{event_id}/copy/` | **Duplicate an event as a new draft** — undocumented on the public docs site but confirmed live and working. See "Copying an event" below — this is the recommended way to spin up a recurring-series event (e.g. next month's meetup) instead of building one from scratch with `POST /organizations/{organization_id}/events/`. |
| POST | `/events/{event_id}/publish/` | Publish |
| POST | `/events/{event_id}/unpublish/` | Unpublish |
| POST | `/events/{event_id}/cancel/` | Cancel |
| DELETE | `/events/{event_id}/` | Delete (only while still a draft) |
| GET | `/venues/{venue_id}/events/` | Events at a venue |

#### Copying an event (recommended for recurring events)

`POST /events/{event_id}/copy/` with an empty `{}` body clones the source
event into a **new draft** (confirmed live, 2026-07-01). This is far better
than rebuilding an event from scratch via the org-scoped create endpoint,
because it carries over the things the plain create endpoint can't set:

- **The cover image** (`logo_id`/`logo` — copied by reference, still
  resolves to the same CDN URL). This is the only known way to get an image
  onto an event through this API, since direct image upload is broken (see
  Gotchas below).
- **The rich "structured content" listing body** (the multi-module,
  emoji-formatted description an organizer builds in the web UI) — copied
  as-is into the new draft's `structured_content`, even though that same
  content is *read-only* once copied (see Gotchas).
- **Ticket classes** — copied with `quantity_sold` reset to 0, but
  `sales_start`/`sales_end` and the ticket class ID's association with the
  *old* dates are NOT auto-shifted — update them explicitly after copying.

After copying, update at minimum: `name`, `start`/`end` (via
`POST /events/{event_id}/`), and each ticket class's `sales_start`/
`sales_end` (via `POST /events/{event_id}/ticket_classes/{id}/`) to match
the new date. The event stays `status: draft` throughout — copying does not
publish it, and the source event is completely unaffected by the copy.

**Known limitation:** the copied rich structured-content module still
contains the *source* event's date/month text (e.g. copying a "June" event's
description into a new "August" draft leaves literal "June" mentions inside
the rich body) — because that module can't be edited via API (see Gotchas).
Plan for a short manual pass in the web UI to fix date mentions inside the
rich description body; everything else (name, dates, ticket ids, cover
image) is fully API-editable.

Create body (all of these are required — confirmed via a live `400
ARGUMENTS_ERROR`):
```json
{
  "event": {
    "name": {"html": "My Event"},
    "start": {"timezone": "Europe/Madrid", "utc": "2026-09-01T17:00:00Z"},
    "end":   {"timezone": "Europe/Madrid", "utc": "2026-09-01T19:00:00Z"},
    "currency": "EUR"
  }
}
```

### Ticket classes
| Method | Path | Notes |
|---|---|---|
| GET | `/events/{event_id}/ticket_classes/` | List |
| GET | `/events/{event_id}/ticket_classes/{ticket_class_id}/` | Get one |
| POST | `/events/{event_id}/ticket_classes/` | Create. Non-free/non-donation classes need `cost` (confirmed live: `{"ticket_class":{"name":"General","quantity_total":100,"cost":"USD,1000"}}` — `cost` is `"<currency>,<minor units>"` and **must match the event's own `currency`**, else `CURRENCY_MISMATCH`) or set `"free": true` / `"donation": true` |
| POST | `/events/{event_id}/ticket_classes/{ticket_class_id}/` | Update |
| DELETE | `/events/{event_id}/ticket_classes/{ticket_class_id}/` | Delete |

### Attendees
| Method | Path | Notes |
|---|---|---|
| GET | `/events/{event_id}/attendees/` | List (paginated, default page size 50) |
| GET | `/events/{event_id}/attendees/{attendee_id}/` | Get one |

### Orders
| Method | Path | Notes |
|---|---|---|
| GET | `/events/{event_id}/orders/` | Orders for one event |
| GET | `/organizations/{organization_id}/orders/` | Orders across the org |
| GET | `/orders/{order_id}/` | Get one order |
| GET | `/users/me/orders/` | Orders you placed as a buyer |

Orders are private: visible only to the buyer or a member of the owning
Organization.

### Venues
| Method | Path | Notes |
|---|---|---|
| GET | `/venues/{venue_id}/` | Get one |
| POST | `/venues/{venue_id}/` | Update |
| GET | `/organizations/{organization_id}/venues/` | List (see Organizations) |
| POST | `/organizations/{organization_id}/venues/` | Create (see Organizations) |

### Taxonomy (categories / subcategories / formats)
| Method | Path | Notes |
|---|---|---|
| GET | `/categories/` | Global list, e.g. `{"id":"103","name":"Music",...}` |
| GET | `/categories/{id}/` | One category |
| GET | `/subcategories/` | Global list; each has a `parent_category` |
| GET | `/subcategories/{id}/` | One subcategory |
| GET | `/formats/` | Global list, e.g. `{"id":"1","name":"Conference"}` |

These are global lookups, not scoped to a token/org — use them to resolve
`category_id`/`subcategory_id`/`format_id` on an event.

### Discounts & access codes
| Method | Path | Notes |
|---|---|---|
| GET/POST | `/organizations/{organization_id}/discounts/?scope=event&event_id={id}` | `scope` is **required** (`event` or `organization`); pass `event_id` when scope=event |
| GET | `/events/{event_id}/access_codes/` | List access codes (gate ticket classes behind a code) |
| POST | `/events/{event_id}/access_codes/` | Create one |

Two discount types: **Public** (shown on checkout, single-event) and
**Coded** (requires a secret code, can span multiple ticket classes/events).

### Webhooks
| Method | Path | Notes |
|---|---|---|
| GET | `/organizations/{organization_id}/webhooks/` | List |
| POST | `/organizations/{organization_id}/webhooks/` | Create. Body: `{"endpoint_url": "...", "actions": "event.updated", "event_id": "..."}` — `event_id` optional (omit to fire for all org events); `actions` accepts one action or a comma-separated list, comes back as an array |
| GET | `/webhooks/{webhook_id}/` | Get one |
| DELETE | `/webhooks/{webhook_id}/` | Delete — returns `{"id": "...", "success": true}` |

Action types (from Eventbrite's engineering blog, not independently
re-verified against a firing webhook): `event.created`, `event.published`,
`event.unpublished`, `event.updated`, `attendee.updated`,
`attendee.checked_in`, `attendee.checked_out`, `order.placed`,
`order.updated`, `order.refunded`, `organizer.updated`, `venue.updated`.
Delivery is a notify-then-fetch POST referencing the changed object's API
URL, not the full object inline.

### Public event search — REMOVED, do not use
`GET /events/search/` **returns a bare 404** today (confirmed live) — it's
not just deprecated, the route is gone. Eventbrite killed public
cross-platform search in Feb 2020. There is no replacement; fetch events by
ID, by venue, or by organization instead.

## Worked examples (curl)

```bash
AUTH=(-H "Authorization: Bearer $EVENTBRITE_API_KEY")

# Who am I, and what orgs do I have?
curl -s "${AUTH[@]}" "https://www.eventbriteapi.com/v3/users/me/"
ORG=$(curl -s "${AUTH[@]}" "https://www.eventbriteapi.com/v3/users/me/organizations/" \
  | python3 -c "import json,sys;print(json.load(sys.stdin)['organizations'][0]['id'])")

# List all events in that org (including past/draft), with venue+tickets inlined
curl -s "${AUTH[@]}" \
  "https://www.eventbriteapi.com/v3/organizations/$ORG/events/?status=all&expand=venue,ticket_classes"

# Get one event's attendees
curl -s "${AUTH[@]}" "https://www.eventbriteapi.com/v3/events/$EVENT_ID/attendees/"

# Create + immediately delete a webhook (e.g. to smoke-test permissions)
curl -s -X POST "${AUTH[@]}" -H "Content-Type: application/json" \
  "https://www.eventbriteapi.com/v3/organizations/$ORG/webhooks/" \
  -d '{"endpoint_url":"https://example.com/webhook","actions":"event.updated"}'
curl -s -X DELETE "${AUTH[@]}" "https://www.eventbriteapi.com/v3/webhooks/$WEBHOOK_ID/"
```

## Gotchas learned from live testing

- **`/users/me/owned_events/` is dead for private tokens** — 404s with a
  misleading `"user_id you requested does not exist"` message. Always go
  through `/organizations/{organization_id}/events/` instead.
- **`/events/search/` is a hard 404**, not a throttled/degraded endpoint —
  don't build retry logic around it, there's nothing to retry into.
- **Discounts require `?scope=`** — omitting it gives `ARGUMENTS_ERROR:
  scope - MISSING` rather than defaulting to one scope.
- **Ticket class creation needs a `cost`** unless the class is explicitly
  `free` or `donation` — `NO_COST` error otherwise. The `cost` currency must
  match the event's own `currency` field exactly, or you get
  `CURRENCY_MISMATCH`. The create field is `name`, not `display_name`
  (`display_name` is read-only and comes back "Unknown parameter" on create).
- **Rate-limit info is a response header** (`x-rate-limit`), not something
  you need to track client-side or infer from docs — just read it.
- Creating a resource (event/webhook/ticket class/etc.) is a real,
  live-visible side effect on the account — clean up test resources (e.g.
  `DELETE` a webhook you created to verify permissions) rather than leaving
  them behind.
- **`event.capacity_is_custom` is read-only** — sending it on event create
  gives `ARGUMENTS_ERROR: capacity_is_custom - Unknown parameter`. Just send
  `capacity`; the server sets `capacity_is_custom` itself.
- **New events are created as `status: draft` by default** — creating via
  `POST /organizations/{organization_id}/events/` never auto-publishes.
  Nothing extra is needed to "leave it in draft"; you only need to explicitly
  avoid calling `/events/{event_id}/publish/`.
- **Rich "structured content" (the block-based description editor shown on
  eventbrite.com) is read-only through the public API**, at least via a
  private token. `GET /events/{event_id}/structured_content/` returns the
  modules (inc. the hero image carousel) and even advertises
  `resource_uris.add_module`/`.publish` write endpoints, but every write
  attempt fails:
  - `POST .../structured_content/{version}/module/` → hard `404 NOT_FOUND`
    regardless of payload shape (tried both `{"modules":[...]}` and a bare
    single-module object).
  - `POST .../structured_content/` (no version segment) → `405
    METHOD_NOT_ALLOWED`.
  These `resource_uris` appear to be vestigial/internal-only, not something
  a private-token integration can drive. **Use the plain `event.description`
  field instead** (`POST /events/{event_id}/` with
  `{"event":{"description":{"html": "..."}}}`) — it's the one place free text
  reliably lands, even though it renders as a flat block rather than the
  rich multi-module layout you see when an organizer edits via the web UI.
- **Event logo/cover image upload is broken for private-token API use.**
  `GET /media/upload/?type=image-event-logo` returns an
  `upload_url`/`upload_data`/`upload_token`, mimicking a classic S3
  form-post, but `upload_data` (`AWSAccessKeyId`, `bucket`, `acl`,
  `signature`, `policy`) all come back **empty strings** — only `key` is
  populated. POSTing the file + `key` to `upload_url`
  (`https://www.eventbrite.com/image-bff/api/upload`) does return
  `{"success":true,"message":"Upload completed"}`, but there is no working
  way to finalize it into a usable image: `POST /media/create/` rejects
  `upload_token` AND `key` as `Unknown parameter` (so neither name from the
  upload response is what it expects), and sending only `crop_mask` (the one
  field it does recognize) triggers a `500 INTERNAL_ERROR` instead of
  linking to the uploaded file. Net effect: **you cannot set an event's
  cover image via this API with a private token** — the "success" from the
  upload step is misleading, since there's no discovered way to attach that
  upload to an event afterward. Tell the user to set the cover image
  manually in the Eventbrite web editor; don't spend more time retrying
  parameter-name variations on `/media/create/` without new evidence.
- **Exclamation marks in JSON payload bodies can get silently corrupted by
  the shell** when built via `curl -d '...'` or a Bash heredoc — a stray
  backslash gets inserted before every `!` (e.g. "going!" becomes "going\!"),
  which then round-trips into the live event description. Eventbrite copy
  text is full of exclamation marks ("spaces are limited!"), so this bites
  often. It reproduced even inside a single-quoted heredoc, so quoting
  alone doesn't fix it. **Workaround: write the JSON payload file with the
  Write tool (not Bash/heredoc), then reference it with `curl -d @file`** —
  Write isn't shell-parsed so the text survives untouched. Always spot-check
  the live result afterward (`chr(92) in text` in Python) rather than
  trusting a local pre-send check, since the same corruption can affect a
  verification command's inline string too and produce a false-negative
  "looks fine" match.
- **There is no scheduled/future publish via the API.** Eventbrite's web
  organizer UI offers a "Schedule" option alongside "Publish Now" when
  publishing an event, but this is a web-app-only mechanism — confirmed live
  (2026-07-01) that it does NOT surface anywhere via the API:
  - The event object has no scheduled-publish field at all (checked every
    top-level key on a freshly web-UI-scheduled event — nothing named
    `publish_date`, `scheduled_*`, etc.).
  - `POST /events/{event_id}/publish/` only supports immediate publish —
    passing `{"publish_date": "..."}` gives `ARGUMENTS_ERROR: publish_date -
    Unknown parameter`.
  - No `/events/{event_id}/schedule/` or similar sub-resource exists (`404`).
  If a user wants an event to go live at a specific future time and they
  won't do it manually in the web UI, the only API-side workaround is an
  external scheduler (e.g. a Claude Code cloud routine) that calls
  `POST /events/{event_id}/publish/` at the target time — there is no
  Eventbrite-native way to arm this.
