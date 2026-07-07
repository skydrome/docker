# syntax=docker/dockerfile:1

ARG ALPINE_VERSION=3.24

# https://sourceforge.net/projects/tcl/files/Tcl
ARG TCL_VER=9.0.4
ARG TCL_MAJOR=9.0
ARG LLVM=22

ARG CC=clang
ARG CCWARN="-Wno-deprecated-non-prototype"
ARG CFLAGS="-O3 -pipe -march=armv7-a -mtune=cortex-a15 -mfpu=neon-vfpv4 -mfloat-abi=hard -fomit-frame-pointer -flto ${CCWARN}"
ARG LDFLAGS="-fuse-ld=mold -flto -rtlib=compiler-rt -Wl,-O2,--gc-sections,--strip-all,--as-needed,--sort-common -Wl,-z,relro -Wl,-z,now"

FROM --platform=$BUILDPLATFORM tonistiigi/xx AS xx
FROM --platform=$BUILDPLATFORM alpine:$ALPINE_VERSION AS cross_builder
COPY --link --from=xx / /

ARG BUILDPLATFORM TARGETPLATFORM TARGETOS TARGETARCH TARGETVARIANT TCL_VER TCL_MAJOR LLVM
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
        autoconf autoconf-archive automake clang libtool make patch pkgconf tree \
        git lld llvm mold
EOF
RUN --mount=type=cache,target=/var/cache/apk,sharing=locked <<EOF
set -ex
    xx-apk add --no-scripts \
        gcc musl-dev zlib-dev compiler-rt \
        openssl-dev bsd-compat-headers python3-dev
EOF

ARG CFLAGS LDFLAGS
ENV CFLAGS=$CFLAGS LDFLAGS=$LDFLAGS
ENV CC=xx-clang

RUN <<EOF
set -ex
    xx-clang --setup-target-triple
    xx-info env

    cd /usr/lib/llvm${LLVM}/lib/clang/${LLVM}/lib/$SYSROOT
    ln -s /$SYSROOT/usr/lib/llvm${LLVM}/lib/clang/${LLVM}/lib/$SYSROOT/libclang_rt.builtins-armhf.a libclang_rt.builtins.a
EOF

ADD  --link "src/tcl${TCL_VER}-src.tar.gz" .
COPY --link "src/thread.patch" .

RUN <<EOF
set -ex
cd tcl$TCL_VER
    cd pkgs
    rm -r itcl* tdbcodbc*
    patch -d thread* -Np1 -i /src/thread.patch

    cd ../unix
    ./configure \
        --host=$SYSROOT --build=$BUILDHOST \
        --prefix=/usr \
        --disable-64bit \
        --disable-symbols \
        --disable-rpath \
        --disable-zipfs

    make -j$(nproc)
    xx-verify tclsh
    make INSTALL_ROOT=/opt install install-private-headers
EOF
RUN <<EOF
set -ex
cd /opt/usr
    cd    bin && ln -sf  tclsh${TCL_MAJOR}    tclsh
    cd ../lib && ln -sf libtcl${TCL_MAJOR}.so libtcl.so
    rm -r /opt/usr/share

    sed -e "s|'/usr'|'/opt/usr'|" \
        -e "s|/src/tcl${TCL_VER}/unix|/opt/usr/lib|" \
        -e "s|/usr/lib|/opt/usr/lib|" \
        -e "s|/usr/include|/opt/usr/include|" \
        -i "/opt/usr/lib/tclConfig.sh"
EOF

ADD --keep-git-dir=true "https://github.com/eggheads/eggdrop.git" eggdrop
COPY --link src/egg-force-cross.patch .

RUN <<EOF
set -ex
cd eggdrop
    [[ ! -f configure ]] && ./autogen.sh
    patch -Np1 -i ../egg-force-cross.patch

    ./configure \
        --host=$SYSROOT --build=$BUILDHOST \
        --prefix=/eggdrop \
        --with-python-config=/$SYSROOT/usr/bin/python-config \
        --with-tcl=/opt/usr/lib \
        --enable-ipv6 \
        --enable-tls

    make config
    make -j$(nproc)
    xx-verify ./eggdrop

    make install
EOF

ADD --keep-git-dir=true \
    "https://github.com/bohagan1/TclTLS.git#6ec6b4987464cb25a948fd28c136e3497c52b6fa" tls
RUN <<EOF
set -ex
cd tls
    ./configure \
        --host=$SYSROOT --build=$BUILDHOST \
        --prefix=/usr --exec-prefix=/opt/usr \
        --enable-ssl-fastpath --disable-ssl3 --disable-tls1 --disable-tls1_1

    make binaries libraries
    make install-binaries install-libraries
EOF

ADD --keep-git-dir=true \
    "https://github.com/chpock/tdom.git#19d1d7b258588df3257938296f9c59eee561e4fb" tdom
RUN <<EOF
set -ex
cd tdom
    ./configure \
        --host=$SYSROOT --build=$BUILDHOST \
        --prefix=/usr --exec-prefix=/opt/usr

    make binaries libraries
    make install-binaries install-libraries

# cd extensions/tdomhtml
#    ./configure
EOF


FROM alpine:$ALPINE_VERSION AS qemu_builder
COPY --from=cross_builder /opt /opt
COPY --from=cross_builder /opt /

WORKDIR /src

RUN --mount=type=cache,target=/var/cache/apk,sharing=locked <<EOF
set -ex
    apk upgrade --update-cache
    apk add \
        make clang pkgconf tree lld llvm mold compiler-rt
EOF

ARG CFLAGS LDFLAGS
ENV CFLAGS="$CFLAGS -Wno-incompatible-pointer-types -Wno-switch -Wno-unused-value -Wno-return-type"
ENV LDFLAGS=$LDFLAGS
ENV AR=llvm-ar
ENV RANLIB=llvm-ranlib

ADD "https://github.com/andreas-kupries/critcl.git" critcl
RUN <<EOF
set -ex
cd critcl
    sed -i 's|gcc|clang|' lib/critcl/Config
    tclsh build.tcl install \
        --prefix /usr --dest-dir /opt
EOF

ADD "https://github.com/tcltk/tcllib.git" tcllib
RUN <<EOF
set -ex
cd tcllib
    tclsh ./installer.tcl \
        -pkgs -pkg-path /opt/usr/lib/tcllib \
        -apps -app-path /opt/usr/bin \
        -no-wait -no-gui -no-examples -no-nroff -no-html
EOF


FROM alpine:$ALPINE_VERSION
COPY --from=cross_builder /eggdrop /eggdrop
COPY --from=qemu_builder  /opt/usr /usr

RUN --mount=type=cache,target=/var/cache/apk,sharing=locked <<EOF
    apk upgrade --update-cache
    apk add \
        bash \
        busybox-extras \
        ca-certificates \
        coreutils \
        dropbear \
        libpq \
        lscpu \
        mariadb-connector-c \
        mimalloc2 \
        nano \
        procps \
        python3 \
        su-exec \
        tini \
        util-linux-misc \
        zlib

    # apk add ncdu libtree
    apk --purge del apk-tools && rm -rf /lib/apk /etc/apk /usr/share/apk
EOF

COPY --link entrypoint.sh /
COPY --link --chmod=600 src/ssh/authorized_keys           /root/.ssh/
COPY --link --chmod=600 src/ssh/dropbear_ed25519_host_key /etc/dropbear/
COPY --link --chmod=755 src/gen_ssl_cert.sh               /usr/bin/gen_ssl_cert

ENV PS1="\[\e[0;32m\]\u\[\e[0m\]:\[\e[0;34m\]\w\[\e[0m\]\$ "
SHELL ["/bin/bash", "-c"]
ARG TCL_MAJOR

RUN <<EOF
    PYTHON_VER=$(python -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')

    rm -rf \
        /etc/terminfo/{s,v,k,g,d} \
        /etc/{modprobe.d,network,udhcpd.conf,periodic} \
        /{home,media,mnt,opt,srv} \
        /lib/{sysctl.d,modules*,firmware} \
        /sbin/*disk \
        /eggdrop/modules-*/{filesys,share,notes,seen,assoc,uptime,ident,compress}.so \
        /eggdrop/{doc,scripts,language/*{dan,fin,fre,ger,ita,por}*} \
        /sbin/{hwclock,zramctl,*swap*,fsck*,mkfs*,blk*} \
        /usr/include \
        /usr/lib/*.a \
        /usr/lib/python$PYTHON_VER/{pydoc_data,ensurepip/_bundled,lib2to3} \
        /usr/lib/python$PYTHON_VER/encodings/{cp,euc,big,gb,mac}*.py \
        /usr/lib/tcl$TCL_MAJOR/encoding/{cp,cns,euc,ksc,big,gb,*jis,mac}*.enc \
        /usr/lib/critcl-*/critcl_c/tcl8.{6,7} \
        /usr/sbin/{update-ca-*,rtcwake,rfkill} \
        /usr/share/{man,udhcpc} \
        /var/{lib,tmp,opt,mail,local} \
        /var/spool

    ln -sf /dev/null /var/log/wtmp
    find /usr/lib/python$PYTHON_VER -iname "*opt-1.pyc" -type f -delete

    adduser -D -s /bin/bash -H -h /eggdrop-data eggdrop
    chown -R eggdrop:eggdrop /eggdrop
EOF

RUN <<EOF
/eggdrop/eggdrop -v

tclsh <<_versions
    puts "tcl       [info patchlevel]"
    puts "base64    [package require base64]"
    puts "blowfish  [package require blowfish]"
    puts "critcl    [package require critcl]"
    puts "htmlparse [package require htmlparse]"
    puts "http      [package require http]"
    puts "json      [package require json]"
    puts "msgcat    [package require msgcat]"
    puts "sha1      [package require sha1]"
    puts "sqlite    [package require sqlite3]"
    puts "tdom      [package require tdom]"
    puts "textutil  [package require textutil]"
    puts "thread    [package require thread]"
    puts "tls       [package require tls]"
    puts "websocket [package require websocket]"
    puts "tdbc::mysql    [package require tdbc::mysql]"
    puts "tdbc::postgres [package require tdbc::postgres]"
    puts "tdbc::sqlite3  [package require tdbc::sqlite3]"
_versions

    chmod 700 ~/.ssh
    dropbear -V
EOF

# start dropbear as root then drops to eggdrop user
USER root
VOLUME /eggdrop-data
ENTRYPOINT ["tini", "--", "/entrypoint.sh"]

LABEL org.opencontainers.image.source="https://github.com/skydrome/docker/tree/master/eggdrop"
LABEL org.opencontainers.image.description="Eggdrop arm32v7"
