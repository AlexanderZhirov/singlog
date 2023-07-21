import singlog;

void main(string[] argv) {
    log.output(log.output.syslog.stderr.stdout.file)    // write to syslog, standard error/output streams and file
        .program(argv[0])                               // program name as an identifier (for Windows OS)
        .level(log.level.debugging)                     // logging level
        .color(true)                                    // color text output
        .file("./test.log");                            // the path to the log file

    log.i("This is an information message");
    log.n("This is a notice message");
    log.w("This is a warning message");
    log.e("This is an error message");
    log.c("This is a critical message");
    log.a("This is an alert message");
    log.d("This is a debug message");

    log.now(log.output.stdout).n("This error message will only be written to the standard output stream");
    log.now(log.output.syslog.file).c("This error message will only be written to the syslog and file");
}
