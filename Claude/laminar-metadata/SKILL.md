---
name: laminar-metadata
version: 1.0.0
description: Attach metadata to Laminar traces and filter/group them in the web UI. Use when instrumenting code with OpenTelemetry span attributes for Laminar or organizing traces by metadata and tags.
---

# Laminar Trace Metadata & Grouping

Guide for attaching metadata to Laminar traces and filtering/grouping them in the web UI.

## Span Attribute Keys

Set these as OpenTelemetry span attributes when instrumenting your code:

| Attribute key | Type | Purpose |
|---|---|---|
| `lmnr.association.properties.metadata.<key>` | string | Arbitrary key-value metadata (e.g., `metadata.environment`, `metadata.project_alias`) |
| `lmnr.association.properties.tags` | string[] | Array of categorical string labels |
| `lmnr.association.properties.session_id` | string | Group traces by session |
| `lmnr.association.properties.user_id` | string | Group traces by user |
| `lmnr.association.properties.trace_type` | string | Trace type classification |

The `ai.telemetry.metadata.*` prefix is also supported as a fallback (Vercel AI SDK compatible).

## Code Examples

### Python (OpenTelemetry)

```python
from opentelemetry import trace

tracer = trace.get_tracer(__name__)
with tracer.start_as_current_span("my-operation") as span:
    span.set_attribute("lmnr.association.properties.metadata.environment", "production")
    span.set_attribute("lmnr.association.properties.metadata.project_alias", "my-chatbot")
    span.set_attribute("lmnr.association.properties.tags", ["production", "v2", "chat"])
    span.set_attribute("lmnr.association.properties.session_id", "session-abc-123")
    span.set_attribute("lmnr.association.properties.user_id", "user-456")
```

### Via Span API (JSON)

```json
{
  "name": "chat_completion",
  "traceId": "uuid",
  "spanId": "uuid",
  "attributes": {
    "lmnr.association.properties.metadata.environment": "production",
    "lmnr.association.properties.metadata.project_alias": "my-chatbot",
    "lmnr.association.properties.tags": ["production", "important"],
    "lmnr.association.properties.session_id": "session-123",
    "lmnr.association.properties.user_id": "user-456"
  }
}
```

## How Metadata Propagates to Traces

- **Metadata**: First non-empty metadata from any span in the trace is used.
- **Tags**: All unique tags from all spans in the trace are collected.
- **Session ID / User ID**: First non-empty value from any span is used.

Data is stored in ClickHouse (`traces` table) as:
- `metadata` — JSON string
- `tags` — Array of strings
- `session_id` — String
- `user_id` — String

## Filtering in the Web UI

The **Traces table** provides filterable columns for all metadata fields:

| Column | Filter format | Example |
|---|---|---|
| Metadata | `key=value` | `environment=production` |
| Tags | select tag value | `v2` |
| Session ID | text search | `session-abc-123` |
| User ID | text search | `user-456` |

## Querying via SQL

All metadata is queryable in the SQL query engine:

```sql
-- Filter by metadata key
SELECT * FROM traces
WHERE simpleJSONExtractString(metadata, 'environment') = 'production';

-- Filter by tag
SELECT * FROM traces
WHERE has(tags, 'v2');

-- Group by metadata key
SELECT simpleJSONExtractString(metadata, 'project_alias') AS project,
       count() AS trace_count
FROM traces
GROUP BY project;
```

## Projects vs Metadata

Laminar **projects** are tied to API keys — each project has its own key and isolated dashboard. Metadata does **not** reassign traces to a different project.

Use metadata for logical sub-grouping within a project (e.g., `metadata.project_alias`). Use separate Laminar projects when you need full data isolation.
