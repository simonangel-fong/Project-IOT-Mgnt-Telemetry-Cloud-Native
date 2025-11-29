# Project: IOT Management Telemetry - Cloud Native Solution

- [Solution: Baseline](./doc/baseline/baseline.md)

| Solution ID  | Design                               | Tune                 |
| ------------ | ------------------------------------ | -------------------- |
| Sol-Baseline | ECS(FastAPI){1 cpu}+RDS{4 cpu}       | NA                   |
| Sol-ECS      | ECS(FastAPI){1 cpu}+RDS{4 cpu}       | pool+overflow+worker |
| Sol-Redis    | ECS(FastAPI){1 cpu}+Redis+RDS{4 cpu} | pool+overflow+worker |

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

| Variant             | Description                                        | Intended Improvement                        |
| ------------------- | -------------------------------------------------- | ------------------------------------------- |
| **Baseline**        | FastAPI + PostgreSQL (ECS + RDS)                   | Starting reference                          |
| **App Tuning**      | DB connection pool tuning; optimized SQL/app logic | Higher throughput, lower latency            |
| **ECS Autoscaling** | Horizontal scaling of API containers               | Improved handling of peak load              |
| **Redis Caching**   | Cache read endpoints                               | Faster reads, reduced DB load               |
| **Write Queue**     | Async write pipeline (producer → queue → consumer) | Higher write throughput, smoother ingestion |

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

| Architecture Variant | Test Profile | p95 Latency (ms) | Error Rate (%) | Max Sustainable RPS | RDS CPU Max (%) | ECS CPU Max (%) | SLO Status | Notes |
| -------------------- | ------------ | ---------------- | -------------- | ------------------- | --------------- | --------------- | ---------- | ----- |
| Baseline             | Read-Heavy   |                  |                |                     |                 |                 |            |       |
| Baseline             | Write-Heavy  |                  |                |                     |                 |                 |            |       |
| Baseline             | Mixed        |                  |                |                     |                 |                 |            |       |
| App Tuning           | Read-Heavy   |                  |                |                     |                 |                 |            |       |
| App Tuning           | Write-Heavy  |                  |                |                     |                 |                 |            |       |
| App Tuning           | Mixed        |                  |                |                     |                 |                 |            |       |
| ECS Autoscaling      | Read-Heavy   |                  |                |                     |                 |                 |            |       |
| ECS Autoscaling      | Write-Heavy  |                  |                |                     |                 |                 |            |       |
| ECS Autoscaling      | Mixed        |                  |                |                     |                 |                 |            |       |
| Redis Caching        | Read-Heavy   |                  |                |                     |                 |                 |            |       |
| Redis Caching        | Write-Heavy  |                  |                |                     |                 |                 |            |       |
| Redis Caching        | Mixed        |                  |                |                     |                 |                 |            |       |
| Write Queue          | Read-Heavy   |                  |                |                     |                 |                 |            |       |
| Write Queue          | Write-Heavy  |                  |                |                     |                 |                 |            |       |
| Write Queue          | Mixed        |                  |                |                     |                 |                 |            |       |

---

- [Sol-Baseline](./doc/baseline/baseline.md)
