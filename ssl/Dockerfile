FROM alpine:latest

LABEL maintainer=az@zok.xyz \
      version="1.0"

RUN mkdir -p /kopano/easypki /kopano/ssl /kopano/ssl/clients
WORKDIR /kopano/easypki

ENV PKI_ROOT /kopano/easypki
ENV PKI_ORGANIZATION Internal Kopano System
ENV PKI_COUNTRY DE

RUN apk add --update \
    easypki \
    openssl \
    && rm -rf /var/cache/apk/*

COPY start.sh /start.sh
COPY gencerts.sh /gencerts.sh

RUN chmod a+x /start.sh /gencerts.sh

CMD ["/start.sh"]