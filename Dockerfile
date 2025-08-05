# target architecture
FROM debian:trixie-slim AS builder

# Git branch to build from
ARG BV_SYN=release-v1.135
ARG BV_TUR=master
ARG TAG_SYN=v1.135.0

# user configuration
ENV MATRIX_UID=991 MATRIX_GID=991

# use --build-arg REBUILD=$(date) to invalidate the cache and upgrade all
# packages
ARG REBUILD=1
RUN set -ex \
    && export ARCH=`dpkg --print-architecture` \
    && export MARCH=`uname -m` \
    && touch /synapse.version \
    && export DEBIAN_FRONTEND=noninteractive \
    && mkdir -p /var/cache/apt/archives \
    && touch /var/cache/apt/archives/lock \
    && apt-get clean \
    && apt-get update -y -q --fix-missing\
    && apt-get upgrade -y

RUN apt-get install -y --no-install-recommends rustc cargo file gcc git libevent-dev libffi-dev libgnutls28-dev libjpeg62-turbo-dev libldap2-dev libsasl2-dev libsqlite3-dev \
    libssl-dev libtool libxml2-dev libxslt1-dev make zlib1g-dev python3-dev python3-setuptools libpq-dev pkg-config libicu-dev g++

RUN apt-get install -y --no-install-recommends \
    bash \
    coreutils \
    coturn \
    libjpeg62-turbo \
    libssl3 \
    libtool \
    libxml2 \
    libxslt1.1 \
		libicu-dev \
    pwgen \
    libffi8 \
    sqlite3 \
    python3 \
    python3-pip \
    python3-jinja2 \
    python3-icu \
    python3-venv

RUN groupadd -r -g $MATRIX_GID matrix
RUN useradd -r -d /matrix -m -u $MATRIX_UID -g matrix matrix

RUN git clone --branch $BV_SYN --depth 1 https://github.com/element-hq/synapse.git /synapse
RUN cd /synapse \
    && git checkout -b tags/$TAG_SYN

RUN chown -R $MATRIX_UID:$MATRIX_GID /matrix
RUN chown -R $MATRIX_UID:$MATRIX_GID /synapse
RUN chown -R $MATRIX_UID:$MATRIX_GID /synapse.version


RUN python3 -m venv /matrix/venv
RUN . /matrix/venv/bin/activate

ENV PATH=/matrix/venv/bin:$PATH

RUN pip3 install --upgrade wheel ;\
    pip3 install --upgrade psycopg2;\
    pip3 install --upgrade python-ldap ;\
    pip3 install --force-reinstall -v "Twisted==24.7.0" ;\
    pip3 install --upgrade redis ;\
    pip3 install --upgrade cryptography ;\
    pip3 install --upgrade lxml

RUN cd /synapse \
    && pip3 install .[all]

RUN cd /synapse \
    && GIT_SYN=$(git ls-remote https://github.com/element-hq/synapse $BV_SYN | cut -f 1) \
    && echo "synapse: $BV_SYN ($GIT_SYN)" >> /synapse.version

USER root

RUN rm -rf /matrix/.cargo \
    rm -rf /matrix/.cache

FROM debian:trixie-slim

# Maintainer
LABEL maintainer="Andreas Peters <support@aventer.biz>"
LABEL org.opencontainers.image.title="docker-matrix"
LABEL org.opencontainers.image.description="The one fits all docker image for synapse (matrix) chat server."
LABEL org.opencontainers.image.vendor="AVENTER UG (haftungsbeschränkt)"
LABEL org.opencontainers.image.source="https://github.com/AVENTER-UG/docker-matrix"

# install homerserver template
COPY adds/start.sh /start.sh

ENV COTURN_ENABLE=true
ENV MATRIX_UID=991 MATRIX_GID=991
ENV REPORT_STATS=no

RUN groupadd -r -g $MATRIX_GID matrix
RUN useradd -r -d /matrix -m -u $MATRIX_UID -g matrix matrix

RUN  mkdir /data \
    mkdir /uploads

RUN apt-get update -y -q --fix-missing
RUN apt-get upgrade -y
RUN apt-get install -y --no-install-recommends \
    bash \
    coturn \
    sqlite3 \
    zlib1g \
    libjpeg62-turbo \
    libtool \
    libxml2 \
    libxslt1.1 \
    libffi8 \
    python3 \
    python3-venv \
		python3-icu \
    pwgen

RUN rm -rf /var/lib/apt/* /var/cache/apt/*

RUN chown -R $MATRIX_UID:$MATRIX_GID /data
RUN chown -R $MATRIX_UID:$MATRIX_GID /uploads

COPY --from=builder /matrix /matrix
COPY --from=builder /synapse.version /synapse.version

RUN chown -R $MATRIX_UID:$MATRIX_GID /matrix
RUN chmod 777 /matrix
RUN chmod 777 /synapse.version

USER matrix

RUN python3 -m venv /matrix/venv
RUN . /matrix/venv/bin/activate

ENV PATH=/matrix/venv/bin:$PATH

EXPOSE 8448

ENTRYPOINT ["/start.sh"]
CMD ["autostart"]

#ENV LD_PRELOAD="/usr/lib/libjemalloc.so.2"
