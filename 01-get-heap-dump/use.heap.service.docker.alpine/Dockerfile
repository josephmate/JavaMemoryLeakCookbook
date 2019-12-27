FROM openjdk:8-jdk-alpine
MAINTAINER Joseph Mate

# Add Maven dependencies (not shaded into the artifact; Docker-cached)
ADD target/lib           /usr/share/service/lib

RUN addgroup -S notroot 
RUN adduser -S -G notroot notroot
RUN chmod -R ugo+rwx  /usr/share/service/lib
USER notroot

ENTRYPOINT ["java", "-cp", "/usr/share/service/lib/*:/usr/share/service/service.jar", "Server"]
