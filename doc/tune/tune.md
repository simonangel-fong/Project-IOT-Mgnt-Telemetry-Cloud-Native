# Project: IOT Mgnt Telemetry Cloud Native - Application Tuning

[Back](../../README.md)

- [Project: IOT Mgnt Telemetry Cloud Native - Application Tuning](#project-iot-mgnt-telemetry-cloud-native---application-tuning)
  - [FastAPI](#fastapi)
  - [Local - Testing](#local---testing)

---

## FastAPI

```sh
# init
cd sol_tune/app/fastapi
python -m venv .venv

.venv\Scripts\activate.bat

python.exe -m pip install --upgrade pip
pip install fastapi "uvicorn[standard]" "SQLAlchemy[asyncio]" asyncpg pydantic python-dotenv pydantic-settings pytest pytest-asyncio httpx redis

uvicorn app.main:app --reload

# unit test
pytest
```

---

## Local - Testing

```sh
docker compose -f app/compose.tune.yaml down -v
docker compose -f app/compose.tune.yaml up -d --build

# smoke
docker run --rm --name test_smoke --net=tune_public_network -p 5665:5665 -e BASE_URL="http://nginx:8080" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/sol_tuned_local_smoke.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_smoke.js

# read heavy
docker run --rm --name test_hp_read --net=tune_public_network -p 5665:5665 -e SOLUTION_ID="Sol-Tune" -e BASE_URL="http://nginx:8080" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/sol_tuned_local_read.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_read.js

# write heavy
docker run --rm --name test_hp_write --net=tune_public_network -p 5665:5665 -e SOLUTION_ID="Sol-Tune" -e BASE_URL="http://nginx:8080" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/sol_tuned_local_write.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_write.js

# mixed
docker run --rm --name test_hp_mixed --net=tune_public_network -p 5665:5665 -e SOLUTION_ID="Sol-Tune" -e BASE_URL="http://nginx:8080" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/sol_tuned_local_mixed.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_mixed.js
```

---
