# Project: IOT Mgnt Telemetry Cloud Native - Baseline

[Back](../../README.md)

- [Project: IOT Mgnt Telemetry Cloud Native - Baseline](#project-iot-mgnt-telemetry-cloud-native---baseline)
  - [App](#app)
  - [Local Testing](#local-testing)
  - [ECR](#ecr)
    - [fastapi](#fastapi)
    - [init\_db](#init_db)
  - [AWS](#aws)
  - [Remote Testing](#remote-testing)

## App

```sh
cd sol_baseline/app/fastapi
python -m venv .venv

.venv\Scripts\activate.bat

python.exe -m pip install --upgrade pip
pip install fastapi "uvicorn[standard]" "SQLAlchemy[asyncio]" asyncpg pydantic python-dotenv pydantic-settings pytest pytest-asyncio httpx redis

uvicorn app.main:app --reload
```

---

## Local Testing

```sh
docker compose -f sol_baseline/app/docker-compose.yaml down -v
docker compose -f sol_baseline/app/docker-compose.yaml up -d --build

# smoke
docker run --rm --name test_smoke --net=baseline_public_network -p 5665:5665 -e BASE_URL="http://nginx:8080" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/test_smoke.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_smoke.js

# read heavy
docker run --rm --name test_hp_read --net=baseline_public_network -p 5665:5665 -e BASE_URL="http://nginx:8080" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/test_hp_read.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_read.js

# write heavy
docker run --rm --name test_hp_write --net=app_public_network -p 5665:5665 -e BASE_URL="http://nginx:8080" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/test_hp_write.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_write.js
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

### init_db

```sh
aws ecr create-repository --repository-name iot-mgnt-telemetry-init-db --region ca-central-1

docker build -t init-db sol_baseline/app/init_db
# tag
docker tag init-db 099139718958.dkr.ecr.ca-central-1.amazonaws.com/iot-mgnt-telemetry-init-db:baseline
# push to docker
docker push 099139718958.dkr.ecr.ca-central-1.amazonaws.com/iot-mgnt-telemetry-init-db:baseline
```

---

## AWS

```sh
cd sol_baseline/aws

terraform init -backend-config=backend.config

tfsec .
terraform fmt && terraform validate

terraform apply -auto-approve

terraform destroy -auto-approve

```

---

## Remote Testing

```sh
docker run --rm --name aws_test_smoke -p 5665:5665 -e BASE_URL="http://iot-baseline.arguswatcher.net" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/aws_test_smoke.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_smoke.js
```
