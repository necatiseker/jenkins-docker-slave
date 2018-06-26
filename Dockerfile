FROM docker:18.05.0-ce

ENV JENKINS_HOME /home/jenkins
ENV SWARM_CLIENT_VERSION 3.13

RUN apk add --no-cache ca-certificates curl git \
   openjdk8-jre \
   nodejs yarn \
   python py-setuptools py-pip \
   sudo

RUN pip --no-cache-dir install --target=/usr/local/bin docker-compose 

RUN adduser -D -h $JENKINS_HOME -s /bin/sh jenkins jenkins \
    && chmod a+rwx $JENKINS_HOME

RUN echo "jenkins ALL=(ALL) NOPASSWD: /usr/local/bin/docker" > /etc/sudoers.d/00jenkins \
    && chmod 440 /etc/sudoers.d/00jenkins
  
RUN curl --create-dirs -sSLo /usr/local/jenkins/slave.jar https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/${SWARM_CLIENT_VERSION}/swarm-client-${SWARM_CLIENT_VERSION}.jar \
   && chmod 755 /usr/local/jenkins \
   && chmod 644 /usr/local/jenkins/slave.jar

COPY entrypoint.sh /usr/local/jenkins/entrypoint.sh

RUN chmod +x /usr/local/jenkins/entrypoint.sh \
   && sed -i -e 's/\r$//' /usr/local/jenkins/entrypoint.sh

CMD ["/usr/local/jenkins/entrypoint.sh"]  

# RUN set -ex; \
# apk add --no-cache --virtual .fetch-deps \
#    python \
#    python \
#    py-pip \
#  ; \
#  \
#  pip --no-cache-dir install docker-compose; \
#  \
#  apk del .fetch-deps; \
#  \
#  chmod +x /usr/bin/docker-compose 

# COPY entrypoint.sh /
# RUN chmod +x /entrypoint.sh  \
#  && sed -i -e 's/\r$//' /entrypoint.sh

# CMD ["/entrypoint.sh"]
