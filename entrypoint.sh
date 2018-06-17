#!/bin/sh
set -e

LABELS="${LABELS:-docker}"
EXECUTORS="${EXECUTORS:-3}"
FSROOT="${FSROOT:-/tmp/jenkins}"

mkdir -p $FSROOT
java -jar swarm-client.jar -labels=$LABELS -executors=$EXECUTORS -fsroot=$FSROOT \
  -name=docker-$(hostname) -master=$JENKINS_ADDR -username=$JENKINS_USER -password=$JENKINS_PASS
