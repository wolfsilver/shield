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

# ENV CADDY_VERSION v2.7.4

RUN set -eux; xcaddy build \
		--with github.com/caddyserver/caddy/v2=github.com/wolfsilver/shield/v2@SHIELD_TAG	 \
		--with github.com/caddyserver/forwardproxy@master=github.com/wolfsilver/forwardproxy@naive \
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
