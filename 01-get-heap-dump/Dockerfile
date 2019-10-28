FROM openjdk:8-jdk-alpine
MAINTAINER Joseph Mate <mate.joseph@gmail.com>

# Add Maven dependencies (not shaded into the artifact; Docker-cached)
ADD target/lib           /usr/share/service/lib
# Add the service itself
ARG JAR_FILE
ADD target/${JAR_FILE} /usr/share/service/service.jar

RUN addgroup -S notroot 
RUN adduser -S -G notroot notroot
RUN chmod -R ugo+rwx  /usr/share/service/lib
RUN chmod -R ugo+rwx  /usr/share/service/service.jar
USER notroot

ENTRYPOINT ["java", "-cp", "/usr/share/service/lib/*:/usr/share/service/service.jar", "Server"]
