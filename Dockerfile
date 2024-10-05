FROM alpine:3.20.3

# Install dependencies
RUN set -ex; \
    apk add --no-cache \
        bash \
        curl \
        openssl \
    ;

# Set variables
# Note the 'v' in default GETSSL_VERSION. If set to 'latest', it will
# fetch the very last commit on the upstream repository
ARG GETSSL_VERSION=v2.49
ENV GETSSL_BIN=/usr/bin/getssl \
    SOURCE_URL="https://raw.githubusercontent.com/srvrco/getssl"

# Install getssl
RUN set -eux; \
    curl "${SOURCE_URL}/${GETSSL_VERSION}/getssl" > "${GETSSL_BIN}"; \
    chmod 755 "${GETSSL_BIN}"

# Install default cron job
COPY crontab /var/spool/cron/crontabs/root

CMD ["crond", "-f", "-l", "2"]
