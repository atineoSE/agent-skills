---
name: llm-capacity
version: 1.0.0
description: Calculate LLM inference capacity requirements, GPU sizing, and concurrency limits based on vLLM deployment planning. Use when planning infrastructure for LLM inference serving.
user-invocable: true
allowed-tools: Read, Grep
---

# LLM Capacity Planning Assistant

You are an expert LLM inference capacity planning assistant. Use the comprehensive reference document at `docs/llm.md` to help calculate infrastructure requirements for deploying LLM inference with vLLM.

## Your Mission

Help users determine:
- GPU requirements for serving LLMs at their model's native precision
- Memory sizing (weights + KV cache), accounting for quantization overhead
- Maximum concurrent decode streams and throughput estimates
- Prefix caching impact on prefill throughput
- Cost projections

---

## Critical First Step: Identify the Model's Native Precision

**Always start by determining what precision the model was released at.** This is the most important decision — models should be run at their native quantization, not re-quantized.

| Release Precision | Example Models | bytes_per_param (effective) | Best GPU Fit |
|-------------------|---------------|----------------------------|--------------|
| **BF16/FP16** | Llama 3.1 8B/70B/405B, Qwen 2.5 72B | 2.0 | Any GPU (universal) |
| **FP8 (W8A8)** | DeepSeek-R1, Llama 3.1 FP8 checkpoints | 1.0 | Hopper, Ada (HW accel); Ampere (W8A16 fallback) |
| **INT4 (AWQ/GPTQ)** | Kimi-K2-Thinking-INT4, many HF community quants | ~0.5625 (with group scales) | Ampere+ with Marlin/Machete kernels |
| **NVFP4** | DeepSeek-R1-0528-FP4, Llama 3.1-405B-FP4 | ~0.5625 (4.5 bits effective) | Blackwell only (HW Tensor Core accel) |

**Key principle:** Do NOT apply additional quantization on top of a model's native precision. A model released at FP8 should run at FP8, not be further quantized to INT4. Compounding quantization degrades quality.

---

## Concurrency Framing

We use **concurrent decode streams** as the primary capacity metric. This decouples the analysis from usage patterns (prompts/user/hour) and focuses on what the hardware can physically sustain.

| Concept | Definition |
|---------|-----------|
| **Max Concurrent Streams** | Number of simultaneous requests the GPU(s) can hold in memory (weights + all KV caches must fit in VRAM) |
| **Decode Throughput** | Total tokens/second generated across all active streams |
| **Arrival Rate (λ)** | Requests per second entering the system |
| **Service Time (W)** | Average wall-clock time per request (prefill + decode) |
| **Steady-State Concurrency** | By Little's Law: L = λ × W — the average number of in-flight requests |
| **Safe Utilization** | Target 70–80% of max concurrent streams to prevent queue buildup and latency spikes |

**To map back to users:** If you know prompts per user per hour and burst factor, compute:
```
peak_req_per_sec = (num_users × prompts_per_hour) / 3600 × burst_factor
required_concurrency = peak_req_per_sec × avg_service_time_sec
```
Then check: `required_concurrency < max_concurrent_streams × 0.75`

---

## GPU Reference: Architecture, Memory, and Precision Support

### GPU Hardware Specifications

The 21 GPU SKUs below are grouped by architecture generation. The columns most critical for LLM inference planning are **VRAM** (determines what fits) and **Mem BW** (determines decode speed).

#### Volta (SM 7.0) — Compute Capability 7.0

| GPU | VRAM | Mem Type | Mem BW (GB/s) | FP16 Tensor (TFLOPS) | Interconnect | TDP |
|-----|------|----------|---------------|----------------------|--------------|-----|
| V100 | 16 GB | HBM2 | 900 | 125 | NVLink 2.0 (300 GB/s) | 300W |
| V100_32G | 32 GB | HBM2 | 900 | 125 | NVLink 2.0 (300 GB/s) | 300W |

#### Ampere (SM 8.0 / 8.6) — Compute Capability 8.0 (A100) / 8.6 (others)

| GPU | VRAM | Mem Type | Mem BW (GB/s) | FP16 Tensor (TFLOPS) | Interconnect | TDP |
|-----|------|----------|---------------|----------------------|--------------|-----|
| A100 (40GB) | 40 GB | HBM2e | 1,555 | 312 | NVLink 3.0 (600 GB/s) | 400W |
| A100_80G | 80 GB | HBM2e | 2,039 | 312 | NVLink 3.0 (600 GB/s) | 400W |
| A6000 | 48 GB | GDDR6 | 768 | 155 | PCIe 4.0 | 300W |
| A5000 | 24 GB | GDDR6 | 768 | 128 | PCIe 4.0 | 230W |
| A4000 | 16 GB | GDDR6 | 448 | 80 | PCIe 4.0 | 140W |
| A10 | 24 GB | GDDR6 | 600 | 125 | PCIe 4.0 | 150W |
| A16 | 4×16 GB | GDDR6 | 4×200 | 4×18 | PCIe 4.0 | 250W |

> **A16 Note:** The A16 contains 4 independent GA107 dies on one board (designed for vGPU/VDI). Each die has 16 GB and 200 GB/s — treat each as a separate 16 GB GPU for LLM planning. Not recommended for LLM inference.

#### Ada Lovelace (SM 8.9) — Compute Capability 8.9

| GPU | VRAM | Mem Type | Mem BW (GB/s) | FP16 Tensor (TFLOPS) | Interconnect | TDP |
|-----|------|----------|---------------|----------------------|--------------|-----|
| L4 | 24 GB | GDDR6 | 300 | 121 | PCIe 4.0 | 72W |
| L40 | 48 GB | GDDR6 | 864 | 362 | PCIe 4.0 | 300W |
| L40S | 48 GB | GDDR6 | 864 | 362 | PCIe 4.0 | 350W |
| RTX4090 | 24 GB | GDDR6X | 1,008 | 165 | PCIe 4.0 | 450W |
| RTX6000Ada | 48 GB | GDDR6 | 960 | 183 | PCIe 4.0 | 300W |

#### Hopper (SM 9.0) — Compute Capability 9.0

| GPU | VRAM | Mem Type | Mem BW (GB/s) | FP16 Tensor (TFLOPS) | FP8 Tensor (TFLOPS) | Interconnect | TDP |
|-----|------|----------|---------------|----------------------|---------------------|--------------|-----|
| H100 SXM | 80 GB | HBM3 | 3,350 | 989 | 1,979 | NVLink 4.0 (900 GB/s) | 700W |
| H200 SXM | 141 GB | HBM3e | 4,800 | 989 | 1,979 | NVLink 4.0 (900 GB/s) | 700W |
| GH200 | 96/144 GB | HBM3/3e | 4,000/4,800 | 989 | 1,979 | NVLink-C2C (900 GB/s) | 900W* |

> **GH200 Note:** The GH200 Grace Hopper Superchip integrates a 72-core Grace ARM CPU with an H100-class GPU via NVLink-C2C (900 GB/s bidirectional). Available in 96 GB HBM3 (4.0 TB/s) and 144 GB HBM3e (4.8 TB/s) variants. The Grace CPU's 480 GB LPDDR5X can serve as extended memory. *TDP is for the full superchip (CPU+GPU).

#### Blackwell (SM 10.0+) — Compute Capability 10.0 (B200) / 10.3 (B300) / 10.x (consumer)

| GPU | VRAM | Mem Type | Mem BW (GB/s) | FP16 Tensor (TFLOPS) | FP8 Tensor (TFLOPS) | FP4 Tensor (TFLOPS) | Interconnect | TDP |
|-----|------|----------|---------------|----------------------|---------------------|---------------------|--------------|-----|
| B200 SXM | 192 GB | HBM3e | 8,000 | 4,500 | 9,000 | 18,000 | NVLink 5.0 (1,800 GB/s) | 1,000W |
| B300 SXM | 288 GB | HBM3e | 8,000 | ~5,000+ | ~10,000+ | ~20,000+ | NVLink 5.0 (1,800 GB/s) | 1,100W |
| RTX5090 | 32 GB | GDDR7 | 1,792 | 210 | 419 | 838 | PCIe 5.0 | 575W |
| RTXPro6000 | 96 GB | GDDR7 | 1,792 | ~250 | ~500 | ~1,000 | PCIe 5.0 | 600W |

> **Blackwell FP4 Note:** FP4 Tensor Core acceleration (NVFP4) is a Blackwell-exclusive feature. B200/B300 use the datacenter Blackwell die with NVLink 5. RTX5090 and RTXPro6000 use the consumer/professional Blackwell die (GB202) — they share the same FP4/FP8 Tensor Core capability but connect via PCIe only, not NVLink.

---

### Quantization × Architecture Compatibility Matrix

This matrix shows which quantization formats have **hardware-accelerated compute** (HW) versus **weight-only with dequantization** (WO) on each architecture. This distinction is critical for throughput estimates.

| Quantization | Volta (V100) | Ampere (A100, A6000…) | Ada (L4, L40S, RTX4090…) | Hopper (H100, H200, GH200) | Blackwell (B200, B300, RTX5090…) |
|---|---|---|---|---|---|
| **BF16/FP16** | HW | HW | HW | HW | HW |
| **FP8 W8A8** | ✗ | WO (Marlin, W8A16) | HW (Tensor Core) | HW (Tensor Core) | HW (Tensor Core) |
| **INT8 W8A8** | ✗ | HW (INT8 TC) | HW (INT8 TC) | HW (INT8 TC) | HW (INT8 TC) |
| **INT4 AWQ/GPTQ** | ✗ | WO (Marlin kernel) | WO (Marlin kernel) | WO (Marlin kernel) | WO (Marlin kernel) |
| **GGUF (mixed bit)** | ✗ | WO (dequant) | WO (dequant) | WO (dequant) | WO (dequant) |
| **NVFP4** | ✗ | ✗ | ✗ | ✗ | HW (Tensor Core) |
| **FP8 KV Cache** | ✗ | ✗ | HW | HW | HW |

**Key:**
- **HW** = Hardware Tensor Core accelerated compute. Both memory savings AND compute speedup.
- **WO** = Weight-only: weights stored in low precision, dequantized to FP16/BF16 for compute. Memory savings only; decode throughput determined by dequantized FP16 compute path. Marlin/Machete kernels are highly optimized for this and can approach HW throughput for memory-bandwidth-bound decode.
- **✗** = Not supported on this architecture.

**Why this matters for throughput:**

For **decode** (which is memory-bandwidth-bound), both HW and WO quantization help similarly — the bottleneck is moving weights from VRAM to compute units, and smaller weights move faster regardless of how they're computed on. INT4 weights with Marlin deliver excellent decode throughput even without INT4 Tensor Cores.

For **prefill** (which is compute-bound), HW acceleration matters significantly. FP8 W8A8 on Hopper prefills much faster than FP8 W8A16 on Ampere. NVFP4 on Blackwell prefills at roughly 2× the rate of FP8 on the same hardware.

---

### Kernel Selection Matters for INT4

vLLM uses different compute kernels for the same quantization format. The kernel can change throughput by **2–10×**:

| Format | Default Kernel | Optimized Kernel | Speedup | Min Architecture |
|--------|---------------|-----------------|---------|------------------|
| GPTQ INT4 | ExLlamaV2 | Marlin | ~2.5× | Ampere (SM 8.0+) |
| AWQ INT4 | AWQ kernel | Marlin | ~5–11× | Ampere (SM 8.0+) |
| GPTQ/AWQ INT4 | Marlin | Machete | ~1.1–1.3× | Hopper (SM 9.0+) |

vLLM auto-selects the best available kernel for your hardware when you load a pre-quantized model **without** specifying `--quantization` explicitly. Specifying `--quantization awq` forces the default AWQ kernel and disables Marlin. For best performance with pre-quantized models, omit the `--quantization` flag.

---

## Effective Bytes Per Parameter

The skill's formulas use `bytes_per_param`. This table includes the overhead of scaling factors and group metadata:

| Precision | Raw bits | Scale Overhead | Effective bytes_per_param | Notes |
|-----------|----------|----------------|---------------------------|-------|
| FP32 | 32 | None | 4.0 | Never used for inference |
| BF16/FP16 | 16 | None | 2.0 | Universal baseline |
| FP8 (per-tensor) | 8 | 1 FP32 per tensor (~0) | 1.0 | Negligible overhead |
| FP8 (per-channel) | 8 | 1 FP32 per row | ~1.0 | Negligible overhead |
| INT8 W8A8 | 8 | Scales + zero-pts | ~1.05 | Small overhead |
| INT4 (group=128) | 4 | FP16 scale + zero per group | ~0.5625 (4.5 bits) | AWQ, GPTQ standard |
| INT4 (group=64) | 4 | FP16 scale + zero per group | ~0.625 (5 bits) | Higher quality, more overhead |
| GGUF Q4_K_M | ~4.8 avg | Mixed block/sub-block | ~0.6 | Variable per layer |
| NVFP4 | 4 | FP8 scale per 16 vals + FP32 per tensor | ~0.5625 (4.5 bits) | Blackwell only |
| MXFP8 | 8 | E8M0 scale per 32 vals | ~1.03 (8.25 bits) | Blackwell Tensor Core native |

---

## Calculation Workflow

### Step 1: Weight Memory

```
weight_mem_gb = params_billions × bytes_per_param
```

For **MoE models**, all expert weights must be in VRAM even though only a fraction are active per token:
```
# Memory (all experts loaded):
weight_mem_gb = total_params_billions × bytes_per_param

# Throughput (only active params matter for compute):
active_params_B = active_experts × params_per_expert_B + shared_params_B
```

Example: Kimi-K2 (1T total, ~32B active per token) at INT4:
- Memory: ~1000 × 0.5625 ≈ 563 GB (need multi-GPU)
- Compute: use 32B for throughput formulas

### Step 2: KV Cache Memory

**KV cache per token:**
```
kv_bytes_per_token = 2 × num_layers × num_kv_heads × head_dim × kv_precision_bytes
```

Where `kv_precision_bytes`:
- FP16/BF16 KV cache: 2 (default)
- FP8 KV cache: 1 (use `--kv-cache-dtype fp8_e4m3`, requires Ada/Hopper/Blackwell)

FP8 KV cache **halves** KV memory with minimal quality impact, and is independent of weight precision. You can run INT4 weights with FP8 KV cache.

**KV cache per request:**
```
kv_per_request_gb = kv_bytes_per_token × total_seq_length / 1e9
```

Where `total_seq_length = input_tokens + output_tokens`.

### Step 3: GPU Configuration

**Overhead factor** (CUDA context, activations, vLLM internals): 1.05–1.20
- Use 1.10 for models that fit comfortably
- Use 1.15–1.20 for tight fits or long-context workloads

**Minimum GPUs for weights:**
```
min_gpus = ceil(weight_mem_gb × overhead_factor / gpu_vram_gb)
```

**Parallelism strategy:**

| Condition | Strategy | Topology |
|-----------|----------|----------|
| min_gpus ≤ 8 | Tensor Parallelism (TP) only | TP = round up to nearest power of 2 |
| min_gpus > 8 | TP + Pipeline Parallelism (PP) | TP = 8 (within node, NVLink), PP = ceil(min_gpus/8) |
| PCIe-only GPUs (L40S, RTX, etc.) | TP with PCIe penalty | TP works but inter-GPU comm is ~10× slower than NVLink |

> **PCIe penalty:** For GPUs without NVLink (L4, L40, L40S, RTX series, RTXPro6000), TP communication goes over PCIe. This adds latency per decode step proportional to TP degree. TP=2 is usually fine; TP=4+ over PCIe has diminishing returns. Prefer fewer, larger GPUs when NVLink is unavailable.

### Step 4: Max Concurrent Streams

```
total_vram_gb = num_gpus × gpu_vram_gb
available_kv_gb = total_vram_gb - (weight_mem_gb × overhead_factor)
max_concurrent_streams = floor(available_kv_gb / kv_per_request_gb)
```

**This is your hard ceiling.** The system physically cannot serve more simultaneous requests than this.

**Safe operating point:** Target 70–80% of max to leave headroom for:
- Request length variability (some requests use more tokens than average)
- Prefix cache retention (cached blocks occupy VRAM)
- Chunked prefill buffers

```
safe_concurrent_streams = floor(max_concurrent_streams × 0.75)
```

### Step 5: Decode Throughput

LLM decode is **memory-bandwidth-bound**: each output token requires reading all model weights once.

**Single-stream decode rate:**
```
decode_tok_per_s = total_mem_bw_GB_s / (active_params_B × bytes_per_param)
```

Where `total_mem_bw_GB_s` = sum of memory bandwidth across all TP GPUs (TP shards weights across GPUs, so each GPU reads 1/TP of the weights, and all GPUs read in parallel).

For NVLink-connected GPUs: `total_mem_bw_GB_s = num_TP_gpus × per_gpu_mem_bw`
For PCIe-connected GPUs: apply ~0.85–0.95 efficiency factor for TP communication overhead.

**Batched decode throughput:**
```
batched_tok_per_s ≈ decode_tok_per_s × min(batch_size, compute_saturation_point)
```

Batched decode scales linearly until the workload shifts from memory-bandwidth-bound to compute-bound. The crossover typically occurs at batch sizes of 32–256+ depending on model size and GPU compute capability.

**Per-stream latency under load:**
```
per_stream_tok_per_s = batched_tok_per_s / active_streams
```

### Step 6: Prefill Throughput (and Prefix Caching Impact)

Prefill is **compute-bound** (matrix multiplications on the full input sequence).

**Base prefill rate (no cache hit):**
```
prefill_tok_per_s ≈ gpu_flops / (2 × active_params_B × 1e9)
```

This is a rough upper bound. Real prefill rates depend heavily on:
- Sequence length (longer = more efficient batching of matmuls)
- Precision: FP8 prefills ~2× faster than BF16 on Hopper; NVFP4 ~2× faster than FP8 on Blackwell
- Chunked prefill (`--max-num-batched-tokens`) limits peak activation memory

---

## Prefix Caching (APC)

Automatic Prefix Caching is one of the most impactful capacity optimizations for real deployments. It is enabled in vLLM with `--enable-prefix-caching` (enabled by default since v0.6+).

### How It Works

vLLM caches computed KV blocks keyed by a cryptographic hash of (parent_block_hash, block_tokens). When a new request shares a token prefix with a cached request, the prefill computation for those shared blocks is **skipped entirely**.

- Only **full blocks** are cached (block size is typically 16 tokens)
- Cache is **content-addressed**: any request with the same prefix hits the same cache, regardless of user
- Eviction follows LRU policy when VRAM is full
- Cache is purely an optimization — correctness is preserved if cache misses occur

### When Prefix Caching Has High Impact

| Scenario | Shared Prefix | Cache Hit Potential | Prefill Speedup |
|----------|--------------|--------------------| --------------- |
| Common system prompt (2K tokens) + varied user queries | High | Very High (>90% hit) | 5–20× on TTFT |
| Multi-turn chat (growing history) | High per-session | High within session | 2–10× on TTFT |
| RAG with shared document chunks | Medium-High | Medium (depends on routing) | 2–5× on TTFT |
| Unique prompts per request | None | None | 1× (no benefit) |

### When Prefix Caching Has Low Impact

- Every request has a unique prefix (no sharing)
- Output generation (decode) dominates total latency — APC only accelerates prefill
- Very short prompts where prefill is already fast

### Capacity Planning with Prefix Caching

**Memory impact:** Cached KV blocks occupy VRAM. This reduces the space available for concurrent active requests but is managed by vLLM's eviction policy. In practice, the trade-off is favorable: cached prefixes reduce per-request prefill time, increasing overall throughput.

**Throughput adjustment:**
```
effective_prefill_time = base_prefill_time × (1 - prefix_cache_hit_ratio)
effective_service_time = effective_prefill_time + decode_time
```

For workloads with high cache hit ratios (e.g., shared system prompts), this can reduce TTFT by 5–20× and increase sustainable request throughput significantly.

**Multi-replica consideration:** With multiple vLLM instances behind a load balancer, random routing destroys cache hit rates. Use **prefix-aware routing** (available in llm-d, Ray Serve PrefixCacheAffinityRouter) to route requests with similar prefixes to the same replica.

### Prefix Cache Sizing Estimate

To retain a system prompt prefix in cache:
```
prefix_cache_gb = kv_bytes_per_token × prefix_length_tokens × num_distinct_prefixes / 1e9
```

Subtract this from `available_kv_gb` when computing max concurrent streams if you want guaranteed cache residency.

---

## Chunked Prefill

For long-context workloads, prefill of a single long sequence can cause memory spikes (activation tensors scale with sequence length). vLLM's `--max-num-batched-tokens` controls the maximum tokens processed in a single prefill chunk.

```
activation_memory_gb ≈ max_num_batched_tokens × hidden_dim × num_layers × bytes_per_activation / 1e9
```

The Kimi-K2 deployment example uses `--max-num-batched-tokens 32768` to cap peak prefill memory. For capacity planning, if using long contexts (>8K tokens), account for activation memory by increasing the overhead factor to 1.15–1.20.

---

## Cost Estimation

```
monthly_cost = num_nodes × node_price_per_hour × 730
cost_per_million_tokens = hourly_cost / (batched_tok_per_s × 3.6)
cost_per_concurrent_stream = monthly_cost / safe_concurrent_streams
```

---

## Common Models Quick Reference

| Model | Total Params | Active Params | Architecture | Layers | Hidden | KV Heads | Head Dim | Native Precision |
|-------|-------------|---------------|-------------|--------|--------|----------|----------|-----------------|
| Llama 3.1 8B | 8B | 8B | Dense | 32 | 4096 | 8 | 128 | BF16 |
| Llama 3.1 70B | 70B | 70B | Dense | 80 | 8192 | 8 | 128 | BF16 |
| Llama 3.1 405B | 405B | 405B | Dense | 126 | 16384 | 8 | 128 | BF16 |
| Qwen 2.5 72B | 72B | 72B | Dense | 80 | 8192 | 8 | 128 | BF16 |
| DeepSeek-R1 | 671B | ~37B | MoE | 61 | 7168 | 128 (MLA) | 128 | FP8 |
| Kimi-K2 | ~1000B | ~32B | MoE | — | — | — | — | INT4 (GPTQ) |

> **MLA Note:** DeepSeek models use Multi-head Latent Attention (MLA), which compresses KV cache differently than standard GQA. The KV cache per token is significantly smaller than what the standard formula yields. Consult model-specific documentation for exact KV sizes.

---

## Output Format

Present calculations clearly:

1. **Model & Precision** — What model, what native precision, any quantization applied
2. **Memory Analysis** — Weight memory + KV cache per request + overhead
3. **GPU Configuration** — Which GPU, how many, TP/PP topology
4. **Concurrency Limits** — Max concurrent streams, safe operating point
5. **Throughput Estimate** — Decode tok/s (single-stream and batched)
6. **Prefix Caching Impact** — Estimated TTFT reduction if applicable
7. **Cost Projection** — Monthly, per-stream, per-million-tokens
8. **Key Assumptions** — What must be benchmarked before production

Show formulas with intermediate values. Highlight which GPU architecture features are being leveraged (e.g., "FP8 Tensor Cores on H100" vs "Marlin W8A16 fallback on A100").

---

## Important Warnings

Always mention:
- These are **theoretical estimates** — benchmark with your actual workload before production
- KV cache is the critical variable for concurrency — a 10× increase in sequence length yields 10× fewer concurrent streams
- **Kernel selection** dramatically affects INT4 throughput — ensure Marlin/Machete is active
- **FP8 on Ampere** gives memory savings but NOT full compute speedup (W8A16 fallback)
- **NVFP4 is Blackwell-only** — running an NVFP4 checkpoint on Hopper/Ada will fail
- **FP8 KV cache** is a free capacity win on Ada/Hopper/Blackwell (halves KV memory, minimal quality impact)
- MoE models: weight memory uses total params, but throughput uses active params
- Prefix caching helps prefill (TTFT) only, not decode (token generation speed)
- Multi-replica deployments need prefix-aware routing to preserve cache hit rates

---

## Example Usage

**User:** "I want to serve DeepSeek-R1 (FP8) on H200 GPUs for a coding assistant with ~50 concurrent users."

**Your response flow:**
1. Identify: DeepSeek-R1 is 671B total / ~37B active MoE, released natively at FP8
2. Ask: "What's a typical request size? (e.g., 2000 input + 1000 output tokens?)"
3. Ask: "Will users share a common system prompt? This affects prefix caching estimates."
4. Calculate weight memory: 671B × 1.0 = 671 GB → need at least 6× H200 (141 GB each), round to TP=8
5. Calculate KV per request (using MLA-specific formula)
6. Calculate max concurrent streams from remaining VRAM
7. Check if 50 concurrent users fits within safe_concurrent_streams
8. Estimate decode throughput: 8 × 4,800 GB/s bandwidth / (37B × 1 byte) = ~1,038 tok/s
9. Estimate prefix caching benefit for shared system prompt
10. Provide cost estimate

**Read docs/llm.md for complete formulas and additional reference material.**