FROM debian:8-slim
LABEL MAINTAINER "Jose Moreira <josemoreiravarzim@gmail.com>"

RUN echo "deb http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list \
    && apt-get update \
    && apt-get -t jessie-backports install "gosu" \
    && apt-get install -y --no-install-recommends \
        ca-certificates wget curl rsync \
        git subversion \
        build-essential g++ \
        python time unzip file gawk ccache  gettext  xsltproc \
        libssl-dev libncurses5-dev zlib1g-dev \
    && apt-get autoclean \
    && apt-get clean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

ADD entrypoint.sh /entrypoint
RUN chmod 755 /entrypoint

RUN mkdir -p /src /output
WORKDIR /src
ENTRYPOINT ["/entrypoint"]
CMD ["/bin/bash"]