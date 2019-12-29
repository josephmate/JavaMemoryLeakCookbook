FROM centos:centos7
MAINTAINER Joseph Mate

RUN yum install -y \
       java-1.8.0-openjdk \
       java-1.8.0-openjdk-devel

# Add Maven dependencies (not shaded into the artifact; Docker-cached)
ADD target/lib           /usr/share/service/lib

RUN useradd -ms /bin/bash notroot
RUN chmod -R ugo+rwx  /usr/share/service/lib
USER notroot

ENTRYPOINT ["java", "-cp", "/usr/share/service/lib/*:/usr/share/service/service.jar", "Server"]
