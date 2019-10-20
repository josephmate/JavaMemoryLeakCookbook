mvn clean install
docker run -d -p 4567:4567 com.josephmate/using.heap.service:1.0-SNAPSHOT


# wait 10 seconds for the memory to load
# TODO use localhost:4567/health to figure out when the service is ready
Start-Sleep -s 10


