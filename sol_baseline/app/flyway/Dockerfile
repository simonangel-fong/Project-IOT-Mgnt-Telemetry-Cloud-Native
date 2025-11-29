# flyway/Dockerfile
FROM flyway/flyway:10-alpine

WORKDIR /flyway
# copy sql scripts
COPY ./sql /flyway/sql
# copy conf
COPY ./conf /flyway/conf/

CMD ["migrate"]
