#
#  Author: Hari Sekhon 
# Updated by: Mujtaba Idrees
#  Date: 2018-11-27 

#  vim:ts=4:sts=4:sw=4:et
#
#  https://github.com/harisekhon/Dockerfiles/hbase
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback
#
#  https://www.linkedin.com/in/harisekhon
#

FROM harisekhon/alpine-github:latest
MAINTAINER Hari Sekhon (https://www.linkedin.com/in/harisekhon)

#ARG HBASE_VERSION=0.94.27
#ARG HBASE_VERSION=0.96.2
#ARG HBASE_VERSION=0.98.23
#ARG HBASE_VERSION=1.0.3
#ARG HBASE_VERSION=1.1.7
ARG HBASE_VERSION=1.2.6

ENV PATH $PATH:/hbase/bin

ENV JAVA_HOME=/usr

LABEL Description="HBase Dev", \
      "HBase Version"="$HBASE_VERSION"

WORKDIR /

RUN set -euxo pipefail && \
    apk add --no-cache wget && \
    # older versions have to use apache archive
    # HBase 0.90, 0.92, 0.94
    if  [ "${HBASE_VERSION:0:4}" = "0.90" -o \
          "${HBASE_VERSION:0:4}" = "0.92" -o \
          "${HBASE_VERSION:0:4}" = "0.94" ]; then \
        url="http://www.apache.org/dyn/closer.lua?filename=hbase/hbase-$HBASE_VERSION/hbase-$HBASE_VERSION.tar.gz&action=download"; \
        url_archive="http://archive.apache.org/dist/hbase/hbase-$HBASE_VERSION/hbase-$HBASE_VERSION.tar.gz"; \
    # HBase 0.95 / 0.96
    elif [ "${HBASE_VERSION:0:4}" = "0.95" -o "${HBASE_VERSION:0:4}" = "0.96" ]; then \
        url="https://archive.apache.org/dist/hbase/hbase-$HBASE_VERSION/hbase-$HBASE_VERSION-hadoop2-bin.tar.gz"; \
        url_archive="http://archive.apache.org/dist/hbase/hbase-$HBASE_VERSION/hbase-$HBASE_VERSION-hadoop2-bin.tar.gz"; \
    # HBase 0.98
    elif [ "${HBASE_VERSION:0:4}" = "0.98" ]; then \
        url="http://www.apache.org/dyn/closer.lua?filename=hbase/$HBASE_VERSION/hbase-$HBASE_VERSION-hadoop2-bin.tar.gz&action=download"; \
        url_archive="http://archive.apache.org/dist/hbase/$HBASE_VERSION/hbase-$HBASE_VERSION-hadoop2-bin.tar.gz"; \
    # HBase 0.99 / 1.0
    elif [ "${HBASE_VERSION:0:4}" = "0.99" -o "${HBASE_VERSION:0:3}" = "1.0" ]; then \
        url="http://www.apache.org/dyn/closer.lua?filename=hbase/hbase-$HBASE_VERSION/hbase-$HBASE_VERSION-bin.tar.gz&action=download"; \
        url_archive="http://archive.apache.org/dist/hbase/hbase-$HBASE_VERSION/hbase-$HBASE_VERSION-bin.tar.gz"; \
    # HBase 1.1+
    else \
        url="http://www.apache.org/dyn/closer.lua?filename=hbase/$HBASE_VERSION/hbase-$HBASE_VERSION-bin.tar.gz&action=download"; \
        url_archive="http://archive.apache.org/dist/hbase/$HBASE_VERSION/hbase-$HBASE_VERSION-bin.tar.gz"; \
    fi && \
    # --max-redirect - some apache mirrors redirect a couple times and give you the latest version instead
    #                  but this breaks stuff later because the link will not point to the right dir
    #                  (and is also the wrong version for the tag)
    wget -t 10 --max-redirect 1 --retry-connrefused -O "hbase-$HBASE_VERSION-bin.tar.gz" "$url" || \
    wget -t 10 --max-redirect 1 --retry-connrefused -O "hbase-$HBASE_VERSION-bin.tar.gz" "$url_archive" && \
    mkdir "hbase-$HBASE_VERSION" && \
    tar zxf "hbase-$HBASE_VERSION-bin.tar.gz" -C "hbase-$HBASE_VERSION" --strip 1 && \
    test -d "hbase-$HBASE_VERSION" && \
    ln -sv "hbase-$HBASE_VERSION" hbase && \
    rm -fv "hbase-$HBASE_VERSION-bin.tar.gz" && \
    { rm -rf hbase/{docs,src}; : ; } && \
    mkdir /hbase-data && \
    apk del wget

# Needed for HBase 2.0+ hbase-shell
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    apk update && \
    apk add jruby && \
    apk add jruby-irb # jruby-maven jruby-minitest jruby-rdoc jruby-rake jruby-testunit


COPY entrypoint.sh /
RUN chmod +x entrypoint.sh
COPY conf/hbase-site.xml /hbase/conf/
COPY profile.d/java.sh /etc/profile.d/
COPY hbase_init.txt /

# Stargate  8080  / 8085
# Thrift    9090  / 9095
# HMaster   16000 / 16010
# RS        16201 / 16301
EXPOSE 2181 8080 8085 9090 9095 16000 16010 16201 16301

CMD "/entrypoint.sh"
