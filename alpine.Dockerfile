ARG ALPINE_VERSION=3.9
ARG BDB_VERSION=5.1.29.NC
ARG BDB_SHA256SUM=08238e59736d1aacdd47cfb8e68684c695516c37f4fbe1b8267dde58dc3a576c
FROM alpine:${ALPINE_VERSION} AS bdb

ARG BDB_VERSION
ARG BDB_SHA256SUM

RUN apk upgrade && apk add \
  build-base autoconf automake

ADD http://download.oracle.com/berkeley-db/db-${BDB_VERSION}.tar.gz ./

RUN \
  echo "${BDB_SHA256SUM}  db-${BDB_VERSION}.tar.gz" | sha256sum -c - && \
  tar xf db-${BDB_VERSION}.tar.gz

WORKDIR /db-${BDB_VERSION}/build_unix

RUN \
  sed s/__atomic_compare_exchange/__atomic_compare_exchange_db/g -i ../src/dbinc/atomic.h && \
  ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=/usr/local/bdb && \
  make -s -j3 && \
  make install


FROM alpine:${ALPINE_VERSION} AS build

RUN apk upgrade && apk add \
  build-base autoconf automake libtool pkgconfig \
  boost-dev \
  libevent-dev \
  openssl-dev \
  zeromq-dev \
  python2

WORKDIR /work

COPY --from=bdb /usr/local/bdb /usr/local/bdb
COPY . .

RUN ./autogen.sh

WORKDIR /work/build

RUN \
  ../configure --without-gui \
      --without-miniupnpc \
      --disable-bench \
      --disable-ccache \
      --disable-maintainer-mode \
      --disable-dependency-tracking \
      --disable-tests \
      CFLAGS="-O2 -g" \
      CXXFLAGS="-Wno-cpp -O2 -g" \
      LDFLAGS="-L/usr/local/bdb/lib/ -static-libstdc++" \
      CPPFLAGS="-I/usr/local/bdb/include/"

RUN make -s -j3

RUN \
  make install && \
  strip /usr/local/bin/dogecoin*


FROM alpine:${ALPINE_VERSION}

RUN apk add --no-cache \
  boost \
  boost-program_options \
  libevent \
  libzmq \
  openssl

COPY --from=build \
  /usr/local/bin/dogecoind \
  /usr/local/bin/dogecoin-cli \
  /usr/local/bin/dogecoin-tx \
  /usr/local/bin/

RUN addgroup -S dogecoin && adduser -S dogecoin -G dogecoin

USER dogecoin

RUN mkdir -p /home/dogecoin/.dogecoin

VOLUME ["/home/dogecoin/.dogecoin"]

EXPOSE 22555 22556 44555 44556

ENTRYPOINT ["dogecoind"]
