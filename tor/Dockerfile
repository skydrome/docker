# syntax=docker/dockerfile:1

ARG ALPINE_VERSION=3.23
ARG LLVM=21

ARG CC=xx-clang
ARG CCWARN="-Wno-deprecated-non-prototype -Wno-shorten-64-to-32 -Wno-format"
ARG CFLAGS="-O3 -pipe -march=armv7-a -mtune=cortex-a15 -mfpu=neon-vfpv4 -mfloat-abi=hard -fomit-frame-pointer -flto ${CCWARN}"
ARG LDFLAGS="-fuse-ld=mold -flto -rtlib=compiler-rt -Wl,-O2,--gc-sections,--strip-all,--as-needed,--sort-common -Wl,-z,relro -Wl,-z,now"

FROM --platform=$BUILDPLATFORM tonistiigi/xx AS xx
FROM --platform=$BUILDPLATFORM alpine:$ALPINE_VERSION AS builder
COPY --link --from=xx / /

ARG BUILDPLATFORM TARGETPLATFORM TARGETOS TARGETARCH TARGETVARIANT LLVM
#    linux/amd64   linux/arm/v7   linux      arm         v7
ENV BUILDPLATFORM=$BUILDPLATFORM
ENV TARGETPLATFORM=$TARGETPLATFORM
ENV TARGETOS=$TARGETOS
ENV TARGETARCH=$TARGETARCH
ENV TARGETVARIANT=$TARGETVARIANT

ARG SYSROOT=armv7-alpine-linux-musleabihf
ARG BUILDHOST=x86_64-alpine-linux-musl

WORKDIR /src

RUN --mount=type=cache,target=/var/cache/apk <<EOF
set -ex
    apk upgrade --update-cache
    apk add \
        autoconf autoconf-archive automake clang libtool make patch pkgconf tree \
        git lld llvm mold
EOF
RUN --mount=type=cache,target=/var/cache/apk <<EOF
set -ex
    xx-apk add --no-scripts \
        gcc musl-dev zlib-dev compiler-rt \
        jemalloc-dev libcap-dev libevent-dev libgcrypt-dev libseccomp-dev openssl-dev xz-dev  zstd-dev
EOF

ARG CC CFLAGS LDFLAGS
ENV CC=$CC CFLAGS=$CFLAGS LDFLAGS=$LDFLAGS

RUN <<EOF
set -ex
    xx-clang --setup-target-triple
    xx-info env

    cd /usr/lib/llvm${LLVM}/lib/clang/${LLVM}/lib/$SYSROOT
    ln -s /$SYSROOT/usr/lib/llvm${LLVM}/lib/clang/${LLVM}/lib/$SYSROOT/libclang_rt.builtins-armhf.a libclang_rt.builtins.a
EOF

#ADD "https://github.com/technion/libscrypt.git" scrypt
#RUN <<EOF
#set -ex
#cd scrypt
#    CFLAGS_EXTRA=$CFLAGS LDFLAGS_EXTRA=$LDFLAGS make -j$(nproc)
#    PREFIX=/$SYSROOT/usr make install install-static
#    PREFIX=/opt/usr make install
#    tree /opt/usr
#EOF

ADD --keep-git-dir=true "https://gitlab.torproject.org/tpo/core/tor.git#maint-0.4.8" tor

RUN <<EOF
set -ex
cd tor
    [[ ! -f configure ]] && ./autogen.sh

    ./configure \
        --host=$SYSROOT --build=$BUILDHOST \
        --prefix=/usr \
        --disable-all-bugs-are-fatal \
        --disable-android \
        --disable-asciidoc \
        --disable-coverage \
        --disable-gcc-hardening \
        --disable-html-manual \
        --disable-libfuzzer \
        --disable-linker-hardening \
        --disable-manpage \
        --disable-module-relay \
        --disable-restart-debugging \
        --disable-systemd \
        --disable-unittests \
        --enable-gpl \
        --disable-libscrypt \
        --enable-lzma \
        --enable-module-pow \
        --enable-pic \
        --enable-seccomp \
        --enable-year2038 \
        --enable-zstd \
        --with-tor-group=tor \
        --with-tor-user=tor \
        --with-malloc=jemalloc

    make -j$(nproc)
    xx-verify src/app/tor
    DESTDIR=/opt make install
    tree /opt/usr
EOF


FROM arm32v7/alpine:$ALPINE_VERSION
COPY --from=builder /opt/usr /usr

RUN --mount=type=cache,target=/var/cache/apk,sharing=locked <<EOF
    apk upgrade --update-cache
    apk add \
        jemalloc \
        libcap \
        libevent \
        libseccomp \
        libssl3 \
        netcat-openbsd \
        su-exec \
        tini \
        xz-libs \
        zlib \
        zstd-libs

    # apk add ncdu libtree
    apk --purge del apk-tools && rm -rf /lib/apk /etc/apk /usr/share/apk
EOF

COPY --link entrypoint.sh /

RUN <<EOF
    rm -rf \
        /etc/modprobe.d \
        /etc/network \
        /home \
        /media \
        /mnt \
        /opt \
        /srv \
        /usr/bin/jeprof \
        /usr/include \
        /usr/local \
        /usr/share/udhcpc \
        /var/spool

    adduser -D -S -h /var/lib/tor tor
    tor --version
EOF

USER tor
VOLUME /tor-data
ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
