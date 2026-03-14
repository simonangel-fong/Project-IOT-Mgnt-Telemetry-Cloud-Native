# Automated Architecture Benchmark (ECS)

**One Pipeline. Four Designs. Real Metrics.**

- [Automated Architecture Benchmark (ECS)](#automated-architecture-benchmark-ecs)
  - [Motivation](#motivation)
  - [Results](#results)
  - [Four Designs](#four-designs)
  - [One Pipeline](#one-pipeline)
  - [Tech Stack](#tech-stack)

---

## Motivation

Architecture advice is often theoretical — "add caching," "use a message queue" — without data to back it up. This project answers a practical question:

**How much does each architectural decision actually move the needle under real load?**

Four designs. One automated pipeline. Identical traffic conditions. Real numbers.

---

## Results

Four architectures were tested in progression — Baseline, Auto-Scaling, Redis Caching, and Kafka — each addressing a limitation of the previous.

**Baseline → Kafka:**

- **+213% Throughput Improvement** — 320 → 1,000 RPS
- **-99% Latency Reduction** — 3,000ms → 25ms (p95)
- **~0% Request Failures** — nearly eliminated at 1,000 RPS
- **-67% Database CPU Reduction** — 48.6% → 15.8%

---

**Technical Comparison**

| Architecture | Peak RPS | HTTP Failures | P95 Latency | ECS Tasks (Peak) | DB CPU |
| ------------ | -------- | ------------- | ----------- | ---------------- | ------ |
| Baseline     | 320      | 34.6%         | 3,000ms     | 1                | 19.2%  |
| Scale        | 1,000    | ~0%           | 70ms        | 18               | 48.6%  |
| Redis        | 1,000    | ~0%           | 75ms        | 16               | 34.9%  |
| Kafka        | 1,000    | ~0%           | 25ms        | 10               | 15.8%  |

**Business Impact**

| Architecture | Business Continuity | DB Overload Risk | Operational Cost | Complexity |
| ------------ | ------------------- | ---------------- | ---------------- | ---------- |
| Baseline     | ❌ Low              | 🔴 High          | 🟢 Low           | 🟢 Low     |
| Scale        | 🟢 High             | 🟠 Medium–High   | 🟠 Medium        | 🟠 Medium  |
| Redis        | 🟢 High             | 🟡 Medium        | 🟠 Medium        | 🟠 Medium  |
| Kafka        | 🟢 Very High        | 🟢 Low           | 🔴 High          | 🔴 High    |

![dashboard](./path/to/dashboard.gif)

[Full Metrics Snapshot](grafana-link) · [Load Testing Snapshot](grafana-link) · [Further analysis — load profile, metric behavior, and per-design breakdown](link)

---

## Four Designs

Each architecture addresses a limitation of the previous, tested under identical conditions.

![baseline](./app/html/img/diagram/baseline.gif)

![scale](./app/html/img/diagram/scale.gif)

![redis](./app/html/img/diagram/redis.gif)

![kafka](./app/html/img/diagram/kafka.gif)

[Architecture deep dives — design decisions, trade-offs, and technical challenges](link)

---

## One Pipeline

One automated workflow runs across all four designs — ensuring every benchmark is provisioned, tested, and torn down under identical conditions.

![pipeline](./path/to/github-actions-screenshot.png)

| Step | Action                   | Tool             |
| ---- | ------------------------ | ---------------- |
| 1    | Provision infrastructure | Terraform · Helm |
| 2    | Validate deployment      | Smoke test       |
| 3    | Load testing             | k6               |
| 4    | Tear down infrastructure | Terraform        |

[Pipeline design decisions — why GitHub Actions, why k6, and how state is managed across steps](link)

---

## Tech Stack

| Role               | Tools                                                |
| ------------------ | ---------------------------------------------------- |
| **Infrastructure** | AWS ECS · RDS · ElastiCache · MSK · Terraform · Helm |
| **CI/CD**          | GitHub Actions · Docker                              |
| **Load Testing**   | k6                                                   |
| **Observability**  | Grafana · CloudWatch                                 |
| **Backend**        | Python · FastAPI                                     |

---
