# Project: IOT Mgnt Telemetry Cloud Native - Application

[Back](../../README.md)

- [Project: IOT Mgnt Telemetry Cloud Native - Application](#project-iot-mgnt-telemetry-cloud-native---application)
  - [FastAPI](#fastapi)
    - [ECR](#ecr)

---

## FastAPI


### ECR



- redis

```sh
# Push
docker build -t fastapi_redis app/fastapi_redis

# tag
docker tag fastapi_redis 099139718958.dkr.ecr.ca-central-1.amazonaws.com/iot-mgnt-telemetry:fastapi-redis

# push to docker
docker push 099139718958.dkr.ecr.ca-central-1.amazonaws.com/iot-mgnt-telemetry:fastapi-redis

```

- kafka

```sh
# Push
docker build -t fastapi_kafka app/fastapi_kafka

# tag
docker tag fastapi_kafka 099139718958.dkr.ecr.ca-central-1.amazonaws.com/iot-mgnt-telemetry:fastapi-kafka

# push to docker
docker push 099139718958.dkr.ecr.ca-central-1.amazonaws.com/iot-mgnt-telemetry:fastapi-kafka

```

---
