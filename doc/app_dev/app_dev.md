# Project: IOT Mgnt Telemetry Cloud Native - Application

[Back](../../README.md)

- [Project: IOT Mgnt Telemetry Cloud Native - Application](#project-iot-mgnt-telemetry-cloud-native---application)
  - [FastAPI](#fastapi)
    - [Initialize Environment](#initialize-environment)
    - [Unit Test](#unit-test)
    - [ECR](#ecr)
  - [Flyway](#flyway)

---

## FastAPI

### Initialize Environment

```sh
# init
cd app/fastapi
python -m venv .venv

.venv\Scripts\activate.bat

python.exe -m pip install --upgrade pip
pip install fastapi "uvicorn[standard]" "SQLAlchemy[asyncio]" asyncpg pydantic python-dotenv pydantic-settings pytest pytest-asyncio httpx redis kafka

pip freeze > requirements.txt

uvicorn app.main:app --reload
```

---

### Unit Test

```sh
cd app/fastapi

# unit test
pytest
```

---

### ECR

```sh
# login
aws ecr get-login-password --region ca-central-1 | docker login --username AWS --password-stdin 099139718958.dkr.ecr.ca-central-1.amazonaws.com
# Login Succeeded

# Create repo
aws ecr create-repository --repository-name iot-mgnt-telemetry-fastapi --region ca-central-1

# Push
docker build -t fastaapi app/fastapi
# tag
docker tag fastaapi 099139718958.dkr.ecr.ca-central-1.amazonaws.com/iot-mgnt-telemetry-fastapi
# push to docker
docker push 099139718958.dkr.ecr.ca-central-1.amazonaws.com/iot-mgnt-telemetry-fastapi

```

---

## Flyway

- ECR

```sh
# login
aws ecr get-login-password --region ca-central-1 | docker login --username AWS --password-stdin 099139718958.dkr.ecr.ca-central-1.amazonaws.com
# Login Succeeded

# Create repo
aws ecr create-repository --repository-name iot-mgnt-telemetry-flyway --region ca-central-1

# push image
docker build -t flyway app/flyway
# tag
docker tag flyway 099139718958.dkr.ecr.ca-central-1.amazonaws.com/iot-mgnt-telemetry-flyway
# push to docker
docker push 099139718958.dkr.ecr.ca-central-1.amazonaws.com/iot-mgnt-telemetry-flyway

```
