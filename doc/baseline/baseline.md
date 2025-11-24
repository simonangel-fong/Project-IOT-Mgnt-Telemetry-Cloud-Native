## App

```sh
cd sol_baseline/app/fastapi
python -m venv .venv

.venv\Scripts\activate.bat

python.exe -m pip install --upgrade pip
pip install fastapi "uvicorn[standard]" "SQLAlchemy[asyncio]" asyncpg pydantic python-dotenv pydantic-settings pytest pytest-asyncio httpx redis

uvicorn app.main:app --reload

```

## Testing

```sh
docker compose -f sol_baseline/app/docker-compose.yaml down -v
docker compose -f sol_baseline/app/docker-compose.yaml up -d --build

# smoke
docker run --rm --name k6_smoke --net=app_public_network -p 5665:5665 -e BASE_URL="http://nginx:8080" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/test_smoke.html -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_smoke.js
```

## AWS

```sh
cd sol_baseline/aws

terraform init -backend-config=backend.config

tfsec .
terraform fmt && terraform validate

terraform apply -auto-approve

```
