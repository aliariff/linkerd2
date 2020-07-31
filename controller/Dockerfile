ARG BUILDPLATFORM=linux/amd64

# Precompile key slow-to-build dependencies
FROM --platform=$BUILDPLATFORM golang:1.14.2-alpine as go-deps
ONBUILD WORKDIR /linkerd-build
ONBUILD COPY go.mod go.sum ./
ONBUILD COPY bin/install-deps bin/
ONBUILD RUN go mod download
ONBUILD ARG TARGETARCH
ONBUILD RUN ./bin/install-deps $TARGETARCH

## compile controller service
FROM go-deps as golang
COPY controller/gen controller/gen
COPY pkg pkg
COPY controller controller
COPY charts/patch charts/patch
COPY charts/partials charts/partials

# Generate static templates
# TODO: `go generate` does not honor -mod=readonly
RUN go generate -mod=readonly ./pkg/charts/static
RUN CGO_ENABLED=0 GOOS=linux GOARCH=$TARGETARCH go build -o /out/controller -tags prod -mod=readonly -ldflags "-s -w" ./controller/cmd

## package runtime
FROM scratch
ENV PATH=$PATH:/go/bin
COPY LICENSE /linkerd/LICENSE
COPY --from=golang /out/controller /go/bin/controller
# for heartbeat (https://versioncheck.linkerd.io/version.json)
COPY --from=golang /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

ARG LINKERD_VERSION
ENV LINKERD_CONTAINER_VERSION_OVERRIDE=${LINKERD_VERSION}

ENTRYPOINT ["/go/bin/controller"]
