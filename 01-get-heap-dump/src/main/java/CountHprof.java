import org.kohsuke.args4j.*;
import org.netbeans.lib.profiler.heap.*;

import java.io.File;
import java.util.List;

public class CountHprof {

    @Option(name="-hprof", usage="The filesystem path pointing to the hprof file to dump", required=true)
    private String hprofPath = null;

    public static void main(String[] args) throws Exception {
        CountHprof bean = new CountHprof();
        CmdLineParser parser = new CmdLineParser(bean);
        try {
            parser.parseArgument(args);
            bean.run();
        } catch (CmdLineException e) {
            // handling of wrong arguments
            System.err.println(e.getMessage());
            parser.printUsage(System.err);
        }
    }

    public void run() throws Exception {
        Heap heap = HeapFactory.createHeap(new File(hprofPath));
        long count = 0;
        @SuppressWarnings("unchecked")
        List<JavaClass> javaClasses = heap.getAllClasses();
        for(JavaClass javaClass : javaClasses) {
            @SuppressWarnings("unchecked")
            List<Instance> instances = javaClass.getInstances();
            for (Instance instance : instances) {
                count++;
            }
        }
        System.out.print(count);
    }
}
