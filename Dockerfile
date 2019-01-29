FROM alpine

LABEL maintainer="morningspace@yahoo.com"

RUN apk add --no-cache bash curl jq

WORKDIR /root

RUN mkdir elash

COPY lib README.md LICENSE elash/

RUN ln -s $HOME/elash/main.sh /usr/local/bin/elash
