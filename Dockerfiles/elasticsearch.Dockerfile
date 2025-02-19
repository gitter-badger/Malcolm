FROM amazon/opendistro-for-elasticsearch:1.13.2

# Copyright (c) 2021 Battelle Energy Alliance, LLC.  All rights reserved.
LABEL maintainer="malcolm.netsec@gmail.com"
LABEL org.opencontainers.image.authors='malcolm.netsec@gmail.com'
LABEL org.opencontainers.image.url='https://github.com/idaholab/Malcolm'
LABEL org.opencontainers.image.documentation='https://github.com/idaholab/Malcolm/blob/master/README.md'
LABEL org.opencontainers.image.source='https://github.com/idaholab/Malcolm'
LABEL org.opencontainers.image.vendor='Idaho National Laboratory'
LABEL org.opencontainers.image.title='malcolmnetsec/elasticsearch-od'
LABEL org.opencontainers.image.description='Malcolm container providing Elasticsearch (the Apache-licensed Open Distro variant)'

ARG DEFAULT_UID=1000
ARG DEFAULT_GID=1000
ENV DEFAULT_UID $DEFAULT_UID
ENV DEFAULT_GID $DEFAULT_GID
ENV PUID $DEFAULT_UID
ENV PUSER "elasticsearch"
ENV PGROUP "elasticsearch"
ENV PUSER_PRIV_DROP true

ENV TERM xterm

ARG GITHUB_OAUTH_TOKEN=""
ARG DISABLE_INSTALL_DEMO_CONFIG=true
ENV DISABLE_INSTALL_DEMO_CONFIG $DISABLE_INSTALL_DEMO_CONFIG
ENV JAVA_HOME=/usr/share/elasticsearch/jdk

# Malcolm manages authentication and encryption via NGINX reverse proxy
# https://opendistro.github.io/for-elasticsearch-docs/docs/security/configuration/disable/
# https://opendistro.github.io/for-elasticsearch-docs/docs/install/docker/#customize-the-docker-image
# https://github.com/opendistro-for-elasticsearch/opendistro-build/issues/613
RUN yum install -y openssl && \
  /usr/share/elasticsearch/bin/elasticsearch-plugin remove opendistro_security && \
  echo -e 'cluster.name: "docker-cluster"\nnetwork.host: 0.0.0.0' > /usr/share/elasticsearch/config/elasticsearch.yml && \
  chown -R $PUSER:$PGROUP /usr/share/elasticsearch/config/elasticsearch.yml && \
  sed -i "s/user=1000\b/user=%(ENV_PUID)s/g" /usr/share/elasticsearch/plugins/opendistro-performance-analyzer/pa_config/supervisord.conf && \
  sed -i "s/user=1000\b/user=%(ENV_PUID)s/g" /usr/share/elasticsearch/performance-analyzer-rca/pa_config/supervisord.conf && \
  sed -i '/[^#].*\/usr\/share\/elasticsearch\/bin\/elasticsearch.*/i /usr/local/bin/jdk-cacerts-auto-import.sh || true' /usr/local/bin/docker-entrypoint.sh
# just used for initial keystore creation
ADD shared/bin/docker-uid-gid-setup.sh /usr/local/bin/
ADD shared/bin/jdk-cacerts-auto-import.sh /usr/local/bin/

USER root

ENTRYPOINT ["/usr/local/bin/docker-uid-gid-setup.sh"]

CMD ["/usr/local/bin/docker-entrypoint.sh"]

# to be populated at build-time:
ARG BUILD_DATE
ARG MALCOLM_VERSION
ARG VCS_REVISION

LABEL org.opencontainers.image.created=$BUILD_DATE
LABEL org.opencontainers.image.version=$MALCOLM_VERSION
LABEL org.opencontainers.image.revision=$VCS_REVISION
