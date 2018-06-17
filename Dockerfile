FROM docker:18.05.0-ce

RUN apk --update add ca-certificates wget openjdk8-jre git \
  && update-ca-certificates \
  && wget -O swarm-client.jar https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/3.13/swarm-client-3.13.jar

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh  \
  && sed -i -e 's/\r$//' /entrypoint.sh

CMD ["/entrypoint.sh"]