FROM openjdk:8-jdk-alpine
MAINTAINER Joseph Mate <mate.joseph@gmail.com>

# Add Maven dependencies (not shaded into the artifact; Docker-cached)
ADD target/lib           /usr/share/myservice/lib
# Add the service itself
ARG JAR_FILE
ADD target/${JAR_FILE} /usr/share/myservice/myservice.jar

ENTRYPOINT ["java", "-cp", "/usr/share/myservice/lib/*:/usr/share/myservice/myservice.jar", "Server"]
