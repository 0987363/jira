#FROM ubuntu:jammy as base
FROM alpine/curl as base

LABEL maintainer="haxqer <haxqer666@gmail.com>" version="9.6.0"

ARG JIRA_VERSION=9.6.0
# Production: jira-software jira-core
ARG JIRA_PRODUCT=jira-software
ARG AGENT_VERSION=1.3.3
ARG MYSQL_DRIVER_VERSION=8.0.22

ENV JIRA_USER=jira \
    JIRA_GROUP=jira \
    JIRA_HOME=/var/jira \
    JIRA_INSTALL=/opt/jira \
    AGENT_PATH=/var/agent \
    AGENT_FILENAME=atlassian-agent.jar 

RUN mkdir -p ${JIRA_INSTALL} ${JIRA_HOME} ${AGENT_PATH}
COPY atlassian-jira-software-9.6.0-standalone $JIRA_INSTALL
COPY jira.xx.delu1.com-server.xml $JIRA_INSTALL/atlassian-jira-software-9.6.0-standalone/conf/server.xml
COPY atlassian-agent-v1.3.3.jar ${AGENT_PATH}/${AGENT_FILENAME}
COPY mysql-connector-java-8.0.22.jar ${JIRA_INSTALL}/lib/mysql-connector-java-8.0.22.jar


#RUN curl -o ${AGENT_PATH}/${AGENT_FILENAME}  https://github.com/haxqer/jira/releases/download/v${AGENT_VERSION}/atlassian-agent.jar -L \
#RUN curl -o ${JIRA_INSTALL}/lib/mysql-connector-java-${MYSQL_DRIVER_VERSION}.jar https://repo1.maven.org/maven2/mysql/mysql-connector-java/${MYSQL_DRIVER_VERSION}/mysql-connector-java-${MYSQL_DRIVER_VERSION}.jar -L \
RUN echo "jira.home = ${JIRA_HOME}" > ${JIRA_INSTALL}/atlassian-jira/WEB-INF/classes/jira-application.properties


FROM eclipse-temurin:8u362-b09-jre-focal

ENV JIRA_USER=jira \
    JIRA_GROUP=jira \
    JIRA_HOME=/var/jira \
    JIRA_INSTALL=/opt/jira \
    JVM_MINIMUM_MEMORY=2g \
    JVM_MAXIMUM_MEMORY=20g \
    JVM_CODE_CACHE_ARGS='-XX:InitialCodeCacheSize=1g -XX:ReservedCodeCacheSize=2g' \
    AGENT_PATH=/var/agent \
    AGENT_FILENAME=atlassian-agent.jar \
    ENABLE_CJK_FONT=true


ENV JAVA_OPTS="-javaagent:${AGENT_PATH}/${AGENT_FILENAME} ${JAVA_OPTS}"

COPY --from=base $JIRA_HOME $JIRA_HOME
COPY --from=base $JIRA_INSTALL $JIRA_INSTALL
COPY --from=base $AGENT_PATH $AGENT_PATH

#RUN mkdir /usr/share/fonts/opentype
#COPY SourceHanSansSC-Normal.otf /usr/share/fonts/opentype

RUN apt update \
&& apt install -y fonts-droid-fallback fonts-wqy-zenhei fonts-wqy-microhei fonts-arphic-ukai fonts-arphic-uming \
&& rm -rf /var/lib/{apt,dpkg,cache,log}/ 
#&& mkfontscale \
#&& mkfontdir \
#&& fc-cache -fv


RUN export CONTAINER_USER=$JIRA_USER \
&& export CONTAINER_GROUP=$JIRA_GROUP \
&& groupadd -r $JIRA_GROUP && useradd -r -g $JIRA_GROUP $JIRA_USER \
&& chown -R $JIRA_USER:$JIRA_GROUP ${JIRA_INSTALL} ${JIRA_HOME} ${AGENT_PATH} 

VOLUME $JIRA_HOME
USER $JIRA_USER
WORKDIR $JIRA_INSTALL
EXPOSE 8080

ENTRYPOINT ["/opt/jira/bin/start-jira.sh", "-fg"]

