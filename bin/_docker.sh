#!/usr/bin/env bash

set -eu

bindir=$( cd "${BASH_SOURCE[0]%/*}" && pwd )

# shellcheck source=_log.sh
. "$bindir"/_log.sh

# TODO this should be set to the canonical public docker registry; we can override this
# docker registry in, for instance, CI.
export DOCKER_REGISTRY=${DOCKER_REGISTRY:-gcr.io/linkerd-io}

# When set, causes docker's build output to be emitted to stderr.
export DOCKER_TRACE=${DOCKER_TRACE:-}

# When set, it will build multi architectures docker images.
export DOCKER_BUILDX=${DOCKER_BUILDX:-}

# When set together with DOCKER_BUILDX, it will push the multi architecture images to the registry.
export DOCKER_PUSH_MULTIARCH=${DOCKER_PUSH_MULTIARCH:-false}

# Default supported docker image architectures
export SUPPORTED_ARCHS=linux/amd64,linux/arm64,linux/arm/v7

docker_repo() {
    repo=$1

    name=$repo
    if [ -n "${DOCKER_REGISTRY:-}" ]; then
        name="$DOCKER_REGISTRY/$name"
    fi

    echo "$name"
}

docker_build() {
    repo=$(docker_repo "$1")
    shift

    tag=$1
    shift

    file=$1
    shift

    output=/dev/null
    if [ -n "$DOCKER_TRACE" ]; then
        output=/dev/stderr
    fi

    rootdir=$( cd "$bindir"/.. && pwd )

    if [ -n "$DOCKER_BUILDX" ]; then
        log_debug "  :; docker buildx build $rootdir --platform $SUPPORTED_ARCHS --output type=image,push=$DOCKER_PUSH_MULTIARCH -t $repo:$tag -t $repo:main -f $file $*"
        docker buildx build "$rootdir" \
            --platform "$SUPPORTED_ARCHS" \
            --output "type=image,push=$DOCKER_PUSH_MULTIARCH" \
            -t "$repo:$tag" \
            -t "$repo:main" \
            -f "$file" \
            "$@" \
            > "$output"
    else
        log_debug "  :; docker build $rootdir -t $repo:$tag -f $file $*"
        docker build "$rootdir" \
            -t "$repo:$tag" \
            -f "$file" \
            "$@" \
            > "$output"
    fi

    echo "$repo:$tag"
}

docker_pull() {
    repo=$(docker_repo "$1")
    tag=$2
    log_debug "  :; docker pull $repo:$tag"
    docker pull "$repo:$tag"
}

docker_push() {
    repo=$(docker_repo "$1")
    tag=$2
    log_debug "  :; docker push $repo:$tag"
    docker push "$repo:$tag"
}

docker_retag() {
    repo=$(docker_repo "$1")
    from=$2
    to=$3
    log_debug "  :; docker tag $repo:$from $repo:$to"
    docker tag "$repo:$from" "$repo:$to"
    echo "$repo:$to"
}
