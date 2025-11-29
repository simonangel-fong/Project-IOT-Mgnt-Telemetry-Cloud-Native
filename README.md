# Project: IOT Management Telemetry - Cloud Native Solution

- [Solution: Baseline](./doc/baseline/baseline.md)

## Goal

Evaluate how multiple **system architectures** impact the performance of an IoT telemetry platform, focusing on:

- Read capacity
- Write capacity
- Latency (p95/p99)
- Error rate
- Scalability and bottlenecks

**Outcome:** Identify the architecture that delivers the best performance under sustained high-volume workloads.

---

# 2. Design

## 2.1 System Architecture Variants

| Solution ID  | Variant             | Description                                        | Intended Improvement                        |
| ------------ | ------------------- | -------------------------------------------------- | ------------------------------------------- |
| Sol-Baseline | **Baseline**        | FastAPI + PostgreSQL (ECS + RDS)                   | Starting reference                          |
| Sol-App      | **App Tuning**      | DB connection pool tuning; optimized SQL/app logic | Higher throughput, lower latency            |
| Sol-Scale    | **ECS Autoscaling** | Horizontal scaling of API containers               | Improved handling of peak load              |
| Sol-Cache    | **Redis Caching**   | Cache read endpoints                               | Faster reads, reduced DB load               |
| Sol-Queue    | **Write Queue**     | Async write pipeline (producer → queue → consumer) | Higher write throughput, smoother ingestion |

---

## 2.2 Test Design

### Core Idea

Use the **same k6 tests** across **different architectures** to ensure a fair and scientific **comparison**.

---

### Workload Profiles

| Test Profile    | Purpose                          | Workload Characteristics             |
| --------------- | -------------------------------- | ------------------------------------ |
| **Read-Heavy**  | Measure read scalability         | High RPS on `/telemetry/latest`      |
| **Write-Heavy** | Measure write scalability        | High RPS on telemetry write endpoint |
| **Mixed**       | Evaluate realistic load patterns | Configurable read/write ratios       |

---

### Load Model

- **k6 `ramping-arrival-rate`** (RPS-based): Controls the number of requests per second.
- **Ramp or step to ~1000 RPS**: Gradual increase toward the target load.
- **No early stop**: Allow full observation of behavior beyond SLO breach.

---

### Metrics Collected

| Category           | Metrics                                                                     |
| ------------------ | --------------------------------------------------------------------------- |
| **Latency**        | p50, p95, p99 (endpoint-specific)                                           |
| **Errors**         | Failure rate, status code distribution, timeouts                            |
| **Capacity**       | Max RPS where latency and error thresholds remain acceptable                |
| **System Metrics** | ECS CPU/memory, RDS CPU/IOPS/connections, Redis hit rate, queue backlog/lag |

---

## 2.3 Comparison Method

All architectures are evaluated using the same workload profiles and metrics to enable consistent comparison.

### Comparison Table

### Comparison Table

| Solution ID  | Test Profile | p95 Latency (ms) | Error Rate (%) | Max Sustainable RPS | RDS CPU Max (%) | ECS CPU Max (%) | SLO Status | Notes |
| ------------ | ------------ | ---------------- | -------------- | ------------------- | --------------- | --------------- | ---------- | ----- |
| Sol-Baseline | Read-Heavy   |                  |                |                     |                 |                 |            |       |
| Sol-Baseline | Write-Heavy  |                  |                |                     |                 |                 |            |       |
| Sol-Baseline | Mixed        |                  |                |                     |                 |                 |            |       |
| Sol-App      | Read-Heavy   |                  |                |                     |                 |                 |            |       |
| Sol-App      | Write-Heavy  |                  |                |                     |                 |                 |            |       |
| Sol-App      | Mixed        |                  |                |                     |                 |                 |            |       |
| Sol-Scale    | Read-Heavy   |                  |                |                     |                 |                 |            |       |
| Sol-Scale    | Write-Heavy  |                  |                |                     |                 |                 |            |       |
| Sol-Scale    | Mixed        |                  |                |                     |                 |                 |            |       |
| Sol-Cache    | Read-Heavy   |                  |                |                     |                 |                 |            |       |
| Sol-Cache    | Write-Heavy  |                  |                |                     |                 |                 |            |       |
| Sol-Cache    | Mixed        |                  |                |                     |                 |                 |            |       |
| Sol-Queue    | Read-Heavy   |                  |                |                     |                 |                 |            |       |
| Sol-Queue    | Write-Heavy  |                  |                |                     |                 |                 |            |       |
| Sol-Queue    | Mixed        |                  |                |                     |                 |                 |            |       |

---

- [Sol-Baseline](./doc/baseline/baseline.md)
