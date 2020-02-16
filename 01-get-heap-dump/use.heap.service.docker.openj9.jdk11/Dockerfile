FROM adoptopenjdk/openjdk11-openj9
MAINTAINER Joseph Mate

# Add Maven dependencies (not shaded into the artifact; Docker-cached)
ADD target/lib           /usr/share/service/lib

RUN useradd -ms /bin/bash notroot 
RUN chmod -R ugo+rwx  /usr/share/service/lib
USER notroot

ENTRYPOINT ["java", "-cp", "/usr/share/service/lib/*:/usr/share/service/service.jar", "Server"]
