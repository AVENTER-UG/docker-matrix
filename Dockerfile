# target architecture
ARG BASE_ARCH=${ARCH:-amd64}
FROM ${BASE_ARCH}/debian:buster-slim

# Maintainer
MAINTAINER Andreas Peters <support@aventer.biz>

# install homerserver template
COPY adds/start.sh /start.sh

# startup configuration
ENTRYPOINT ["/start.sh"]
CMD ["autostart"]
EXPOSE 8448

# Git branch to build from
ARG BV_SYN=release-v1.37
ARG BV_TUR=master
ARG TAG_SYN=v1.37.1


# user configuration
ENV MATRIX_UID=991 MATRIX_GID=991

# use --build-arg REBUILD=$(date) to invalidate the cache and upgrade all
# packages
ARG REBUILD=1
RUN set -ex \
    && export ARCH=`dpkg --print-architecture` \
    && export MARCH=`uname -m` \
    && mkdir /uploads \
    && export DEBIAN_FRONTEND=noninteractive \
    && mkdir -p /var/cache/apt/archives \
    && touch /var/cache/apt/archives/lock \
    && apt-get clean \
    && apt-get update -y -q --fix-missing\
    && apt-get upgrade -y \
    && buildDeps=" \
        rustc \
        cargo \
        file \
        gcc \
        git \
        libevent-dev \
        libffi-dev \
        libgnutls28-dev \
        libjpeg62-turbo-dev \
        libldap2-dev \
        libsasl2-dev \
        libsqlite3-dev \
        libssl-dev \
        libtool \
        libxml2-dev \
        libxslt1-dev \
        make \
        zlib1g-dev \
        python3-dev \
        python3-setuptools \
        libpq-dev \
    " \
    && apt-get install -y --no-install-recommends \
        $buildDeps \
        bash \
        coreutils \
        coturn \
        libffi6 \
        libjpeg62-turbo \
        libssl1.1 \
        libtool \
        libxml2 \
        libxslt1.1 \
        pwgen \
        python3 \
        python3-pip \
        python3-jinja2 \
        sqlite \
        zlib1g \
    ; \
    pip3 install --upgrade wheel ;\
    pip3 install --upgrade psycopg2;\
    pip3 install --upgrade python-ldap ;\
    pip3 install --upgrade twisted==21.2.0 ;\
    pip3 install --upgrade redis ;\
    pip3 install -e "git+https://github.com/t2bot/synapse-simple-antispam#egg=synapse-simple-antispam" ;\
    pip3 install -e "git+https://github.com/matrix-org/mjolnir.git#egg=mjolnir&subdirectory=synapse_antispam" ;\
    pip3 install --upgrade lxml \
    ; \
    groupadd -r -g $MATRIX_GID matrix \
    && mkdir /data \
    && useradd -r -d /data -M -u $MATRIX_UID -g matrix matrix \
    && chown -R $MATRIX_UID:$MATRIX_GID /data \
    && chown -R $MATRIX_UID:$MATRIX_GID /uploads \
    && git clone --branch $BV_SYN --depth 1 https://github.com/matrix-org/synapse.git \
    && cd /synapse \
    && git checkout -b tags/$TAG_SYN \
    && pip3 install --upgrade .[all] \
    && GIT_SYN=$(git ls-remote https://github.com/matrix-org/synapse $BV_SYN | cut -f 1) \
    && echo "synapse: $BV_SYN ($GIT_SYN)" >> /synapse.version \
    && cd / \
    && rm -rf /synapse \
    ; \
    apt-get autoremove -y $buildDeps ; \
    apt-get autoremove -y ;\
    ln -s /usr/lib/${MARCH}-linux-gnu/libjemalloc.so.2 /usr/lib/libjemalloc.so.2; \
    rm -rf /var/lib/apt/* /var/cache/apt/* \
    rm -rf /root/.cargo \
    rm -rf /root/.cache

USER matrix

#ENV LD_PRELOAD="/usr/lib/libjemalloc.so.2"
