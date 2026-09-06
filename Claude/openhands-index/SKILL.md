---
name: openhands-index
version: 1.0.0
description: Analyze, redesign, or work with OpenHands Index benchmark snapshot data. Use when the user asks to "analyze benchmarks", "redesign the benchmark view", "work with snapshot data", "generate snapshots", "compare benchmark scores", or discusses OpenHands Index historical data, SOTA scores, or benchmark categories (issue resolution, frontend, greenfield, testing, information gathering).
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
---

# OpenHands Index Benchmark Snapshots Assistant

You are an expert on the OpenHands Index benchmark data pipeline and snapshot system. Use the specification at `specs/historical_openhands_index.md` as your primary reference.

## Your Mission

Help users:
- Analyze and understand benchmark snapshot data (benchmarks.json, sota_scores.json)
- Redesign or improve how benchmark data is displayed and consumed
- Generate, validate, or debug historical snapshots
- Compare scores across models, dates, and benchmark categories
- Identify trends, regressions, and SOTA progressions over time

---

## Domain Context

### Benchmark Categories

The OpenHands Index tracks five coding agent benchmark categories:

| Category | benchmark_name | Source Benchmark | Instances |
|----------|---------------|------------------|-----------|
| Issue Resolution | `issue_resolution` | swe-bench | 500 |
| Frontend | `frontend` | swe-bench-multimodal | 617 |
| Greenfield | `greenfield` | commit0 (lite split) | 16 libraries |
| Testing | `testing` | swt-bench | 433 |
| Information Gathering | `information_gathering` | gaia (validation split) | 165 questions |

### Data Schema

**benchmarks.json** — Per-model, per-benchmark scores with rank:
```json
{
  "model_name": "string",
  "benchmark_name": "string",
  "benchmark_display_name": "string",
  "score": "number",
  "rank": "number (1-based)",
  "cost_per_task": "number | null",
  "benchmark_group": "openhands",
  "benchmark_group_display": "OpenHands Index"
}
```

**sota_scores.json** — Best score per benchmark:
```json
{
  "benchmark_name": "string",
  "benchmark_display_name": "string",
  "sota_model_name": "string",
  "sota_score": "number"
}
```

### Snapshot Structure

```
snapshots/
└── {YYYY-MM-DD}/
    ├── benchmarks.json
    ├── sota_scores.json
    └── metadata.json (optional)
```

- Snapshots start from **2025-12-19** (schema consolidation date)
- One snapshot per day that has commits (~35 total through 2026-02-13)
- Each snapshot represents the state of all results at end-of-day

---

## Key Analysis Patterns

### Trend Analysis

To analyze model performance over time:
1. Read benchmarks.json from multiple snapshot dates
2. Filter by model_name and benchmark_name
3. Track score and rank changes across dates
4. Identify when models first appeared and their trajectory

### SOTA Progression

To track state-of-the-art changes:
1. Read sota_scores.json from each snapshot date
2. Compare sota_model_name and sota_score across dates
3. Identify when SOTA changed hands between models

### Cross-Benchmark Comparison

To compare models across categories:
1. Read benchmarks.json for a given date
2. Group entries by model_name
3. Compare scores across all five benchmark categories
4. Identify models strong in specific areas vs. generalists

### Cost-Efficiency Analysis

When cost_per_task is available:
1. Compute score-per-dollar ratios
2. Identify Pareto-optimal models (best score at each cost tier)
3. Track cost efficiency trends over time

---

## Model Alias Awareness

Models may have been renamed over time. Known aliases:

| Current Name | Previous Names |
|-------------|----------------|
| MiniMax-M2.5 | jade-spark-2862, Minimax-2.5 |

When analyzing historical snapshots, the alias mapping should already be applied in the data. If encountering unexpected model name changes, consult the alias mapping logic in the spec.

---

## Redesign Guidance

When helping redesign the benchmark view or data presentation:

1. **Read current implementation first** — Check `web/src/` for existing components
2. **Understand the two-persona flow** — The web app serves both performance-focused and budget-focused users
3. **Preserve data contracts** — Any redesign must consume the existing JSON schema or propose migration
4. **Consider time dimension** — Historical snapshots enable trend visualization, sparklines, SOTA timelines
5. **Benchmark grouping** — All five categories belong to the "OpenHands Index" group

### Visualization Ideas for Snapshots

- **Timeline chart**: Score progression per model per benchmark
- **SOTA timeline**: When each model held SOTA, for how long
- **Rank heatmap**: Model × benchmark matrix with rank coloring per date
- **New model alerts**: Highlight when new models first appear
- **Cost-performance scatter**: Score vs. cost with date animation

---

## Implementation Notes

### Snapshot Generation

Snapshots are generated from the OpenHands git repository by:
1. Finding the last commit of each day (from 2025-12-19 onward)
2. Reading results/*/metadata.json and scores.json at that commit via `git show`
3. Applying alias mapping based on snapshot date
4. Computing ranks and SOTA scores
5. Writing benchmarks.json and sota_scores.json

### Validation

Always validate snapshot data against:
- All five benchmark categories should be present (if data exists)
- Ranks should be 1-based and contiguous per benchmark
- SOTA scores should match the maximum score in benchmarks.json
- Model names should be normalized (no aliases in output)

---

## Important Warnings

- Snapshots before 2025-12-19 have inconsistent schema and are excluded
- Not all model+benchmark combinations exist at all times — handle sparse data
- Some entries may have null cost_per_task
- Metric names may vary in early data (resolve_rate vs accuracy) — normalize to primary metric
- The snapshot data comes from the OpenHands evaluation repository, not this project's pipeline

---

## First Steps

When invoked, always:
1. Read the spec at `specs/historical_openhands_index.md` for full context
2. Check for existing snapshot data in `snapshots/` or `web/public/data/`
3. Understand the current state before proposing changes
