FROM alpine:latest as atomicparsleybuild

RUN apk --update --no-cache add cmake g++ jq linux-headers make zlib-dev

RUN wget -qO - `wget -qO - "https://api.github.com/repos/wez/atomicparsley/releases/latest" | jq -r .tarball_url` | tar -zx --strip-components=1 && cmake . && cmake --build . --config Release --target install/strip


FROM alpine:latest
# Fork from Jonathan Harris <jonathan@marginal.org.uk>
MAINTAINER Brian Russell
ENV GETIPLAYER_OUTPUT=/output GETIPLAYER_PROFILE=/output/.get_iplayer PORT=1935 BASEURL=
EXPOSE $PORT
VOLUME "$GETIPLAYER_OUTPUT"

RUN apk --update --no-cache add ffmpeg perl-cgi perl-mojolicious perl-lwp-protocol-https perl-xml-libxml jq logrotate su-exec tini curl

COPY --from=atomicparsleybuild /usr/local/bin/AtomicParsley /usr/local/bin/AtomicParsley

RUN wget -qO - "https://api.github.com/repos/get-iplayer/get_iplayer/releases/latest" > /tmp/latest.json && \
    echo get_iplayer release `jq -r .name /tmp/latest.json` && \
    wget -qO - "`jq -r .tarball_url /tmp/latest.json`" | tar -zxf - && \
    cd get-iplayer* && \
    install -m 755 -t /usr/local/bin ./get_iplayer ./get_iplayer.cgi && \
    cd / && \
    rm -rf get-iplayer* && \
    rm /tmp/latest.json

COPY files/ /

RUN chmod u+s /sbin/su-exec

ENTRYPOINT ["/sbin/tini", "--"]
CMD /start
