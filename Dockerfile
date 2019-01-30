FROM alpine

LABEL maintainer="morningspace@yahoo.com"

RUN apk add --no-cache bash curl jq dialog

WORKDIR /root

RUN mkdir elash

COPY lib README.md LICENSE elash/
COPY etc /etc/

RUN ln -s $HOME/elash/main.sh /usr/local/bin/elash && \
  echo "source elash/bin/common/completion.sh" >> ~/.bashrc