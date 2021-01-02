FROM alpine:3.12

ARG RUBY_VERSION

# Building required Ruby version from sources
RUN set -ex \
  && apk add --no-cache --virtual .ruby-builddeps \
    autoconf \
    bison \
    bzip2 \
    bzip2-dev \
    ca-certificates \
    coreutils \
    dpkg-dev \
    dpkg \
    gcc \
    gdbm-dev \
    glib-dev \
    libc-dev \
    libffi-dev \
    libxml2-dev \
    libxslt-dev \
    linux-headers \
    make \
    ncurses-dev \
    openssl \
    openssl-dev \
    patch \
    procps \
    readline-dev \
    tar \
    xz \
    yaml-dev \
    zlib-dev \
  \
  && mkdir -p /tmp/ruby \
  && cd /tmp/ruby \
  && wget -nv -O - "https://cache.ruby-lang.org/pub/ruby/${RUBY_VERSION:0:3}/ruby-${RUBY_VERSION}.tar.xz" | tar -Jx \
  && cd ruby-${RUBY_VERSION} \
# hack in "ENABLE_PATH_CHECK" disabling to suppress:
#   warning: Insecure world writable dir
  && { \
    echo '#define ENABLE_PATH_CHECK 0'; \
    echo; \
    cat file.c; \
  } > file.c.new \
  && mv file.c.new file.c \
  \
  && autoconf \
  && export gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
# the configure script does not detect isnan/isinf as macros
  && ac_cv_func_isnan=yes ac_cv_func_isinf=yes \
    ./configure \
      --build="${gnuArch}" \
      --disable-install-doc \
      --enable-shared \
  && make -j"$(getconf _NPROCESSORS_ONLN)" \
  && make install \
  \
  && runDeps="$( \
    scanelf --needed --nobanner --recursive /usr/local \
      | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
      | sort -u \
      | xargs -r apk info --installed \
      | sort -u \
  )" \
  && apk del --no-network .ruby-builddeps \
  && apk add --virtual .ruby-rundeps $runDeps \
    bzip2 \
    ca-certificates \
    libffi-dev \
    libressl-dev \
    yaml-dev \
    procps \
    zlib-dev \
  && cd / \
  && rm -r /tmp/ruby \
  ## rough smoke test
  && ruby --version \
  && echo "gem version $(gem --version)"
  # && echo "Ruby installed"

RUN echo "gem: --no-document" >> ~/.gemrc
