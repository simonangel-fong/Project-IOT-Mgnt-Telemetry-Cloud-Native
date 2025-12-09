# Project: IOT Mgnt Telemetry Cloud Native - Baseline

[Back](../../README.md)

- [Project: IOT Mgnt Telemetry Cloud Native - Baseline](#project-iot-mgnt-telemetry-cloud-native---baseline)
  - [Local Testing](#local-testing)
  - [AWS Deployment](#aws-deployment)
  - [Remote Testing](#remote-testing)

---

## Local Testing

```sh
docker compose -f app/compose.baseline.yaml down -v
docker compose -f app/compose.baseline.yaml up -d --build

# smoke
docker run --rm --name baseline_local_smoke --net=baseline_public_network -p 5665:5665 -e BASE_URL="http://nginx:8080" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/baseline_local_smoke.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_smoke.js

# read heavy
docker run --rm --name baseline_local_read --net=baseline_public_network -p 5665:5665 -e SOLUTION_ID="baseline" -e BASE_URL="http://nginx:8080" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/baseline_local_read.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_read.js

# write heavy
docker run --rm --name test_hp_write --net=baseline_public_network -p 5665:5665 -e SOLUTION_ID="baseline" -e BASE_URL="http://nginx:8080" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/baseline_local_write.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_write.js

# mixed
docker run --rm --name test_hp_mixed --net=baseline_public_network -p 5665:5665 -e SOLUTION_ID="baseline" -e BASE_URL="http://nginx:8080" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/baseline_local_mixed.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_mixed.js
```

---

## AWS Deployment

```sh
cd aws/baseline

terraform init -backend-config=backend.config

tfsec .
terraform fmt && terraform validate

terraform apply -auto-approve

# execute flyway to init rds
aws ecs run-task --cluster iot-mgnt-telemetry-baseline-cluster --task-definition iot-mgnt-telemetry-baseline-task-flyway --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[subnet-,subnet-,subnet-],securityGroups=[sg-]}"

terraform destroy -auto-approve

```

---

## Remote Testing

```sh
# smoke
docker run --rm --name baseline_aws_smoke -p 5665:5665 -e BASE_URL="https://iot-baseline.arguswatcher.net" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/baseline_aws_smoke.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_smoke.js

# read heavy
docker run --rm --name baseline_aws_read -p 5665:5665 -e SOLUTION_ID="baseline" -e BASE_URL="https://iot-baseline.arguswatcher.net" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/baseline_aws_read.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_read.js

# write heavy
docker run --rm --name baseline_aws_write -p 5665:5665 -e SOLUTION_ID="baseline" -e BASE_URL="https://iot-baseline.arguswatcher.net" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/baseline_aws_write.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_write.js

# mixed
docker run --rm --name baseline_aws_mixed -p 5665:5665 -e SOLUTION_ID="baseline" -e BASE_URL="https://iot-baseline.arguswatcher.net" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/baseline_aws_mixed.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_mixed.js

```
