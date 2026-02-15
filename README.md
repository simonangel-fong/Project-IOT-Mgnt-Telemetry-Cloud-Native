# Project: IOT Management Telemetry - Cloud Native Solution

- [Project: IOT Management Telemetry - Cloud Native Solution](#project-iot-management-telemetry---cloud-native-solution)
  - [Goal](#goal)
  - [Design: System Architecture](#design-system-architecture)
  - [Design: Testing](#design-testing)
    - [Workload Profiles](#workload-profiles)
    - [Load Model](#load-model)
    - [Metrics Collected](#metrics-collected)
    - [Comparison Method](#comparison-method)

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

## Design: System Architecture

| Solution   | Description                                        | Intended Improvement                        |
| ---------- | -------------------------------------------------- | ------------------------------------------- |
| `baseline` | ECS(FastAPI) + RDS(PostgreSQL)                     | Starting reference                          |
| `scale`    | ECS Autoscaling                                    | Improved handling of stress load            |
| `redis`    | Cache read endpoints                               | Faster reads, reduced DB load               |
| `kafka`    | Async write pipeline (producer → kafka → consumer) | Higher write throughput, smoother ingestion |

---

## Design: Testing

- **Core Idea**

Use the **same k6 tests** across **different architectures** to ensure a fair and scientific **comparison**.

---

### Workload Profiles

| Test Profile    | Purpose                          | Workload Characteristics                    |
| --------------- | -------------------------------- | ------------------------------------------- |
| **Read-Heavy**  | Measure read scalability         | High RPS on `GET /api/telemetry/latest`     |
| **Write-Heavy** | Measure write scalability        | High RPS on `POST /api/telemetry/device_id` |
| **Mixed**       | Evaluate realistic load patterns | Both `GET` and `POST`                       |

---

### Load Model

- **k6 `ramping-arrival-rate`** (RPS-based): Controls the number of requests per second.
- **Ramp or step to ~1000 RPS**: Gradual increase toward the target load.
- **Early stop**: Stop after SLO breach

---

### Metrics Collected

| Category           | Metrics                                                                     |
| ------------------ | --------------------------------------------------------------------------- |
| **Latency**        | p95, p99 (endpoint-specific)                                                |
| **Errors**         | Failure rate, status code distribution, timeouts                            |
| **Capacity**       | Max RPS where latency and error thresholds remain acceptable                |
| **System Metrics** | ECS CPU/memory, RDS CPU/IOPS/connections, Redis hit rate, kafka backlog/lag |

---

### Comparison Method

All architectures are evaluated using the same workload profiles and metrics to enable consistent comparison.

- [Baseline](./doc/baseline/baseline.md)
- [Scale](./doc/scale/scale.md)
- [Redis](./doc/redis/redis.md)
- [Kafka](./doc/kafka/kafka.md)
<!-- - [Tune](./doc/tune/tune.md) -->
