FROM registry.access.redhat.com/ubi8/ubi:latest

ENV VIRTUAL_ENV=/insights-behavioral-spec-venv \
    VIRTUAL_ENV_BIN=/insights-behavioral-spec-venv/bin \
    HOME=/insights-behavioral-spec \
    REQUESTS_CA_BUNDLE=/etc/pki/tls/certs/ca-bundle.crt \
    ENV_DOCKER=1 \
    DB_NAME=test \
    DB_HOST=database \
    DB_PORT=5432 \
    DB_USER=postgres \
    DB_PASS=postgres \
    DB_PARAMS="sslmode=disable" \
    KAFKA_HOST=kafka \
    KAFKA_PORT=9092 \
    S3_TYPE=minio \
    S3_HOST=minio \
    S3_PORT=9000 \
    S3_ACCESS_KEY=test_access_key \
    S3_SECRET_ACCESS_KEY=test_secret_access_key \
    S3_BUCKET=test \
    S3_USE_SSL=false

WORKDIR $HOME

COPY . $HOME

ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN dnf install --nodocs -y python3.11 unzip make lsof git libpq-devel

RUN python3.11  -m venv $VIRTUAL_ENV && source $VIRTUAL_ENV/bin/activate

RUN curl -ksL https://certs.corp.redhat.com/certs/2015-IT-Root-CA.pem -o /etc/pki/ca-trust/source/anchors/RH-IT-Root-CA.crt
RUN curl -ksL https://certs.corp.redhat.com/certs/2022-IT-Root-CA.pem -o /etc/pki/ca-trust/source/anchors/2022-IT-Root-CA.pem
RUN update-ca-trust
RUN pip install --no-cache-dir -U pip setuptools wheel
RUN pip install --no-cache-dir -r requirements/requirements_docker.txt

RUN dnf clean all
RUN chmod -R g=u $HOME $VIRTUAL_ENV /etc/passwd
RUN chgrp -R 0 $HOME $VIRTUAL_ENV


COPY --from=quay.io/ccxdev/cp-kafkacat:7.0.10-1-ubi8 /usr/local/bin/kafkacat $VIRTUAL_ENV_BIN/kcat

USER 1001

CMD ["sh", "-c", "make $TESTS_TO_EXECUTE"]
