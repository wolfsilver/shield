FROM caddy:builder-alpine as base

# ENV CADDY_VERSION v2.7.4

RUN set -eux; xcaddy build \
		--with github.com/caddyserver/caddy/v2=github.com/wolfsilver/shield/v2@v2.0.106	 \
		--with github.com/caddyserver/forwardproxy@caddy2=github.com/wolfsilver/forwardproxy@3036edc \
		--with github.com/caddyserver/transform-encoder \
		--with github.com/mholt/caddy-events-exec \
		--with github.com/caddy-dns/cloudflare \
		--with github.com/ueffel/caddy-brotli \
		--output /usr/bin/caddy

FROM caddy:alpine

COPY --from=base /usr/bin/caddy /usr/bin/caddy

# See https://caddyserver.com/docs/conventions#file-locations for details
ENV XDG_CONFIG_HOME /etc
ENV XDG_DATA_HOME /data


WORKDIR /etc/caddy

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
