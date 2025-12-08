# Project: IOT Mgnt Telemetry Cloud Native - Scale

[Back](../../README.md)

- [Project: IOT Mgnt Telemetry Cloud Native - Scale](#project-iot-mgnt-telemetry-cloud-native---scale)
  - [Local - Testing](#local---testing)
  - [AWS](#aws)
  - [Remote Testing](#remote-testing)

---

## Local - Testing

```sh
docker compose -f app/compose.scale.yaml down -v
docker compose -f app/compose.scale.yaml up -d --build

# smoke
docker run --rm --name test_smoke --net=scale_public_network -p 5665:5665 -e BASE_URL="http://nginx:8080" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/scale_local_smoke.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_smoke.js

# read heavy
docker run --rm --name test_hp_read --net=scale_public_network -p 5665:5665 -e SOLUTION_ID="scale" -e BASE_URL="http://nginx:8080" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/scale_local_read.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_read.js

# write heavy
docker run --rm --name test_hp_write --net=scale_public_network -p 5665:5665 -e SOLUTION_ID="scale" -e BASE_URL="http://nginx:8080" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/scale_local_write.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_write.js

# mixed
docker run --rm --name test_hp_mixed --net=scale_public_network -p 5665:5665 -e SOLUTION_ID="scale" -e BASE_URL="http://nginx:8080" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/scale_local_mixed.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_mixed.js

```

---

## AWS

```sh
cd aws/scale

terraform init -backend-config=backend.config

terraform fmt && terraform validate

terraform apply -auto-approve

aws ecs run-task --cluster iot-mgnt-telemetry-scale-cluster --task-definition iot-mgnt-telemetry-scale-task-flyway --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[subnet-05eabbefed5ea9683,subnet-0ac0c20da21edab0c,subnet-0b0d7e4c3543d316a],securityGroups=[sg-02b877099d96956a0]}"

terraform destroy -auto-approve

```

## Remote Testing

```sh
# smoke
docker run --rm --name test_smoke -p 5665:5665 -e BASE_URL="https://iot-scale.arguswatcher.net" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/scale_aws_smoke.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_smoke.js

# read heavy
docker run --rm --name test_hp_read -p 5665:5665 -e SOLUTION_ID="scale" -e BASE_URL="https://iot-scale.arguswatcher.net" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/scale_aws_read.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run --out json=/report/scale_aws_read.json /script/test_hp_read.js

# write heavy
docker run --rm --name test_hp_write -p 5665:5665 -e SOLUTION_ID="scale" -e BASE_URL="https://iot-scale.arguswatcher.net" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/scale_aws_write.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_write.js

# mixed
docker run --rm --name test_hp_mixed -p 5665:5665 -e SOLUTION_ID="scale" -e BASE_URL="https://iot-scale.arguswatcher.net" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/scale_aws_mixed.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_mixed.js
```
