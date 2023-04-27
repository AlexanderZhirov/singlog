import singlog;

void main(string[] argv) {
    log.output(log.SYSLOG | log.STDOUT | log.FILE)
        .name(argv[0])
        .level(Log.DEBUGGING)
        .file("./test.log");
    log.e("hello!");
    log.w("hello!");
    log.i("hello!");
}
