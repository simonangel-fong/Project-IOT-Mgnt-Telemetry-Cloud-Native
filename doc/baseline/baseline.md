# Project: IOT Mgnt Telemetry Cloud Native - Baseline

[Back](../../README.md)

- [Project: IOT Mgnt Telemetry Cloud Native - Baseline](#project-iot-mgnt-telemetry-cloud-native---baseline)
  - [Git Branch](#git-branch)
  - [Local Testing](#local-testing)
  - [ECR](#ecr)
    - [fastapi](#fastapi)
    - [flyway](#flyway)
  - [AWS](#aws)
  - [Remote Testing](#remote-testing)

---

## Git Branch

```sh
git branch feature-baseline-dev
git branch feature-baseline-testing
```

## Local Testing

```sh
docker compose -f app/compose.baseline.yaml down -v
docker compose -f app/compose.baseline.yaml up -d --build

# smoke
docker run --rm --name test_smoke --net=baseline_public_network -p 5665:5665 -e BASE_URL="http://nginx:8080" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/sol_baseline_local_smoke.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_smoke.js

# read heavy
docker run --rm --name test_hp_read --net=baseline_public_network -p 5665:5665 -e SOLUTION_ID="Sol-Baseline" -e BASE_URL="http://nginx:8080" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/sol_baseline_local_read.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_read.js

# write heavy
docker run --rm --name test_hp_write --net=baseline_public_network -p 5665:5665 -e SOLUTION_ID="Sol-Baseline" -e BASE_URL="http://nginx:8080" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/sol_baseline_local_write.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_write.js

# mixed
docker run --rm --name test_hp_mixed --net=baseline_public_network -p 5665:5665 -e SOLUTION_ID="Sol-Baseline" -e BASE_URL="http://nginx:8080" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/sol_baseline_local_mixed.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_mixed.js
```

---

## ECR

```sh
aws ecr get-login-password --region ca-central-1 | docker login --username AWS --password-stdin 099139718958.dkr.ecr.ca-central-1.amazonaws.com
# Login Succeeded
```

### fastapi

```sh
aws ecr create-repository --repository-name iot-mgnt-telemetry-fastapi --region ca-central-1

docker build -t fastaapi sol_baseline/app/fastapi
# tag
docker tag fastaapi 099139718958.dkr.ecr.ca-central-1.amazonaws.com/iot-mgnt-telemetry-fastapi:baseline
# push to docker
docker push 099139718958.dkr.ecr.ca-central-1.amazonaws.com/iot-mgnt-telemetry-fastapi:baseline

```

---

### flyway

- test

```sh
docker compose -f sol_baseline/app/docker-compose.yaml down -v
docker compose -f sol_baseline/app/docker-compose.yaml up -d --build

```

- push image

```sh
aws ecr create-repository --repository-name iot-mgnt-telemetry-flyway --region ca-central-1

docker build -t flyway sol_baseline/app/flyway
# tag
docker tag flyway 099139718958.dkr.ecr.ca-central-1.amazonaws.com/iot-mgnt-telemetry-flyway:baseline
# push to docker
docker push 099139718958.dkr.ecr.ca-central-1.amazonaws.com/iot-mgnt-telemetry-flyway:baseline
```

---

## AWS

```sh
cd aws/sol_baseline

terraform init -backend-config=backend.config

tfsec .
terraform fmt && terraform validate

terraform apply -auto-approve

# execute flyway to init rds
aws ecs run-task --cluster iot-mgnt-telemetry-baseline-cluster --task-definition iot-mgnt-telemetry-baseline-task-flyway --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[subnet-,subnet-,subnet-],securityGroups=[sg-]}"

aws ecs run-task --cluster iot-mgnt-telemetry-baseline-cluster --task-definition iot-mgnt-telemetry-baseline-task-flyway --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[subnet-0d7988d2ca6f7e6fb,subnet-0c4544fdb8fb05883,subnet-08077246c7a3cc995],securityGroups=[sg-05469459934ffddd7]}"

terraform destroy -auto-approve

```

---

## Remote Testing

```sh
# smoke
docker run --rm --name test_smoke -p 5665:5665 -e BASE_URL="https://iot-baseline.arguswatcher.net" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/sol_baseline_aws_smoke.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_smoke.js

# read heavy
docker run --rm --name test_hp_read -p 5665:5665 -e SOLUTION_ID="Sol-Baseline" -e BASE_URL="https://iot-baseline.arguswatcher.net" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/sol_baseline_aws_read.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_read.js

# write heavy
docker run --rm --name test_hp_write -p 5665:5665 -e SOLUTION_ID="Sol-Baseline" -e BASE_URL="https://iot-baseline.arguswatcher.net" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/sol_baseline_aws_write.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_write.js

# mixed
docker run --rm --name test_hp_mixed -p 5665:5665 -e SOLUTION_ID="Sol-Baseline" -e BASE_URL="https://iot-baseline.arguswatcher.net" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/aws_test_hp_mixed.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_mixed.js
```
