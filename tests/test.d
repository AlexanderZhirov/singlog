import singlog;

void main(string[] argv) {
    log.output(log.SYSLOG | log.STDOUT | log.FILE)  // write to syslog, standard output stream and file
        .program(argv[0])                           // program name as an identifier (for Windows OS)
        .level(log.DEBUGGING)                       // logging level
        .color(true)                                // color text output
        .file("./test.log");                        // the path to the log file

    log.i("This is an information message");
    log.n("This is a notice message");
    log.w("This is a warning message");
    log.e("This is an error message");
    log.c("This is a critical message");
    log.a("This is an alert message");
    log.d("This is a debug message");
}
