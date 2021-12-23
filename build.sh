#!/bin/bash
set -e

TAG_LATEST=registry.cn-hangzhou.aliyuncs.com/whyun/base:restygate-latest

docker pull registry.cn-hangzhou.aliyuncs.com/whyun/base:supervisor-ubuntu-latest
docker build ./docker -f ./Dockerfile -t ${TAG_LATEST} --progress=plain "$@"
if [ "$NEED_PUSH" = "1" ] ; then
    docker push ${TAG_LATEST}
fi