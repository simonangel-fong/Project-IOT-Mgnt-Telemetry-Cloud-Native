# Project: IOT Mgnt Telemetry Cloud Native - Kafka

[Back](../../README.md)

- [Project: IOT Mgnt Telemetry Cloud Native - Kafka](#project-iot-mgnt-telemetry-cloud-native---kafka)
  - [Local - Testing](#local---testing)
  - [AWS](#aws)
  - [Kafka](#kafka)
    - [Init](#init)
    - [Consumer](#consumer)
  - [Remote Testing](#remote-testing)

---

## Local - Testing

```sh
# dev
docker compose -f app/compose_kafka/compose.kafka.yaml down -v && docker compose --env-file app/compose_kafka/.kafka.dev.env -f app/compose_kafka/compose.kafka.yaml up -d --build

# prod
docker compose -f app/compose_kafka/compose.kafka.yaml down -v && docker compose --env-file app/compose_kafka/.kafka.prod.env -f app/compose_kafka/compose.kafka.yaml up -d --build

# smoke
docker run --rm --name kafka_local_smoke --net=kafka_public_network -p 5665:5665 -e BASE_URL="http://nginx:8080" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/kafka_local_smoke.html -e K6_WEB_DASHBOARD_PERIOD=3s -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_smoke.js

# read heavy
docker run --rm --name kafka_local_read --net=kafka_public_network -p 5665:5665 -e SOLUTION_ID="kafka" -e BASE_URL="http://nginx:8080" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/kafka_local_read.html -e K6_WEB_DASHBOARD_PERIOD=3s -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_read.js

# write heavy
docker run --rm --name kafka_local_write --net=kafka_public_network -p 5665:5665 -e SOLUTION_ID="kafka" -e BASE_URL="http://nginx:8080" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/kafka_local_write.html -e K6_WEB_DASHBOARD_PERIOD=3s -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_write.js

# mixed
docker run --rm --name kafka_local_mixed --net=kafka_public_network -p 5665:5665 -e SOLUTION_ID="Sol-kafka" -e BASE_URL="http://nginx:8080" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/kafka_local_mixed.html -e K6_WEB_DASHBOARD_PERIOD=3s -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_mixed.js

python k6/pgdb_write_check.py

```

---

## AWS

```sh
cd aws/kafka

terraform init -backend-config=backend.config

terraform fmt && terraform validate

terraform apply -auto-approve

aws ecs run-task --cluster iot-mgnt-telemetry-kafka-cluster --task-definition iot-mgnt-telemetry-scale-task-flyway --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[subnet-,subnet-,subnet-],securityGroups=[sg-]}"

terraform destroy -auto-approve

```

## Kafka

### Init

```sh
# Push
docker build -t kafka_init app/kafka/init
# tag
docker tag kafka_init 099139718958.dkr.ecr.ca-central-1.amazonaws.com/iot-mgnt-telemetry:kafka-init
# push to docker
docker push 099139718958.dkr.ecr.ca-central-1.amazonaws.com/iot-mgnt-telemetry:kafka-init

```

---

### Consumer

```sh
# Push
docker build -t kafka_consumer app/kafka/consumer
# tag
docker tag kafka_consumer 099139718958.dkr.ecr.ca-central-1.amazonaws.com/iot-mgnt-telemetry:kafka-consumer
# push to docker
docker push 099139718958.dkr.ecr.ca-central-1.amazonaws.com/iot-mgnt-telemetry:kafka-consumer

```

---

## Remote Testing

```sh
# smoke
docker run --rm --name kafka_aws_smoke -p 5665:5665 -e BASE_URL="https://iot-kafka.arguswatcher.net" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/kafka_aws_smoke.html -e K6_WEB_DASHBOARD_PERIOD=3s -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_smoke.js

# read heavy
docker run --rm --name kafka_aws_read -p 5665:5665 -e SOLUTION_ID="kafka" -e BASE_URL="https://iot-kafka.arguswatcher.net" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/kafka_aws_read.html -e K6_WEB_DASHBOARD_PERIOD=3s -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_read.js

# write heavy
docker run --rm --name kafka_aws_write -p 5665:5665 -e SOLUTION_ID="kafka" -e BASE_URL="https://iot-kafka.arguswatcher.net" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/kafka_aws_write.html -e K6_WEB_DASHBOARD_PERIOD=3s -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_write.js

# mixed
docker run --rm --name kafka_aws_mixed -p 5665:5665 -e SOLUTION_ID="kafka" -e BASE_URL="https://iot-kafka.arguswatcher.net" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/kafka_aws_mixed.html -e K6_WEB_DASHBOARD_PERIOD=3s -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_mixed.js

python k6/pgdb_write_check.py

```

- breaking point

```sh
# read breaking point
docker run --rm --name kafka_aws_read_break -p 5665:5665 -e SOLUTION_ID="kafka" -e BASE_URL="https://iot-kafka.arguswatcher.net" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/kafka_aws_read_break.html -e K6_WEB_DASHBOARD_PERIOD=3s -e RATE_TARGET=10000 -e STAGE_RAMP=60 -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_read.js

# write breaking point
docker run --rm --name kafka_aws_write_break -p 5665:5665 -e SOLUTION_ID="kafka" -e BASE_URL="https://iot-kafka.arguswatcher.net" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/kafka_aws_write_break.html -e K6_WEB_DASHBOARD_PERIOD=3s -e RATE_TARGET=10000 -e STAGE_RAMP=60 -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_write.js

# mixed breaking point
docker run --rm --name kafka_aws_write_break -p 5665:5665 -e SOLUTION_ID="kafka" -e BASE_URL="https://iot-kafka.arguswatcher.net" -e K6_WEB_DASHBOARD=true -e K6_WEB_DASHBOARD_EXPORT=/report/kafka_aws_write_break.html -e K6_WEB_DASHBOARD_PERIOD=3s -e RATE_READ_TARGET=10000 -e STAGE_RAMP=60 -v ./k6/script:/script -v ./k6/report:/report/ grafana/k6 run /script/test_hp_write.js

```
