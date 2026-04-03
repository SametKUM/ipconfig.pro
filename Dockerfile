# Build
FROM golang:1.23-bookworm AS build
WORKDIR /go/src/github.com/mpolden/echoip
COPY . .
ENV GO111MODULE=on CGO_ENABLED=0
RUN make

# GeoIP databases
FROM alpine:3.20 AS geoip
RUN apk --no-cache add curl && \
    mkdir -p /geoip && \
    curl -L -o /geoip/GeoLite2-ASN.mmdb "https://git.io/GeoLite2-ASN.mmdb" && \
    curl -L -o /geoip/GeoLite2-City.mmdb "https://git.io/GeoLite2-City.mmdb" && \
    curl -L -o /geoip/GeoLite2-Country.mmdb "https://git.io/GeoLite2-Country.mmdb"

# Run
FROM alpine:3.20
EXPOSE 8080
RUN adduser -D -h /opt/echoip echoip
WORKDIR /opt/echoip

COPY --from=build /go/bin/echoip .
COPY --from=geoip /geoip/*.mmdb ./
COPY html html

USER echoip
ENTRYPOINT ["/opt/echoip/echoip"]
CMD ["-H","CF-Connecting-IP","-a","GeoLite2-ASN.mmdb","-c","GeoLite2-City.mmdb","-f","GeoLite2-Country.mmdb","-r"]
