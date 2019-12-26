# run docker image that has a java process running under notroot
$dockerId = docker run --init -detach --publish 4567:4567 com.josephmate/using.heap.service:1.0-SNAPSHOT
# open a root terminal to the container
docker exec --interactive --tty --user root $dockerId ash
# try jmap to create a heapdump
jmap -dump:live,format=b,file=/tmp/heap.hprof $(pidof java)
# open a notroot terminal to the container
docker exec -i -t --user notroot $dockerId ash
# try jmap to create a heapdump with the matching user
jmap -dump:live,format=b,file=/tmp/heap.hprof $(pidof java)
