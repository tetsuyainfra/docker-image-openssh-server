FROM debian:trixie-slim
ARG S6_OVERLAY_VERSION=3.2.1.0
ARG S6_OVERLAY_NOARCH_HASH=sha256:42e038a9a00fc0fef70bf0bc42f625a9c14f8ecdfe77d4ad93281edf717e10c5  s6-overlay-noarch.tar.xz
ARG S6_OVERLAY_ARCH_HASH=sha256:8bcbc2cada58426f976b159dcc4e06cbb1454d5f39252b3bb0c778ccf71c9435  s6-overlay-x86_64.tar.xz
ARG S6_OVERLAY_ARCH_NAME=s6-overlay-x86_64.tar.xz
# ARG S6_OVERLAY_SYSLOGD_HASH=sha256:0bc6e41f1559d99b9ba8db7f159d001a98b856927e367508f5beb5575f3dabde  syslogd-overlay-noarch.tar.xz

ARG JINJA_VERSION=2.12.0
ARG JINJA_NAME=minijinja-cli-x86_64-unknown-linux-gnu.tar.xz
ARG JINJA_TEMPLATE_HASH="sha256:388a2442d013766fc9fafad339e60c6019389765895079dc04e1c35b6c3a417e"


RUN set -eux; \
    env ; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
            openssh-server xz-utils tzdata ; \
    DEBIAN_FRONTEND=noninteractive apt-get remove --purge --auto-remove -y; \
    rm -rf /var/lib/apt/lists/* ; \
    # create manifest \
    mkdir -p /usr/share/rocks ; \
    # rm SSH HOST Public Key \
    mkdir -p /var/run/sshd ; \
    chmod 750 /var/run/sshd ; \
    rm -rf /etc/ssh/ssh_host_* ; \
    (dpkg-query -f '${binary:Package},${Version}\n' -W | sort) > /usr/share/rocks/packages.list ; \
    # set locale
    # echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen ; \
    # locale-gen en_US ; \
    # update-locale LANG=en_US.UTF-8 LC_CTYPE=en_US.UTF-8 ; \
    # echo -n en_US.UTF-8 > /etc//LANG ; \
    # echo -n en_US.UTF-8 > /etc//LC_CTYPE ; \
    mkdir /data ; \
    true

VOLUME [ "/etc/ssh", "/chroot" ]

# COPY root/ /


# -d : Debug mode 一度しか接続できないので注意
# CMD ["/usr/sbin/sshd", "-D", "-e", "-d"]
# CMD ["/usr/sbin/sshd", "-D", "-e"]


ADD --checksum=${JINJA_TEMPLATE_HASH} https://github.com/mitsuhiko/minijinja/releases/download/${JINJA_VERSION}/${JINJA_NAME} /tmp
RUN tar -C /usr/local/bin -Jxpf /tmp/${JINJA_NAME} --strip-components=1 ${JINJA_NAME%.tar.xz}/minijinja-cli

ADD --checksum=${S6_OVERLAY_NOARCH_HASH} https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD --checksum=${S6_OVERLAY_ARCH_HASH}  https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/${S6_OVERLAY_ARCH_NAME} /tmp
RUN tar -C / -Jxpf /tmp/${S6_OVERLAY_ARCH_NAME}

ENTRYPOINT ["/init"]

COPY root/ /