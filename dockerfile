FROM python:3.8-alpine AS building_stage

RUN apk add g++ build-base lapack-dev gfortran

RUN python -m venv /opt/venv
# Make sure we use the virtualenv:
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .

RUN pip install -Ur requirements.txt


FROM python:3.8-alpine

RUN apk add bash iproute2 g++ lapack-dev

COPY --from=building_stage /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY errant models.pickle sample_from_distribution.py /

COPY example/gateway.sh /entrypoint.sh

ENTRYPOINT /entrypoint.sh