# Project: IOT Management Telemetry - Cloud Native Solution

- [Project: IOT Management Telemetry - Cloud Native Solution](#project-iot-management-telemetry---cloud-native-solution)
  - [Goal](#goal)
  - [Design: System Architecture](#design-system-architecture)
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

## Design: System Architecture

| Solution   | Description                                        | Intended Improvement                        |
| ---------- | -------------------------------------------------- | ------------------------------------------- |
| `baseline` | ECS(FastAPI) + RDS(PostgreSQL)                     | Starting reference                          |
| `scale`    | ECS Autoscaling                                    | Improved handling of stress load            |
| `tune`     | DB connection pool tuning; optimized SQL/app logic | Higher throughput, lower latency            |
| `cache`    | Cache read endpoints                               | Faster reads, reduced DB load               |
| `queue`    | Async write pipeline (producer → queue → consumer) | Higher write throughput, smoother ingestion |

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
| **System Metrics** | ECS CPU/memory, RDS CPU/IOPS/connections, Redis hit rate, queue backlog/lag |

---

### Comparison Method

All architectures are evaluated using the same workload profiles and metrics to enable consistent comparison.

### Comparison Table

| Solution ID | Test Profile | p95 Latency (ms) | Error Rate (%) | Max Sustainable RPS | RDS CPU Max (%) | ECS CPU Max (%) | SLO Status | Notes |
| ----------- | ------------ | ---------------- | -------------- | ------------------- | --------------- | --------------- | ---------- | ----- |
| `baseline`  | Read-Heavy   |                  |                |                     |                 |                 |            |       |
| `baseline`  | Write-Heavy  |                  |                |                     |                 |                 |            |       |
| `baseline`  | Mixed        |                  |                |                     |                 |                 |            |       |
| `tune`      | Read-Heavy   |                  |                |                     |                 |                 |            |       |
| `tune`      | Write-Heavy  |                  |                |                     |                 |                 |            |       |
| `tune`      | Mixed        |                  |                |                     |                 |                 |            |       |
| `scale`     | Read-Heavy   |                  |                |                     |                 |                 |            |       |
| `scale`     | Write-Heavy  |                  |                |                     |                 |                 |            |       |
| `scale`     | Mixed        |                  |                |                     |                 |                 |            |       |
| `cache`     | Read-Heavy   |                  |                |                     |                 |                 |            |       |
| `cache`     | Write-Heavy  |                  |                |                     |                 |                 |            |       |
| `cache`     | Mixed        |                  |                |                     |                 |                 |            |       |
| `queue`     | Read-Heavy   |                  |                |                     |                 |                 |            |       |
| `queue`     | Write-Heavy  |                  |                |                     |                 |                 |            |       |
| `queue`     | Mixed        |                  |                |                     |                 |                 |            |       |

---

- [App Development](./doc/app_dev/app_dev.md)
- [Baseline](./doc/baseline/baseline.md)
- [Tune](./doc/tune/tune.md)
- [Scale](./doc/scale/scale.md)
- [Cache](./doc/cache/cache.md)
- [Queue](./doc/queue/queue.md)

- SLO

  - p99 latency: 300ms
  - error rate: <0.01
  - throughput: ~1000 req/s

- (pool size, worker) = (15, 1); 50ms

  - each connection can be used how many times: 1s/50ms = 20
  - total pool size per second: 15 \* 20 = 300

- debug

```sh
terraform destroy -auto-approve -target=aws_ecs_service.ecs_svc_consumer
terraform apply -auto-approve -target=aws_ecs_service.ecs_svc_consumer
```
