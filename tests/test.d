import singlog;

void main(string[] argv) {
    log.output(log.SYSLOG | log.STDOUT | log.FILE)  // write to syslog, standard output stream and file
        .name(argv[0])                              // program name as an identifier (for Windows OS)
        .level(log.DEBUGGING)                       // logging level
        .file("./test.log");                        // the path to the log file

    log.e("This is an error message");
    log.error("And this is also an error message");
    log.w("This is a warning message");
    log.i("This is an information message");
}
