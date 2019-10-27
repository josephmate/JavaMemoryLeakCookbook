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
# 4. SE Linux
# 5. Only JRE
# 6. GC or CPU Overloaded
# 7. How far apart the versions can be
# 8. Core dump
# 9. jmap under the hood

