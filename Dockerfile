# Build
FROM golang:1.15-buster AS build
WORKDIR /go/src/github.com/mpolden/echoip
COPY . .

# Must build without cgo because libc is unavailable in runtime image
ENV GO111MODULE=on CGO_ENABLED=0
RUN make

# Run
FROM alpine:latest
EXPOSE 8080

COPY --from=build /go/bin/echoip /opt/echoip/
COPY html /opt/echoip/html
RUN apk --no-cache add curl
RUN curl -L -o /opt/echoip/GeoLite2-ASN.mmdb "https://git.io/GeoLite2-ASN.mmdb"
RUN curl -L -o /opt/echoip/GeoLite2-City.mmdb "https://git.io/GeoLite2-City.mmdb"
RUN curl -L -o /opt/echoip/GeoLite2-Country.mmdb "https://git.io/GeoLite2-Country.mmdb"

WORKDIR /opt/echoip
ENTRYPOINT ["/opt/echoip/echoip"]
CMD ["-H","CF-Connecting-IP","-a","/opt/echoip/GeoLite2-ASN.mmdb","-c","/opt/echoip/GeoLite2-City.mmdb","-f","/opt/echoip/GeoLite2-Country.mmdb","-r"]