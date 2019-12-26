$dockerId = docker run --init -d -p 4567:4567 com.josephmate/using.heap.service:1.0-SNAPSHOT

docker exec -i -t --user root $dockerId ash


jmap -dump:live,format=b,file=/tmp/heap.hprof $(pidof java)

jmap -F -dump:live,format=b,file=/tmp/heap.hprof $(pidof java)

docker exec -i -t --user notroot $dockerId ash
