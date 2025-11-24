# Project-IOT-Mgnt-Telemetry-Cloud-Native

- [Solution: Baseline](./doc/baseline/baseline.md)

| Solution ID  | Design                               | Tune                 |
| ------------ | ------------------------------------ | -------------------- |
| Sol-Baseline | ECS(FastAPI){1 cpu}+RDS{4 cpu}       | NA                   |
| Sol-ECS      | ECS(FastAPI){1 cpu}+RDS{4 cpu}       | pool+overflow+worker |
| Sol-Redis    | ECS(FastAPI){1 cpu}+Redis+RDS{4 cpu} | pool+overflow+worker |

- [App](./doc/app/app.md)
- [Sol-Baseline](./doc/baseline/baseline.md)
