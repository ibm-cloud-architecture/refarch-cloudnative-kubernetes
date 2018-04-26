FROM openjdk:alpine

ENV KUBE_LATEST_VERSION="v1.10.0"

RUN apk add --update ca-certificates \
 && apk add --update -t deps curl \
 && apk add --update bash \
 && curl -L https://storage.googleapis.com/kubernetes-release/release/${KUBE_LATEST_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl \
 && chmod +x /usr/local/bin/kubectl \
 && apk del --purge deps \
 && rm /var/cache/apk/*

RUN apk add --update openssl && \
     rm -rf /var/cache/apk/*

RUN mkdir /bc_certs

COPY keygen.sh /bc_certs/keygen.sh
