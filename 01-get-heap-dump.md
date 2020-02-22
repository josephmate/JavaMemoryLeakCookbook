# 1. Introduction
Heap dumps package the JVM's heap, stack, and threads into a binary format that can be loaded for analysis later.
Numerous tools can be applied to analyze a heap dump: Memory Analyzer Tool, VisualVM, and my tool, [DumpHprofFields](https://github.com/josephmate/DumpHprofFields), for dumping an hprof as a csv.

Analyzing the heap dump allows you to determine the root cause of memory leaks.
You can also explore a heap dump to figure out bugs when the JVM cannot be attached by a debugger.
For instance, if the JVM runs at a customer, and they do not permit you to attached a debugger.

This article focuses on all the nitty gritty details of how to obtain a heap dump and all the issues you will run into on various environments.

In the experiments demonstrating the issues you will run into, I will be using docker where I can so you can easily setup same experiments and try for yourself. If I'm not able to use docker, then I mention what I did.

The maven project to build the code and the docker images are available [here](https://github.com/josephmate/JavaMemoryLeakCookbook/tree/master/01-get-heap-dump). As long as you have docker,java and maven installed, you can build everything using `mvn clean install`.

# 2. No Issues
[jmap](https://docs.oracle.com/javase/7/docs/technotes/tools/share/jmap.html) provides the easiest way to get a heap.

```bash
jmap -dump:live,format=b,file=<pathToSaveFileTo> <pidOfJVM>
Dumping heap to <pathToSaveFileTo> ...
Heap dump file created
```

Try it yourself by checking out the
[JavaMemoryLeakCookbook project](https://github.com/josephmate/JavaMemoryLeakCookbook)
.


# 2. Cannot Run jmap as Different User
```powershell
# run docker image that has a java process running under notroot
$dockerId = docker run --init -detach --publish 4567:4567 com.josephmate/use.heap.service.alpine:1.0-SNAPSHOT
# open a root terminal to the container
docker exec --interactive --tty --user root $dockerId ash
# try jmap to create a heapdump
jmap -dump:live,format=b,file=/tmp/heap.hprof $(pidof java)
6: Unable to open socket file: target process not responding or HotSpot VM not loaded
```
Even though I'm root, I'm unable to attach.
However if I try using the correct user, jmap is able to attach and trigger the heap dump.
```powershell
# open a notroot terminal to the container
docker exec --interactive --tty --user notroot $dockerId ash
jmap -dump:live,format=b,file=/tmp/heap.hprof $(pidof java)
Dumping heap to /tmp/heap.hprof ...
Heap dump file created
```

# 3. Difference user, jmap -F doesn't work at all on docker
When jmap doesn't work, you might be attempt to use jmap -F flag because that's what jmap suggests when it does not work. However, sometimes tools like VisualVM and MemoryAnalyzer tool will not be able to consume the heap dumped provided with the -F flag.

<details>
<summary>Alpine doesn't have -F flag: click to expand and see the details of the docker experiment</summary>

```powershell
$dockerId = docker run --init -detach --publish 4567:4567 com.josephmate/use.heap.service.alpine:1.0-SNAPSHOT
docker exec --interactive --tty --user root $dockerId ash
jmap -F -dump:live,format=b,file=/tmp/heap.hprof $(pidof java)
6: Unable to open socket file: target process not responding or HotSpot VM not loaded

jmap -F -dump:live,format=b,file=/tmp/heap.hprof $(pidof java)
Usage:
    jmap -histo <pid>
      (to connect to running process and print histogram of java object heap
    jmap -dump:<dump-options> <pid>
      (to connect to running process and dump java heap)

    dump-options:
      format=b     binary default
      file=<file>  dump heap to <file>

    Example:       jmap -dump:format=b,file=heap.bin <pid>
```
</details>


<details>
<summary>Centos7 fails with DebuggerException: cannot open binary file. Expand see to see details</summary>

```powershell
$dockerId = docker run --init -detach --publish 4567:4567 com.josephmate/use.heap.service.centos:1.0-SNAPSHOT
docker exec --interactive --tty --user root $dockerId bash
PIDOF_JAVA=$(ps aux | grep [j]ava | grep -v docker | awk '{print $2}')
jmap -F -dump:live,format=b,file=/tmp/heap.hprof $PIDOF_JAVA
6: Unable to open socket file: target process not responding or HotSpot VM not loaded
The -F option can be used when the target process is not responding
jmap -F -dump:live,format=b,file=/tmp/heap.hprof $PIDOF_JAVA
Attaching to process ID 6, please wait...
Error attaching to process: sun.jvm.hotspot.debugger.DebuggerException: cannot open binary file
sun.jvm.hotspot.debugger.DebuggerException: sun.jvm.hotspot.debugger.DebuggerException: cannot open binary file
        at sun.jvm.hotspot.debugger.linux.LinuxDebuggerLocal$LinuxDebuggerLocalWorkerThread.execute(LinuxDebuggerLocal.java:163)
        at sun.jvm.hotspot.debugger.linux.LinuxDebuggerLocal.attach(LinuxDebuggerLocal.java:278)
        at sun.jvm.hotspot.HotSpotAgent.attachDebugger(HotSpotAgent.java:671)
        at sun.jvm.hotspot.HotSpotAgent.setupDebuggerLinux(HotSpotAgent.java:611)
        at sun.jvm.hotspot.HotSpotAgent.setupDebugger(HotSpotAgent.java:337)
        at sun.jvm.hotspot.HotSpotAgent.go(HotSpotAgent.java:304)
        at sun.jvm.hotspot.HotSpotAgent.attach(HotSpotAgent.java:140)
        at sun.jvm.hotspot.tools.Tool.start(Tool.java:185)
        at sun.jvm.hotspot.tools.Tool.execute(Tool.java:118)
        at sun.jvm.hotspot.tools.HeapDumper.main(HeapDumper.java:83)
        at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
        at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
        at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
        at java.lang.reflect.Method.invoke(Method.java:498)
        at sun.tools.jmap.JMap.runTool(JMap.java:201)
        at sun.tools.jmap.JMap.main(JMap.java:130)
Caused by: sun.jvm.hotspot.debugger.DebuggerException: cannot open binary file
        at sun.jvm.hotspot.debugger.linux.LinuxDebuggerLocal.attach0(Native Method)
        at sun.jvm.hotspot.debugger.linux.LinuxDebuggerLocal.access$100(LinuxDebuggerLocal.java:62)
        at sun.jvm.hotspot.debugger.linux.LinuxDebuggerLocal$1AttachTask.doit(LinuxDebuggerLocal.java:269)
        at sun.jvm.hotspot.debugger.linux.LinuxDebuggerLocal$LinuxDebuggerLocalWorkerThread.run(LinuxDebuggerLocal.java:138)
```
</details>

<details>
<summary>Centos6 has the same DebuggerException. Expand see to see details</summary>

```powershell
$dockerId = docker run --init -detach --publish 4567:4567 com.josephmate/use.heap.service.centos6:1.0-SNAPSHOT
docker exec --interactive --tty --user root $dockerId bash
PIDOF_JAVA=$(ps aux | grep [j]ava | grep -v docker | awk '{print $2}')
jmap -dump:live,format=b,file=/tmp/heap.hprof $PIDOF_JAVA
6: Unable to open socket file: target process not responding or HotSpot VM not loaded
The -F option can be used when the target process is not responding
Attaching to process ID 6, please wait...
Error attaching to process: sun.jvm.hotspot.debugger.DebuggerException: cannot open binary file
sun.jvm.hotspot.debugger.DebuggerException: sun.jvm.hotspot.debugger.DebuggerException: cannot open binary file
        at sun.jvm.hotspot.debugger.linux.LinuxDebuggerLocal$LinuxDebuggerLocalWorkerThread.execute(LinuxDebuggerLocal.java:163)
        at sun.jvm.hotspot.debugger.linux.LinuxDebuggerLocal.attach(LinuxDebuggerLocal.java:278)
        at sun.jvm.hotspot.HotSpotAgent.attachDebugger(HotSpotAgent.java:671)
        at sun.jvm.hotspot.HotSpotAgent.setupDebuggerLinux(HotSpotAgent.java:611)
        at sun.jvm.hotspot.HotSpotAgent.setupDebugger(HotSpotAgent.java:337)
        at sun.jvm.hotspot.HotSpotAgent.go(HotSpotAgent.java:304)
        at sun.jvm.hotspot.HotSpotAgent.attach(HotSpotAgent.java:140)
        at sun.jvm.hotspot.tools.Tool.start(Tool.java:185)
        at sun.jvm.hotspot.tools.Tool.execute(Tool.java:118)
        at sun.jvm.hotspot.tools.HeapDumper.main(HeapDumper.java:83)
        at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
        at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
        at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
        at java.lang.reflect.Method.invoke(Method.java:498)
        at sun.tools.jmap.JMap.runTool(JMap.java:201)
        at sun.tools.jmap.JMap.main(JMap.java:130)
Caused by: sun.jvm.hotspot.debugger.DebuggerException: cannot open binary file
        at sun.jvm.hotspot.debugger.linux.LinuxDebuggerLocal.attach0(Native Method)
        at sun.jvm.hotspot.debugger.linux.LinuxDebuggerLocal.access$100(LinuxDebuggerLocal.java:62)
        at sun.jvm.hotspot.debugger.linux.LinuxDebuggerLocal$1AttachTask.doit(LinuxDebuggerLocal.java:269)
        at sun.jvm.hotspot.debugger.linux.LinuxDebuggerLocal$LinuxDebuggerLocalWorkerThread.run(LinuxDebuggerLocal.java:138)
```
</details>

After deep diving into the openJDK source, it looks like jmap was trying to open /proc/6/exe [1][2] but was unable. 


[1] [LinuxDebuggerLocal.c](https://github.com/openjdk/jdk13/blob/master/src/jdk.hotspot.agent/linux/native/libsaproc/LinuxDebuggerLocal.c) (jdk13, but should be similar to 8)
<details>
<summary>Click to expand and see the native code that fails from LinuxDebuggerLocal.c</summary>

```c++
JNIEXPORT void JNICALL Java_sun_jvm_hotspot_debugger_linux_LinuxDebuggerLocal_attach0__I
  (JNIEnv *env, jobject this_obj, jint jpid) {

  // For bitness checking, locate binary at /proc/jpid/exe
  char buf[PATH_MAX];
  snprintf((char *) &buf, PATH_MAX, "/proc/%d/exe", jpid);
  verifyBitness(env, (char *) &buf);
  CHECK_EXCEPTION;

  char err_buf[200];
  struct ps_prochandle* ph;
  if ((ph = Pgrab(jpid, err_buf, sizeof(err_buf))) == NULL) {
    char msg[230];
    snprintf(msg, sizeof(msg), "Can't attach to the process: %s", err_buf);
    THROW_NEW_DEBUGGER_EXCEPTION(msg);
  }
  (*env)->SetLongField(env, this_obj, p_ps_prochandle_ID, (jlong)(intptr_t)ph);
  fillThreadsAndLoadObjects(env, this_obj, ph);
}
```
</details>

[2] [LinuxDebuggerLocal.java](https://github.com/infobip/infobip-open-jdk-8/blob/master/hotspot/agent/src/share/classes/sun/jvm/hotspot/debugger/linux/LinuxDebuggerLocal.java#L269) (a copy of the openjdk8 source code) 
<details>
<summary>Click to expand and see the java code that fails from LinuxDebuggerLocal.java</summary>

```java
    /** From the Debugger interface via JVMDebugger */
    public synchronized void attach(int processID) throws DebuggerException {
        checkAttached();
        threadList = new ArrayList();
        loadObjectList = new ArrayList();
        class AttachTask implements WorkerThreadTask {
           int pid;
           public void doit(LinuxDebuggerLocal debugger) {
              debugger.attach0(pid);
              debugger.attached = true;
              debugger.isCore = false;
              findABIVersion();
           }
        }

        AttachTask task = new AttachTask();
        task.pid = processID;
        workerThread.execute(task);
    }
```
</details>

# 4. Difference User, Force with jmap -F makes a corrupt file
Since I wasn't able to reproduce the problem with docker. I setup a Centos6 VM with a root user and notroot user.
```bash
scp -r .\01-get-heap-dump\use.heap.service\target\lib notroot@192.168.56.101:/home/notroot
scp .\01-get-heap-dump\use.heap.service\target\use.heap.service-1.0-SNAPSHOT.jar notroot@192.168.56.101:/home/notroot
scp -r .\01-get-heap-dump\count.hprof\target\lib notroot@192.168.56.101:/home/notroot/libCountHprof
scp .\01-get-heap-dump\count.hprof\target\count.hprof-1.0-SNAPSHOT.jar notroot@192.168.56.101:/home/notroot
ssh notroot@192.168.56.101
sudo yum install java-1.8.0-openjdk-devel
nohup java -cp lib/*:use.heap.service-1.0-SNAPSHOT.jar Server &
# works as expected
jmap -dump:live,format=b,file=/tmp/valid.heap.hprof $(pidof java)
Dumping heap to /tmp/valid.heap.hprof ...
Heap dump file created
logout
ssh root@192.168.56.101
# without -F fails as expected
jmap -dump:live,format=b,file=/tmp/corrupted.heap.hprof $(pidof java)
2103: Unable to open socket file: target process not responding or HotSpot VM not loaded
The -F option can be used when the target process is not responding

# -F still does not work:
jmap -F -dump:live,format=b,file=/tmp/corrupted.heap.hprof $(pidof java)
Attaching to process ID 2103, please wait...
Debugger attached successfully.
Server compiler detected.
JVM version is 25.242-b07
Dumping heap to /tmp/heap.hprof ...
Exception in thread "main" java.lang.reflect.InvocationTargetException
        at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
        at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
        at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
        at java.lang.reflect.Method.invoke(Method.java:498)
        at sun.tools.jmap.JMap.runTool(JMap.java:201)
        at sun.tools.jmap.JMap.main(JMap.java:130)
Caused by: java.lang.InternalError: Metadata does not appear to be polymorphic
        at sun.jvm.hotspot.types.basic.BasicTypeDataBase.findDynamicTypeForAddress(BasicTypeDataBase.java:278)
        at sun.jvm.hotspot.runtime.VirtualBaseConstructor.instantiateWrapperFor(VirtualBaseConstructor.java:102)
        at sun.jvm.hotspot.oops.Metadata.instantiateWrapperFor(Metadata.java:68)
        at sun.jvm.hotspot.memory.DictionaryEntry.klass(DictionaryEntry.java:71)
        at sun.jvm.hotspot.memory.Dictionary.classesDo(Dictionary.java:66)
        at sun.jvm.hotspot.memory.SystemDictionary.classesDo(SystemDictionary.java:190)
        at sun.jvm.hotspot.memory.SystemDictionary.allClassesDo(SystemDictionary.java:183)
        at sun.jvm.hotspot.utilities.HeapHprofBinWriter.writeClasses(HeapHprofBinWriter.java:954)
        at sun.jvm.hotspot.utilities.HeapHprofBinWriter.write(HeapHprofBinWriter.java:427)
        at sun.jvm.hotspot.tools.HeapDumper.run(HeapDumper.java:62)
        at sun.jvm.hotspot.tools.Tool.startInternal(Tool.java:260)
        at sun.jvm.hotspot.tools.Tool.start(Tool.java:223)
        at sun.jvm.hotspot.tools.Tool.execute(Tool.java:118)
        at sun.jvm.hotspot.tools.HeapDumper.main(HeapDumper.java:83)
        ... 6 more

ls -lah  /tmp/*.heap.hprof
-rw-r--r--. 1 root    root    1.4M Feb 21 19:48 /tmp/corrupted.heap.hprof
-rw-------. 1 notroot notroot 3.8M Feb 21 19:44 /tmp/valid.heap.hprof

# but that file is corrupted!
cd /home/notroot
java -cp libCountHprof/*:count.hprof-1.0-SNAPSHOT.jar CountHprof -hprof /tmp/valid.heap.hprof
23563
java -cp libCountHprof/*:count.hprof-1.0-SNAPSHOT.jar CountHprof -hprof /tmp/corrupted.heap.hprof
0


```

# 5. Alpine Docker jmap: Unable to get pid of LinuxThreads manager thread
```powershell
$dockerId = docker run -detach --publish 4567:4567 com.josephmate/use.heap.service.alpine:1.0-SNAPSHOT
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
```powershell
$dockerId = docker run --init -detach --publish 4567:4567 com.josephmate/use.heap.service.alpine:1.0-SNAPSHOT
docker exec --interactive --tty --user notroot $dockerId ash
jmap -dump:live,format=b,file=/tmp/heap.hprof $(pidof java)
```
Unfortunately, you will have to restart the container to be able to dump heap. Attach won't work without `--init`.


# 6. SE Linux
You can't setup SE Linux on docker image. As a result, for this section we setup a Centos7 VM with SE Linux

```bash
scp -r .\01-get-heap-dump\use.heap.service\target\lib notroot@192.168.56.103:/home/notroot
scp .\01-get-heap-dump\use.heap.service\target\use.heap.service-1.0-SNAPSHOT.jar notroot@192.168.56.103:/home/notroot
scp -r .\01-get-heap-dump\count.hprof\target\lib notroot@192.168.56.103:/home/notroot/libCountHprof
scp .\01-get-heap-dump\count.hprof\target\count.hprof-1.0-SNAPSHOT.jar notroot@192.168.56.103:/home/notroot

ssh root@192.168.56.103
yum install java-1.8.0-openjdk-devel
yum install policycoreutils policycoreutils-python selinux-policy selinux-policy-targeted libselinux-utils setools setools-console
reboot


ssh notroot@192.168.56.103
nohup java -cp lib/*:use.heap.service-1.0-SNAPSHOT.jar Server &
# works as expected
jmap -dump:live,format=b,file=/tmp/valid.heap.hprof $(pidof java)

# TODO figure out what selinux policies were need to cause jmap to fail
# TODO figure out what error message looks like in the selinux audit logs

```

# 7. GC or CPU Overloaded



# 8. Only JRE
## 1. How far apart the versions can be
## 2. Core dump

# 9. jmap under the hood

# 10. Eclipse OpenJ9
OpenJ9 JDKs 8, 11, 12, and 13 do not support the jmap -dump option and JDK9 doesn't have jmap at all.

<details>
<summary>Click to see JDK8 not recognizing the -dump option</summary>

```powershell
$dockerId = docker run --init -detach --publish 4567:4567 com.josephmate/use.heap.service.openj9.jdk8:1.0-SNAPSHOT
docker exec --interactive --tty --user notroot $dockerId bash
jmap -dump:live,format=b,file=/tmp/heap.hprof $(pidof java)
exactly one option must be selected
jmap: obtain heap information about a Java process
 Usage:
    jmap <option>* <vmid>
        <vmid>: Attach API VM ID as shown in jps or other Attach API-based tools
        <vmid>s are read from stdin if none are supplied as arguments
    -histo: print statistics about classes on the heap, including number of objects and aggregate size
    -histo:live : Print only live objects
    -J: supply arguments to the Java VM running jmap
NOTE: this utility may significantly affect the performance of the target VM.
At least one option must be selected.
```
</details>

<details>
<summary>Click to see JDK9 not having jmap</summary>

```powershell
$dockerId = docker run --init -detach --publish 4567:4567 com.josephmate/use.heap.service.openj9.jdk9:1.0-SNAPSHOT
docker exec --interactive --tty --user notroot $dockerId bash
jmap -dump:live,format=b,file=/tmp/heap.hprof $(pidof java)
bash: jmap: command not found
```
</details>

<details>
<summary>Click to see JDK11 not recognizing the -dump option</summary>

```powershell
$dockerId = docker run --init -detach --publish 4567:4567 com.josephmate/use.heap.service.openj9.jdk11:1.0-SNAPSHOT
docker exec --interactive --tty --user notroot $dockerId bash
jmap -dump:live,format=b,file=/tmp/heap.hprof $(pidof java)
exactly one option must be selected
jmap: obtain heap information about a Java process
 Usage:
    jmap <option>* <vmid>
        <vmid>: Attach API VM ID as shown in jps or other Attach API-based tools
        <vmid>s are read from stdin if none are supplied as arguments
    -histo: print statistics about classes on the heap, including number of objects and aggregate size
    -histo:live : Print only live objects
    -J: supply arguments to the Java VM running jmap
NOTE: this utility may significantly affect the performance of the target VM.
At least one option must be selected.
```
</details>

<details>
<summary>Click to see JDK12 not recognizing the -dump option</summary>

```powershell
$dockerId = docker run --init -detach --publish 4567:4567 com.josephmate/use.heap.service.openj9.jdk12:1.0-SNAPSHOT
docker exec --interactive --tty --user notroot $dockerId bash
jmap -dump:live,format=b,file=/tmp/heap.hprof $(pidof java)
exactly one option must be selected
jmap: obtain heap information about a Java process
 Usage:
    jmap <option>* <vmid>
        <vmid>: Attach API VM ID as shown in jps or other Attach API-based tools
        <vmid>s are read from stdin if none are supplied as arguments
    -histo: print statistics about classes on the heap, including number of objects and aggregate size
    -histo:live : Print only live objects
    -J: supply arguments to the Java VM running jmap
NOTE: this utility may significantly affect the performance of the target VM.
At least one option must be selected.
```
</details>


<details>
<summary>Click to see JDK13 not recognizing the -dump option</summary>

```powershell
$dockerId = docker run --init -detach --publish 4567:4567 com.josephmate/use.heap.service.openj9.jdk13:1.0-SNAPSHOT
docker exec --interactive --tty --user notroot $dockerId bash
jmap -dump:live,format=b,file=/tmp/heap.hprof $(pidof java)
unrecognized option -dump:live,format=b,file=/tmp/heap.hprof
jmap: obtain heap information about a Java process
 Usage:
    jmap <option>* <vmid>
        <vmid>: Attach API VM ID as shown in jps or other Attach API-based tools
        <vmid>s are read from stdin if none are supplied as arguments
    -histo: print statistics about classes on the heap, including number of objects and aggregate size
    -histo:live : Print only live objects
    -J: supply arguments to the Java VM running jmap
NOTE: this utility may significantly affect the performance of the target VM.
At least one option must be selected.
```
</details>


Instead you can use jcmd in jdk 13 to trigger a heap dump:
<details>
<summary>Click to see JDK 13 creating a heap dump using jcmd</summary>

```powershell
$dockerId = docker run --init -detach --publish 4567:4567 com.josephmate/use.heap.service.openj9.jdk13:1.0-SNAPSHOT
docker exec --interactive --tty --user notroot $dockerId bash
jcmd $(pidof java) Dump.heap myHeapDump.hprof
Dump written to /tmp/myHeapDump.hprof
```
</details>

Unfortunately, jcmd is not found in jdk 8, 9, 11, 12 which make sense because 
[OpenJ9's Implement jcmd task](https://github.com/eclipse/openj9/issues/5164) says they placed jcmd only in in Release 0.16 JDK 13.
As a result, for 8,9,11, and 12 I don't have a way getting the heap dump from an already running JVM.
<details>
<summary>Click to see JDK8 not having jcmd</summary>

```powershell
$dockerId = docker run --init -detach --publish 4567:4567 com.josephmate/use.heap.service.openj9.jdk8:1.0-SNAPSHOT
docker exec --interactive --tty --user notroot $dockerId bash
jcmd $(pidof java) Dump.heap myHeapDump.hprof
bash: jcmd: command not found
exit
docker kill $dockerId
```
</details>
<details>
<summary>Click to see JDK9 not having jcmd</summary>

```powershell
$dockerId = docker run --init -detach --publish 4567:4567 com.josephmate/use.heap.service.openj9.jdk9:1.0-SNAPSHOT
docker exec --interactive --tty --user notroot $dockerId bash
jcmd $(pidof java) Dump.heap myHeapDump.hprof
bash: jcmd: command not found
exit
docker kill $dockerId
```
</details>
<details>
<summary>Click to see JDK11 not having jcmd</summary>

```powershell
$dockerId = docker run --init -detach --publish 4567:4567 com.josephmate/use.heap.service.openj9.jdk11:1.0-SNAPSHOT
docker exec --interactive --tty --user notroot $dockerId bash
jcmd $(pidof java) Dump.heap myHeapDump.hprof
bash: jcmd: command not found
exit
docker kill $dockerId
```
</details>

<details>
<summary>Click to see JDK13 not recognizing the -dump option</summary>

```powershell
$dockerId = docker run --init -detach --publish 4567:4567 com.josephmate/use.heap.service.openj9.jdk12:1.0-SNAPSHOT
docker exec --interactive --tty --user notroot $dockerId bash
jcmd $(pidof java) Dump.heap myHeapDump.hprof
bash: jcmd: command not found
exit
docker kill $dockerId
```
</details>
