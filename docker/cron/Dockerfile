FROM alpine:3.10

RUN apk update && apk --no-cache add curl ca-certificates

# copy crontabs for root user
COPY civicron /etc/crontabs/root

# start crond with log level 8 in foreground, output to stderr
#CMD ["crond", "-f", "-d", "8", "-S"]
CMD ["crond", "-f"]
