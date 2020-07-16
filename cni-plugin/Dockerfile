ARG BUILDPLATFORM=linux/amd64
ARG TARGETPLATFORM=linux/amd64

## compile cni-plugin utility
FROM --platform=$BUILDPLATFORM gcr.io/linkerd-io/go-deps:a525d867 as golang
WORKDIR /linkerd-build
COPY pkg pkg
COPY controller controller
COPY cni-plugin cni-plugin
ARG TARGETARCH
RUN CGO_ENABLED=0 GOOS=linux GOARCH=$TARGETARCH go build -o /go/bin/linkerd-cni -v -mod=readonly ./cni-plugin/

FROM --platform=$TARGETPLATFORM debian:buster-20200514-slim
WORKDIR /linkerd
RUN apt-get update && apt-get install -y jq
COPY --from=golang /go/bin/linkerd-cni /opt/cni/bin/
COPY LICENSE .
COPY cni-plugin/deployment/scripts/install-cni.sh .
COPY cni-plugin/deployment/linkerd-cni.conf.default .
COPY cni-plugin/deployment/scripts/filter.jq .
ENV PATH=/linkerd:/opt/cni/bin:$PATH
CMD ["install-cni.sh"]
