# 1. Introduction
Heap dumps package the JVM's heap, stack, and threads into a binary format that can be loaded for analysis later.
Numerous tools can be applied to analyze a heap dump: Memory Analyzer Tool, VisualVM, any my tool [DumpHprofFields](https://github.com/josephmate/DumpHprofFields).

Analyzing the heap dump allows you to determine the root cause of memory leaks.
You can also explore a heap dump to figure out bugs when the JVM cannot be attached by a debugger.
For instance, if the JVM runs at a customer, and they do not permit you to attached a debugger.

This article focuses on how to obtain a heap dump and all the issues you will run into while getting one.

# 2. Vanilla
[jmap](https://docs.oracle.com/javase/7/docs/technotes/tools/share/jmap.html) provides the easiest way to get a heap.

```bash
jmap -dump:live,format=b,file=<pathToSaveFileTo> <pidOfJVM>
Dumping heap to C:\Users\Joseph\Documents\GitHub\JavaMemoryLeakCookbook\01-get-heap-dump\heap.dump.windows.hprof ...
Heap dump file created
```

Try it yourself by checking out the
[JavaMemoryLeakCookbook project](https://github.com/josephmate/JavaMemoryLeakCookbook)
.

# 2. Avoid -F force 
When jmap doesn't work, you might be attempt to use jmap -F flag because that's what jmap suggests when it does not work. However, somtimes tools like VisualVM and MemoryAnalyzer tool will not be able to consume the heap dumped provided with the -F flag.

Unfortunately, I haven't been able to to reproduce this problem a saw a year ago. Next step is to setup a situation where I need to use force. Maybe it was able to attach ignoring -F.

# 3. User
```
# run docker image that has a java process running under notroot
$dockerId = docker run --init -detach --publish 4567:4567 com.josephmate/using.heap.service:1.0-SNAPSHOT
# open a root terminal to the container
docker exec --interactive --tty --user root $dockerId ash
# try jmap to create a heapdump
jmap -dump:live,format=b,file=/tmp/heap.hprof $(pidof java)
6: Unable to open socket file: target process not responding or HotSpot VM not loaded
```
Even though I'm root, I'm unable to attach.
However if I try using the correct user, jmap is able to attach and trigger the heap dump.
```
# open a notroot terminal to the container
docker exec --interactive --tty --user notroot $dockerId ash
jmap -dump:live,format=b,file=/tmp/heap.hprof $(pidof java)
Dumping heap to /tmp/heap.hprof ...
Heap dump file created
```

# 4. Alpine Docker
```
$dockerId = docker run -detach --publish 4567:4567 com.josephmate/using.heap.service:1.0-SNAPSHOT
docker exec --interactive --tty --user notroot $dockerId ash
jmap -dump:live,format=b,file=/tmp/heap.hprof $(pidof java)
1: Unable to get pid of LinuxThreads manager thread
```

According to
[Github issue: Not able to run jmap, jstack, jcmd on alpine](https://github.com/docker-library/openjdk/issues/372)
and
[Github issue: jmap not happy on alpine](https://github.com/docker-library/openjdk/issues/76),
jmap fails to attach to pid 1.

Passing `--init` to `docker run` solves the issue:
```
$dockerId = docker run --init -detach --publish 4567:4567 com.josephmate/using.heap.service:1.0-SNAPSHOT
docker exec --interactive --tty --user notroot $dockerId ash
jmap -dump:live,format=b,file=/tmp/heap.hprof $(pidof java)
```


# 4. SE Linux
# 5. Only JRE
# 6. GC or CPU Overloaded
# 7. How far apart the versions can be
# 8. Core dump
# 9. jmap under the hood

