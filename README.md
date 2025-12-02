# Project: IOT Management Telemetry - Cloud Native Solution

- [Project: IOT Management Telemetry - Cloud Native Solution](#project-iot-management-telemetry---cloud-native-solution)
  - [Goal](#goal)
  - [Design: System Architecture Variants](#design-system-architecture-variants)
  - [Design: Testing](#design-testing)
      - [Workload Profiles](#workload-profiles)
      - [Load Model](#load-model)
      - [Metrics Collected](#metrics-collected)
    - [Comparison Method](#comparison-method)
    - [Comparison Table](#comparison-table)

---

## Goal

Evaluate how multiple **system architectures** impact the performance of an IoT telemetry platform, focusing on:

- Read capacity
- Write capacity
- Latency (p95/p99)
- Error rate
- Scalability and bottlenecks

**Outcome:** Identify the architecture that delivers the best performance under sustained high-volume workloads.

---

## Design: System Architecture Variants

| Solution ID  | Variant             | Description                                        | Intended Improvement                        |
| ------------ | ------------------- | -------------------------------------------------- | ------------------------------------------- |
| Sol-Baseline | **Baseline**        | FastAPI + PostgreSQL (ECS + RDS)                   | Starting reference                          |
| Sol-Tune      | **App Tuning**      | DB connection pool tuning; optimized SQL/app logic | Higher throughput, lower latency            |
| Sol-Scale    | **ECS Autoscaling** | Horizontal scaling of API containers               | Improved handling of peak load              |
| Sol-Cache    | **Redis Caching**   | Cache read endpoints                               | Faster reads, reduced DB load               |
| Sol-Queue    | **Write Queue**     | Async write pipeline (producer → queue → consumer) | Higher write throughput, smoother ingestion |

---

## Design: Testing

- **Core Idea**

Use the **same k6 tests** across **different architectures** to ensure a fair and scientific **comparison**.

---

#### Workload Profiles

| Test Profile    | Purpose                          | Workload Characteristics             |
| --------------- | -------------------------------- | ------------------------------------ |
| **Read-Heavy**  | Measure read scalability         | High RPS on `/telemetry/latest`      |
| **Write-Heavy** | Measure write scalability        | High RPS on telemetry write endpoint |
| **Mixed**       | Evaluate realistic load patterns | Configurable read/write ratios       |

---

#### Load Model

- **k6 `ramping-arrival-rate`** (RPS-based): Controls the number of requests per second.
- **Ramp or step to ~1000 RPS**: Gradual increase toward the target load.
- **No early stop**: Allow full observation of behavior beyond SLO breach.

---

#### Metrics Collected

| Category           | Metrics                                                                     |
| ------------------ | --------------------------------------------------------------------------- |
| **Latency**        | p50, p95, p99 (endpoint-specific)                                           |
| **Errors**         | Failure rate, status code distribution, timeouts                            |
| **Capacity**       | Max RPS where latency and error thresholds remain acceptable                |
| **System Metrics** | ECS CPU/memory, RDS CPU/IOPS/connections, Redis hit rate, queue backlog/lag |

---

### Comparison Method

All architectures are evaluated using the same workload profiles and metrics to enable consistent comparison.

### Comparison Table

| Solution ID  | Test Profile | p95 Latency (ms) | Error Rate (%) | Max Sustainable RPS | RDS CPU Max (%) | ECS CPU Max (%) | SLO Status | Notes |
| ------------ | ------------ | ---------------- | -------------- | ------------------- | --------------- | --------------- | ---------- | ----- |
| Sol-Baseline | Read-Heavy   |                  |                |                     |                 |                 |            |       |
| Sol-Baseline | Write-Heavy  |                  |                |                     |                 |                 |            |       |
| Sol-Baseline | Mixed        |                  |                |                     |                 |                 |            |       |
| Sol-Tune      | Read-Heavy   |                  |                |                     |                 |                 |            |       |
| Sol-Tune      | Write-Heavy  |                  |                |                     |                 |                 |            |       |
| Sol-Tune      | Mixed        |                  |                |                     |                 |                 |            |       |
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
- [Sol-Tune](./doc/tune/tune.md)
- [FastAPI](./doc/fastapi/fastapi.md)
