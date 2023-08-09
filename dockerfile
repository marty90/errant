FROM python:3.8-alpine AS building_stage

RUN apk update \
	&& apk add \
		build-base \
		gfortran \
		g++ \
		lapack-dev \
	&& rm -rf /var/cache/apk/*

RUN python -m venv /opt/venv
# Make sure we use the virtualenv:
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .

RUN pip install -U --no-cache-dir --requirement requirements.txt


FROM python:3.8-alpine

LABEL maintainer "BRUNO Maxime <maxime.bruno@ens-lyon.fr>"

RUN apk update \
	&& apk add \
		bash \
		g++ \
		iproute2 \
		lapack-dev \
	&& rm -rf /var/cache/apk/*

COPY --from=building_stage /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY errant models.pickle sample_from_distribution.py /

COPY example/gateway.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
