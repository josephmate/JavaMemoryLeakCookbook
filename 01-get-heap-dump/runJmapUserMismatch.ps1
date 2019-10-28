docker run -d -p 4567:4567 com.josephmate/using.heap.service:1.0-SNAPSHOT

docker exec -i -t --user root bbebacf1d6dec53d45502310964a08290751c0c586b9753f3e17fbc2c4f3bfc9 ash


jmap -dump:live,format=b,file=/tmp/heap.hprof $(pidof java)

jmap -F -dump:live,format=b,file=/tmp/heap.hprof $(pidof java)
