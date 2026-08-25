# https://github.com/caddyserver/caddy-docker/blob/master/2.10/builder/Dockerfile
FROM golang:1.25-alpine3.22 AS base

RUN apk add --no-cache \
	curl \
	ca-certificates \
	git \
	libcap

ENV XCADDY_VERSION v0.4.5
# Configures xcaddy to build with this version of Caddy
# ENV CADDY_VERSION v2.10.0
# Configures xcaddy to not clean up post-build (unnecessary in a container)
ENV XCADDY_SKIP_CLEANUP 1
# Sets capabilities for output caddy binary to be able to bind to privileged ports
ENV XCADDY_SETCAP 1

# wget https://github.com/caddyserver/xcaddy/releases/latest/download/xcaddy_0.4.4_linux_arm64.tar.gz
RUN set -eux; \
	LATEST_TAG=$(curl -s https://api.github.com/repos/caddyserver/xcaddy/releases/latest | grep '"tag_name":' | sed -E 's/.*"tag_name": "v([^"]+)".*/\1/') \
	apkArch="$(apk --print-arch)"; \
		case "$apkArch" in \
			x86_64)  binArch='amd64' ;; \
			armhf)   binArch='armv6' ;; \
			armv7)   binArch='armv7' ;; \
			aarch64) binArch='arm64' ;; \
			ppc64el|ppc64le) binArch='ppc64le' ;; \
			riscv64) binArch='riscv64' ;; \
			s390x)   binArch='s390x' ;; \
			*) echo >&2 "error: unsupported architecture ($apkArch)"; exit 1 ;;\
		esac; \
	wget -O /tmp/xcaddy.tar.gz "https://github.com/caddyserver/xcaddy/releases/latest/download/xcaddy_${LATEST_TAG}_linux_${binArch}.tar.gz"; \
	tar x -z -f /tmp/xcaddy.tar.gz -C /usr/bin xcaddy; \
	rm -f /tmp/xcaddy.tar.gz; \
	chmod +x /usr/bin/xcaddy;

ARG CADDY_VERSION

# ARG XCADDY_GO_BUILD_FLAGS="-ldflags '-w -s -X github.com/caddyserver/caddy/v2.CustomVersion=shield' -trimpath -tags nobadger"
# /etc/caddy # caddy version
# shield v2.8.0-beta.2 => github.com/wolfsilver/shield/v2@v2.0.118-0.20240509133855-214167068f03 h1:B9olBXGQ2CMvSvVDroiaen2iENZrOT4k8nUJRyJ8aeQ=


RUN set -eux; echo ${CADDY_VERSION}

RUN set -eux; xcaddy build \
		--with github.com/caddyserver/caddy/v2=github.com/wolfsilver/shield/v2@SHIELD_TAG	 \
		--with github.com/caddyserver/forwardproxy@master=github.com/wolfsilver/forwardproxy@a54b9b8 \
		--with github.com/caddyserver/transform-encoder \
		--with github.com/mholt/caddy-l4=github.com/wolfsilver/caddy-l4@master \
		--with github.com/caddy-dns/cloudflare \
		--output /usr/bin/caddy
		# --with github.com/mholt/caddy-events-exec \
		# --with github.com/ueffel/caddy-brotli \

FROM caddy:alpine

COPY --from=base /usr/bin/caddy /usr/bin/caddy

# See https://caddyserver.com/docs/conventions#file-locations for details
ENV XDG_CONFIG_HOME /etc
ENV XDG_DATA_HOME /data


WORKDIR /etc/caddy

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
