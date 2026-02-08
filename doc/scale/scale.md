# Project: IOT Mgnt Telemetry AWS ECS - Scale

[Back](../../README.md)

- [Project: IOT Mgnt Telemetry AWS ECS - Scale](#project-iot-mgnt-telemetry-aws-ecs---scale)
  - [Local Development](#local-development)
  - [Local - Testing](#local---testing)
  - [AWS](#aws)
  - [Remote Testing](#remote-testing)

---

## Local Development

## Local - Testing

```sh
# dev
docker compose -f app/compose_scale/compose.scale.yaml down -v && docker compose --env-file app/compose_scale/.scale.dev.env -f app/compose_scale/compose.scale.yaml up -d --build

# prod
docker compose -f app/compose_scale/compose.scale.yaml down -v && docker compose --env-file app/compose_scale/.scale.prod.env -f app/compose_scale/compose.scale.yaml up -d --build

# smoke
docker run --rm --name scale_local_smoke --net=scale_public_network -p 5665:5665 -e BASE_URL="http://nginx:8080" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/scale_local_smoke.html -e K6_WEB_DASHBOARD_PERIOD=3s -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_smoke.js

# Read Stress testing
docker run --rm --name scale_local_read_stress --net=scale_public_network -p 5665:5665 -e BASE_URL="http://nginx:8080" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/scale_local_read_stress.html -e K6_WEB_DASHBOARD_PERIOD=3s -e STAGE_RAMP=1 -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/stress_testing_read.js

# Write Stress testing
docker run --rm --name scale_local_write_stress --net=scale_public_network -p 5665:5665 -e BASE_URL="http://nginx:8080" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/scale_local_write_stress.html -e K6_WEB_DASHBOARD_PERIOD=3s -e STAGE_RAMP=1 -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/stress_testing_write.js

# read heavy
docker run --rm --name scale_local_read --net=scale_public_network -p 5665:5665 -e SOLUTION_ID="scale" -e BASE_URL="http://nginx:8080" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/scale_local_read.html -e K6_WEB_DASHBOARD_PERIOD=3s -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_read.js

# write heavy
docker run --rm --name scale_local_write --net=scale_public_network -p 5665:5665 -e SOLUTION_ID="scale" -e BASE_URL="http://nginx:8080" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/scale_local_write.html -e K6_WEB_DASHBOARD_PERIOD=3s  -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_write.js

# mixed
docker run --rm --name scale_local_mixed --net=scale_public_network -p 5665:5665 -e SOLUTION_ID="scale" -e BASE_URL="http://nginx:8080" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/scale_local_mixed.html -e K6_WEB_DASHBOARD_PERIOD=3s  -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_mixed.js

python k6/pgdb_write_check.py
```

---

## AWS

```sh
cd aws/scale

terraform init -backend-config=backend.config

terraform fmt && terraform validate

terraform apply -auto-approve

aws ecs run-task --cluster iot-mgnt-telemetry-scale-cluster --task-definition iot-mgnt-telemetry-scale-task-flyway --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[subnet-,subnet-,subnet-],securityGroups=[sg-]}"

terraform destroy -auto-approve

```

## Remote Testing

```sh
# smoke
docker run --rm --name scale_aws_smoke -p 5667:5665 -e BASE_URL="https://iot-scale.arguswatcher.net" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/scale_aws_smoke.html -e K6_WEB_DASHBOARD_PERIOD=3s -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_smoke.js

# read heavy
docker run --rm --name scale_aws_read -p 5667:5665 -e SOLUTION_ID="scale" -e BASE_URL="https://iot-scale.arguswatcher.net" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/scale_aws_read.html -e K6_WEB_DASHBOARD_PERIOD=3s -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_read.js

# write heavy
docker run --rm --name scale_aws_write -p 5667:5665 -e SOLUTION_ID="scale" -e BASE_URL="https://iot-scale.arguswatcher.net" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/scale_aws_write.html -e K6_WEB_DASHBOARD_PERIOD=3s -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_write.js

# mixed
docker run --rm --name scale_aws_mixed -p 5667:5665 -e SOLUTION_ID="scale" -e BASE_URL="https://iot-scale.arguswatcher.net" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/scale_aws_mixed.html -e K6_WEB_DASHBOARD_PERIOD=3s -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_mixed.js
```
