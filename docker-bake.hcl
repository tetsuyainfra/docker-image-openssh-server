
variable "HTTP_PROXY" {
    type    = string
    default = null
}

variable "HTTPS_PROXY" {
    type    = string
    default = null
}

variable "CRON_BUILDTIME" {
    type    = string
    default = null
}

variable "TAG" {
    type    = string
    default = null
}

variable "BUILD_TIMESTAMP" {
    type    = string
    default = "${ timestamp() }"
}

variable "BUILD_DATETIME" {
    type    = string
    default = "${formatdate("YYYYMMDD_HHMMss", BUILD_TIMESTAMP)}"
}

group "default" {
    targets = ["amd64"]
}

group "all" {
    targets = ["amd64", "arm64"]
}


target "_common" {
    context = "./src"
    dockerfile = "Dockerfile"
    tags = [
            "tetsuyainfra/openssh-server:trixie-latest",
            "tetsuyainfra/openssh-server:trixie-${BUILD_DATETIME}"
    ]
    args = {
        HTTP_PROXY = HTTP_PROXY
        HTTPS_PROXY = HTTPS_PROXY

        CRON_BUILDTIME = CRON_BUILDTIME

        S6_OVERLAY_VERSION = "3.2.1.0"
        S6_OVERLAY_NOARCH_NAME = "s6-overlay-noarch.tar.xz"
        S6_OVERLAY_NOARCH_HASH = "sha256:42e038a9a00fc0fef70bf0bc42f625a9c14f8ecdfe77d4ad93281edf717e10c5"

        JINJA_VERSION = "2.12.0"

    }
}

target "amd64" {
    inherits = ["_common"]
    platforms = ["linux/amd64"]
    tags = [
        "tetsuyainfra/openssh-server:trixie-latest",
        "tetsuyainfra/openssh-server:trixie-latest-amd64",
        "tetsuyainfra/openssh-server:trixie-${BUILD_DATETIME}-amd64"
    ]
    args = {
        S6_OVERLAY_ARCH_NAME="s6-overlay-x86_64.tar.xz"
        S6_OVERLAY_ARCH_HASH="sha256:8bcbc2cada58426f976b159dcc4e06cbb1454d5f39252b3bb0c778ccf71c9435"

        JINJA_NAME = "minijinja-cli-x86_64-unknown-linux-gnu.tar.xz"
        JINJA_HASH = "sha256:388a2442d013766fc9fafad339e60c6019389765895079dc04e1c35b6c3a417e"
    }
}

target "arm64" {
    inherits = ["_common"]
    platforms = ["linux/arm64"]
    tags = [
        "tetsuyainfra/openssh-server:trixie-latest",
        "tetsuyainfra/openssh-server:trixie-latest-arm64",
        "tetsuyainfra/openssh-server:trixie-${BUILD_DATETIME}-arm64"
    ]
    args = {
        S6_OVERLAY_ARCH_NAME="s6-overlay-aarch64.tar.xz"
        S6_OVERLAY_ARCH_HASH="sha256:c8fd6b1f0380d399422fc986a1e6799f6a287e2cfa24813ad0b6a4fb4fa755cc"

        JINJA_NAME = "minijinja-cli-aarch64-unknown-linux-gnu.tar.xz"
        JINJA_HASH = "sha256:1f795c34a9e32279864356c79fe191348dae833381f33107e5db7526f855c0b3"
    }
}
