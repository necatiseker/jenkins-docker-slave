FROM docker:18.05.0-ce

ENV GLIBC 2.27-r0
ENV COMPOSE_VERSION 1.21.2

RUN apk update && apk add --no-cache openssl ca-certificates curl libgcc && \
  curl -fsSL -o /etc/apk/keys/sgerrand.rsa.pub https://raw.githubusercontent.com/sgerrand/alpine-pkg-glibc/master/sgerrand.rsa.pub && \
  curl -fsSL -o glibc-$GLIBC.apk https://github.com/sgerrand/alpine-pkg-glibc/releases/download/$GLIBC/glibc-$GLIBC.apk && \
  apk add --no-cache glibc-$GLIBC.apk && \
  ln -s /lib/libz.so.1 /usr/glibc-compat/lib/ && \
  ln -s /lib/libc.musl-x86_64.so.1 /usr/glibc-compat/lib && \
  ln -s /usr/lib/libgcc_s.so.1 /usr/glibc-compat/lib && \
  curl -L https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose && \
  chmod +x /usr/local/bin/docker-compose && \
  rm /etc/apk/keys/sgerrand.rsa.pub glibc-$GLIBC.apk && \
  apk del curl

ENV VERSION=v8.11.3 NPM_VERSION=5 YARN_VERSION=latest

RUN apk add --no-cache curl make gcc g++ python linux-headers binutils-gold gnupg libstdc++ && \
  for server in ipv4.pool.sks-keyservers.net keyserver.pgp.com ha.pool.sks-keyservers.net; do \
    gpg --keyserver $server --recv-keys \
      94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
      FD3A5288F042B6850C66B31F09FE44734EB7990E \
      71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
      DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
      C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
      B9AE9905FFD7803F25714661B63B535A4C206CA9 \
      56730D5401028683275BD23C23EFEFE93C4CFFFE \
      77984A986EBC2AA786BC0F66B01FBB92821C587A && break; \
  done && \
  curl -sfSLO https://nodejs.org/dist/${VERSION}/node-${VERSION}.tar.xz && \
  curl -sfSL https://nodejs.org/dist/${VERSION}/SHASUMS256.txt.asc | gpg --batch --decrypt | \
    grep " node-${VERSION}.tar.xz\$" | sha256sum -c | grep ': OK$' && \
  tar -xf node-${VERSION}.tar.xz && \
  cd node-${VERSION} && \
  ./configure --prefix=/usr ${CONFIG_FLAGS} && \
  make -j$(getconf _NPROCESSORS_ONLN) && \
  make install && \
  cd / && \
  if [ -z "$CONFIG_FLAGS" ]; then \
    if [ -n "$NPM_VERSION" ]; then \
      npm install -g npm@${NPM_VERSION}; \
    fi; \
    find /usr/lib/node_modules/npm -name test -o -name .bin -type d | xargs rm -rf; \
    if [ -n "$YARN_VERSION" ]; then \
      for server in ipv4.pool.sks-keyservers.net keyserver.pgp.com ha.pool.sks-keyservers.net; do \
        gpg --keyserver $server --recv-keys \
          6A010C5166006599AA17F08146C2130DFD2497F5 && break; \
      done && \
      curl -sfSL -O https://yarnpkg.com/${YARN_VERSION}.tar.gz -O https://yarnpkg.com/${YARN_VERSION}.tar.gz.asc && \
      gpg --batch --verify ${YARN_VERSION}.tar.gz.asc ${YARN_VERSION}.tar.gz && \
      mkdir /usr/local/share/yarn && \
      tar -xf ${YARN_VERSION}.tar.gz -C /usr/local/share/yarn --strip 1 && \
      ln -s /usr/local/share/yarn/bin/yarn /usr/local/bin/ && \
      ln -s /usr/local/share/yarn/bin/yarnpkg /usr/local/bin/ && \
      rm ${YARN_VERSION}.tar.gz*; \
    fi; \
  fi && \
  apk del curl make gcc g++ python linux-headers binutils-gold gnupg ${DEL_PKGS} && \
  rm -rf ${RM_DIRS} /node-${VERSION}* /usr/share/man /tmp/* /var/cache/apk/* \
    /root/.npm /root/.node-gyp /root/.gnupg /usr/lib/node_modules/npm/man \
    /usr/lib/node_modules/npm/doc /usr/lib/node_modules/npm/html /usr/lib/node_modules/npm/scripts
  
ENV JENKINS_HOME /home/jenkins
ENV SLAVE_VERSION 3.13

RUN apk add --no-cache curl git openjdk8-jre sudo && \
  adduser -D -h $JENKINS_HOME -s /bin/sh jenkins jenkins && \
  chmod a+rwx $JENKINS_HOME && \
  echo "jenkins ALL=(ALL) NOPASSWD: /usr/local/bin/docker" > /etc/sudoers.d/00jenkins && \
  chmod 440 /etc/sudoers.d/00jenkins && \
  curl --create-dirs -sSLo /usr/share/jenkins/slave.jar https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/$SLAVE_VERSION/swarm-client-$SLAVE_VERSION.jar && \
  chmod 755 /usr/share/jenkins && \
  chmod 644 /usr/share/jenkins/slave.jar && \
  apk del curl

COPY entrypoint.sh /

VOLUME $JENKINS_HOME
WORKDIR $JENKINS_HOME

USER jenkins

RUN chmod +x /entrypoint.sh \
    && sed -i -e 's/\r$//' /entrypoint.sh

CMD ["/entrypoint.sh"]
