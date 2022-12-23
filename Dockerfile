FROM golang:1.18-alpine3.17 AS builder

RUN set -e \
    && apk upgrade \
    && apk add jq curl git \
    && export GO111MODULE="on" \
    # && export GOPROXY="https://goproxy.cn,direct" \
    && export version=$(curl -s "https://api.github.com/repos/caddyserver/caddy/releases/latest" | jq -r .tag_name) \
    && echo ">>>>>>>>>>>>>>> ${version} ###############" \
    && go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest \
    && xcaddy build ${version} --output /caddy \
        --with github.com/caddy-dns/cloudflare \
        --with github.com/abiosoft/caddy-exec \
        --with github.com/greenpau/caddy-trace \
        --with github.com/hairyhenderson/caddy-teapot-module \
        --with github.com/kirsch33/realip \
        --with github.com/porech/caddy-maxmind-geolocation \
        --with github.com/caddyserver/transform-encoder \
        --with github.com/caddyserver/replace-response \
        --with github.com/imgk/caddy-trojan

FROM alpine:3.17 AS dist
ENV XDG_CONFIG_HOME /config
ENV XDG_DATA_HOME /data
ENV TZ Asia/Shanghai

COPY --from=builder /caddy /usr/bin/caddy
ADD ./Caddyfile /etc/caddy/Caddyfile
ADD ./index.html /usr/share/caddy/index.html

RUN set -e \
    && apk upgrade \
    && apk add bash tzdata mailcap \
    && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && rm -rf /var/cache/apk/*

VOLUME /config
VOLUME /data

EXPOSE 80
EXPOSE 443

WORKDIR /srv

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
