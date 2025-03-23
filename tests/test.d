import singlog;
import std.format : format;
import std.exception : enforce;

/++
    Logging Levels Table:
    Level         | Value    | Description
    --------------|----------|---------
    DEBUGGING     | 0        | Debugging information (highest)
    ALERT         | 1        | Urgent alerts
    CRITICAL      | 2        | Critical errors
    ERROR         | 3        | Errors
    WARNING       | 4        | Warnings
    NOTICE        | 5        | Notices
    INFORMATION   | 6        | Informational messages (lowest)
+/
void main(string[] argv) {
    // Logger configuration
    log.color(true)                           // Enable colored output
       .level(log.level.error)               // Threshold ERROR (3): shows ERROR and less critical (≥3)
       .output(log.output.std.file.syslog)   // Set all three output targets
       .file("./test.log")                     // Set log file
       .program(argv[0]);                // Set program name (Windows only)

    // Application start
    log.i("ChainDemo application started");  // INFO (6) >= 3
    log.e("Logging with ERROR level activated"); // ERROR (3) >= 3

    // Level demonstration
    log.e("Error during operation");         // ERROR (3) >= 3
    log.w("Warning");                        // WARNING (4) >= 3
    log.n("Important notice");               // NOTICE (5) >= 3
    log.d("Debugging not shown");            // DEBUGGING (0) < 3
    log.i("General information");            // INFO (6) >= 3
    log.a("Alert not shown");                // ALERT (1) < 3

    // Example with data types
    int errorCode = 500;
    log.e("Server error %d".format(errorCode)); // ERROR (3) >= 3

    // Temporary output redirection
    log.now(log.output.std).e("Error only to console"); // ERROR (3) >= 3

    // Exception handling
    try {
        enforce(false, "Test exception");
    } catch (Exception e) {
        log.e("Exception: %s".format(e.msg)); // ERROR (3) >= 3
    }

    // Configuration change
    log.color(true)
       .level(log.level.alert)           // Threshold CRITICAL (2): shows CRITICAL and less critical (≥2)
       .output(log.output.std.file);
    log.e("This message will be shown (ERROR >= CRITICAL)"); // ERROR (3) >= 2
    log.a("Configuration changed, ALERT messages"); // ALERT (1) >= 2

    // Finale
    log.c("Demonstration completed");        // CRITICAL (2) >= 2
}
