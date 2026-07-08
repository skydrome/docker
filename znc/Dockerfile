# syntax=docker/dockerfile:1

# TODO
# https://github.com/microsoft/mimalloc

ARG ALPINE_VERSION=3.24
ARG LLVM=22

ARG CCWARN="-Wno-deprecated-non-prototype -Wno-deprecated-declarations"
ARG CXXFLAGS="-O3 -pipe -march=armv7-a -mtune=cortex-a15 -mfpu=neon-vfpv4 -fomit-frame-pointer -flto -stdlib=libc++ -DNDEBUG ${CCWARN}"
ARG LDFLAGS="-fuse-ld=mold -rtlib=compiler-rt -unwindlib=libunwind -flto -Wl,-O2,--gc-sections,--strip-all,--as-needed,--sort-common -Wl,-z,relro -Wl,-z,now"

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

RUN --mount=type=cache,target=/var/cache/apk,sharing=locked <<EOF
set -ex
    apk upgrade --update-cache
    apk add \
       libc++-dev compiler-rt clang cmake git lld llvm llvm-libunwind-dev \
       make mold patch pkgconf tree
EOF
RUN --mount=type=cache,target=/var/cache/apk,sharing=locked <<EOF
set -ex
    xx-apk add \
        g++ libc++-dev musl-dev compiler-rt llvm-libunwind-dev \
        argon2-dev cyrus-sasl-dev openssl-dev zlib-dev
EOF

ARG CXXFLAGS LDFLAGS
ENV CXXFLAGS=$CXXFLAGS LDFLAGS=$LDFLAGS

RUN <<EOF
set -ex
    xx-clang --setup-target-triple
    xx-info env
    env

    cd /usr/lib/llvm${LLVM}/lib/clang/${LLVM}/lib/$SYSROOT
    ln -s /$SYSROOT/usr/lib/llvm${LLVM}/lib/clang/${LLVM}/lib/$SYSROOT/libclang_rt.builtins-armhf.a libclang_rt.builtins.a
EOF

ADD --keep-git-dir=true --chmod=777 \
    "https://github.com/znc/znc.git" znc
ADD "https://github.com/Cizzle/znc-autoinvitejoin.git" znc-autoinvitejoin
ADD "https://github.com/CyberShadow/znc-clientbuffer.git" znc-clientbuffer
ADD "https://github.com/schizoidsaddam/crypt2.git" znc-crypt2
# ADD "https://github.com/ZarTek-Creole/mod-znc-fish.git" znc-fish
ADD "https://github.com/fred0r/znc-fish.git" znc-fish
# COPY --link "src/fish.patch" .

RUN <<EOF
set -ex
# patch -d /src/znc-fish -Np1 -i /src/fish.patch

cd znc/modules
    ln -s ../../znc-autoinvitejoin/autoinvitejoin.cpp .
    ln -s ../../znc-clientbuffer/clientbuffer.cpp .
    ln -s ../../znc-crypt2/crypt2.cpp .
    ln -s ../../znc-fish/fish.cpp .

cd ..
    cmake -B build -Dcxx17check=1 \
        $(xx-clang --print-cmake-defines) \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_LIBRARY_PATH=/$SYSROOT/usr/lib \
        -DCMAKE_SYSTEM_INCLUDE_PATH=/$SYSROOT/usr/include \
        -DWANT_ARGON=ON \
        -DWANT_CYRUS=ON \
        -DWANT_I18N=OFF \
        -DWANT_ICU=OFF \
        -DWANT_OPENSSL=ON \
        -DWANT_ZLIB=ON \
    . || cat build/CMakeFiles/CMakeError.log

    cmake --build build --parallel $(nproc)
    DESTDIR=/opt cmake --install build
EOF
RUN <<EOF
set -e
cd /opt/usr
    rm -r \
        include \
        share/man \
        share/znc/cmake \
        share/znc/translations \
        share/znc/webskins/dark-clouds \
        share/znc/webskins/ice

    xx-verify bin/znc
    tree .
EOF


FROM alpine:$ALPINE_VERSION
COPY --from=builder /opt/usr /usr

RUN --mount=type=cache,target=/var/cache/apk,sharing=locked <<EOF
    apk upgrade --update-cache
    apk add \
        argon2-libs \
        ca-certificates \
        libssl3 \
        libc++ \
        llvm-libunwind \
        mimalloc2 \
        su-exec \
        zlib

    # apk add ncdu libtree
    apk --purge del apk-tools && rm -rf /lib/apk /etc/apk /usr/share/apk
EOF

COPY --link entrypoint.sh /

RUN <<EOF
    rm -r \
        /etc/modprobe.d \
        /etc/network \
        /home \
        /media \
        /mnt \
        /opt \
        /srv \
        /usr/local \
        /usr/sbin/update-ca-certificates \
        /usr/share/udhcpc \
        /var/lib \
        /var/spool

    adduser -D -s /bin/ash -H -h /znc-data znc
    znc --version
EOF

USER znc
VOLUME /znc-data
ENTRYPOINT ["/entrypoint.sh"]

LABEL org.opencontainers.image.source="https://github.com/skydrome/docker/tree/master/znc"
LABEL org.opencontainers.image.description="ZNC arm32v7"
