$workingDir=(Get-Item -Path ".\" -Verbose).FullName

# http://stackoverflow.com/questions/4762982/powershell-get-process-id-of-called-application
# http://stackoverflow.com/questions/651223/powershell-start-process-and-cmdline-switches
$p=Start-Process -FilePath "java" -ArgumentList '-cp','target/lib/*;target\use.heap.service-1.0-SNAPSHOT.jar','Server' -PassThru

# wait 10 seconds for the memory to load
# TODO use localhost:4567/health to figure out when the service is ready
Start-Sleep -s 10

# generate the heap dump
jmap -dump:live,format=b,file=$workingDir\heap.dump.windows.hprof $p.Id


Stop-Process -id $p.Id
