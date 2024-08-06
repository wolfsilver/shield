FROM caddy:builder-alpine as base

# use cf go https://github.com/cloudflare/go
RUN apk add --no-cache bash \
	&& cd /root \
	&& git clone https://github.com/cloudflare/go \
	&& cd go/src \
	&& ./make.bash \
	# add /root/go/bin to PATH
	&& echo 'export PATH=/root/go/bin:$PATH' >> /root/.bashrc

ENV PATH /root/go/bin:$PATH

ARG CADDY_VERSION

# ARG XCADDY_GO_BUILD_FLAGS="-ldflags '-w -s -X github.com/caddyserver/caddy/v2.CustomVersion=shield' -trimpath -tags nobadger"
# /etc/caddy # caddy version
# shield v2.8.0-beta.2 => github.com/wolfsilver/shield/v2@v2.0.118-0.20240509133855-214167068f03 h1:B9olBXGQ2CMvSvVDroiaen2iENZrOT4k8nUJRyJ8aeQ=


RUN set -eux; echo ${CADDY_VERSION}

RUN set -eux; xcaddy build \
		--with github.com/caddyserver/caddy/v2=github.com/wolfsilver/shield/v2@SHIELD_TAG	 \
		--with github.com/caddyserver/forwardproxy@master=github.com/wolfsilver/forwardproxy@efac36f \
		--with github.com/caddyserver/transform-encoder \
		--with github.com/mholt/caddy-events-exec \
		--with github.com/caddy-dns/cloudflare \
		--output /usr/bin/caddy
		# --with github.com/ueffel/caddy-brotli \

FROM caddy:alpine

COPY --from=base /usr/bin/caddy /usr/bin/caddy

# See https://caddyserver.com/docs/conventions#file-locations for details
ENV XDG_CONFIG_HOME /etc
ENV XDG_DATA_HOME /data


WORKDIR /etc/caddy

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
