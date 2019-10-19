import static spark.Spark.*;

public class Server {
    public static void main(String[] args) {
        get("/health", (req, res) -> "Ready");
    }
}
