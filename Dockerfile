FROM docker:18.05.0-ce

RUN apk add --no-cache ca-certificates wget openjdk8-jre git nodejs yarn \
  && wget -q -O swarm-client.jar https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/3.13/swarm-client-3.13.jar

RUN set -ex; \
  apk add --no-cache --virtual .fetch-deps \
    python \
    py-setuptools \
    py-pip \
  ; \
  \
  pip --no-cache-dir install docker-compose; \
  \
  apk del .fetch-deps; \
  \
  chmod +x /usr/bin/docker-compose

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh  \
  && sed -i -e 's/\r$//' /entrypoint.sh

CMD ["/entrypoint.sh"]
