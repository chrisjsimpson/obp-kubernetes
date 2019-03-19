# This creates a jetty jre8 image containing obp-api-1.0.war. 
# It is a multi stage build, meaning a small-ish image is the end result. 

FROM alpine:latest as repo
# Get repo fron github, store as stage 'repo'
RUN apk add --no-cache git
WORKDIR OBP-API
RUN git clone https://github.com/OpenBankProject/OBP-API.git

FROM maven:3-jdk-8 as maven
# Build the source using maven, source is copied from the 'repo' build.
COPY --from=repo /OBP-API /usr/src
RUN cp /usr/src/OBP-API/obp-api/pom.xml /tmp/pom.xml # For Packaging a local repository within the image
WORKDIR /usr/src/OBP-API
RUN cp obp-api/src/main/resources/props/sample.props.template obp-api/src/main/resources/props/default.props
RUN cp obp-api/src/main/resources/props/test.default.props.template obp-api/src/main/resources/props/test.default.props
RUN mvn -B -pl .,obp-commons -s /usr/share/maven/ref/settings-docker.xml dependency:go-offline # This will result in a cached local repository layer
RUN mvn -B -DskipTests -pl obp-api -s /usr/share/maven/ref/settings-docker.xml dependency:go-offline # This will result in a cached local repository layer
#RUN mvn -B -DskipTests -pl obp-api -s /usr/share/maven/ref/settings-docker.xml dependency:resolve # This will result in a cached local repository layer
RUN mvn install --offline -pl .,obp-commons -s /usr/share/maven/ref/settings-docker.xml
RUN mvn install --offline -DskipTests -pl obp-api -s /usr/share/maven/ref/settings-docker.xml


FROM jetty:jre8-alpine
# Copy build artifact (.war file) into jetty from 'maven' stage.
COPY --from=maven /usr/src/OBP-API/obp-api/target/obp-api-1.0.war /var/lib/jetty/webapps/ROOT.war
USER jetty
