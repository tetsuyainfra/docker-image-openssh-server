########################################################################################################################
# build stage
FROM busybox:1 AS buildstage
ARG S6_OVERLAY_VERSION
ARG S6_OVERLAY_NOARCH_NAME
ARG S6_OVERLAY_NOARCH_HASH
ARG S6_OVERLAY_ARCH_HASH
ARG S6_OVERLAY_ARCH_NAME

ARG JINJA_VERSION
ARG JINJA_HASH
ARG JINJA_NAME

## Setup s6-overlay
# dockerfile-utils: ignore
ADD --unpack=true --checksum=${S6_OVERLAY_NOARCH_HASH} https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/${S6_OVERLAY_NOARCH_NAME} /rootfs
# dockerfile-utils: ignore
ADD --unpack=true --checksum=${S6_OVERLAY_ARCH_HASH}  https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/${S6_OVERLAY_ARCH_NAME} /rootfs

## Setup minijinja
ADD --checksum=${JINJA_HASH} https://github.com/mitsuhiko/minijinja/releases/download/${JINJA_VERSION}/${JINJA_NAME} /tmp
RUN mkdir -p /rootfs/usr/local/bin
RUN tar -C /rootfs/usr/local/bin -Jxpf /tmp/${JINJA_NAME} --strip-components=1 ${JINJA_NAME%.tar.xz}/minijinja-cli

########################################################################################################################
# Main stage
FROM debian:trixie-slim
ARG CRON_BUILDTIME=no

RUN  --mount=type=cache,target=/var/cache/apt,sharing=locked \
     --mount=type=cache,target=/var/lib/apt,sharing=locked  <<EOF
set -eux
# cronで実行している時間を受け取り、RUN内で呼び出すことでキャッシュが確実に効かないようにする
echo "CRON_BUILDTIME: ${CRON_BUILDTIME}"
env
# apt-get clean が動作しないようにする
rm /etc/apt/apt.conf.d/docker-clean
# キャッシュの保持を強制
echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
apt-get update
apt-mark hold systemd
DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends openssh-server
DEBIAN_FRONTEND=noninteractive apt-get remove --purge --auto-remove -y
# Create manifest
mkdir -p /usr/share/rocks
# Remoe SSH HOST Public Key
mkdir -p /var/run/sshd
chmod 750 /var/run/sshd
rm -rf /etc/ssh
(dpkg-query -f '${binary:Package},${Version}\n' -W | sort) > /usr/share/rocks/packages.list
mkdir /config
mkdir /chroot
EOF

VOLUME [ "/config", "/chroot" ]

COPY --from=buildstage /rootfs/ /
COPY root/ /

# -d : Debug mode 一度しか接続できないので注意
# CMD ["/usr/sbin/sshd", "-D", "-e", "-d"]
# CMD ["/usr/sbin/sshd", "-f", "/config/sshd_config", "-D", "-e", "-d"] # デバッグモード
# CMD ["/usr/sbin/sshd", "-f", "/config/sshd_config", "-D", "-e"]
ENTRYPOINT ["/init"]
