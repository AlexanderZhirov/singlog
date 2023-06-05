module singlog;

version(Windows)
    import core.sys.windows.windows;
else
    import core.sys.posix.syslog;

import std.string;
import std.stdio;
import std.conv;
import std.file;
import std.datetime;
import datefmt;

alias log = Log.msg;

/++
    Singleton for simple logging

    ---
    // Setting the name of the logged program
    log.name("My program");
    // Setting the error output level
    log.level(log.DEBUGGING);
    log.level(log.ALERT);
    log.level(log.CRITICAL);
    log.level(log.ERROR);
    log.level(log.WARNING);
    log.level(log.NOTICE);
    log.level(log.INFORMATION);
    // Assigning a target output
    log.output(log.SYSLOG);
    log.output(log.STDOUT);
    log.output(log.FILE);
    // Setup and allowing writing to a file
    log.file("./file.log");
    // Output of messages to the log
    log.debugging("Debugging message");
    log.alert("Alert message");
    log.critical("Critical message");
    log.error("Error message");
    log.warning("Warning message");
    log.notice("Notice message");
    log.informations("Information message");
    ---
+/
class Log {
private:
    static Log log;
    string path;
    string nameProgram = "singlog";
    bool writeToFile = true;
    
    this() {}

version(Windows) {
    public enum {
        DEBUGGING   = 0,
        ALERT       = 1,
        CRITICAL    = 1,
        ERROR       = 1,
        WARNING     = 2,
        NOTICE      = 3,
        INFORMATION = 3,
    }
    WORD[] sysLevel = [
        EVENTLOG_SUCCESS,
        EVENTLOG_ERROR_TYPE,
        EVENTLOG_WARNING_TYPE,
        EVENTLOG_INFORMATION_TYPE
    ];

    void syslog(WORD priority, LPCSTR message) {
        HANDLE handleEventLog = RegisterEventSourceA(NULL, this.nameProgram.toStringz());

        if (handleEventLog == NULL)
            return;
        
        ReportEventA(handleEventLog, priority, 0, 0, NULL, 1, 0, &message, NULL);
        DeregisterEventSource(handleEventLog);
    }
} else version(Posix) {
    public enum {
        DEBUGGING   = 0,
        ALERT       = 1,
        CRITICAL    = 2,
        ERROR       = 3,
        WARNING     = 4,
        NOTICE      = 5,
        INFORMATION = 6
    }
    int[] sysLevel = [
        LOG_DEBUG,
        LOG_ALERT,
        LOG_CRIT,
        LOG_ERR,
        LOG_WARNING,
        LOG_NOTICE,
        LOG_INFO
    ];
}

    string[] color = [
        "\u001b[2;30m[DEBUG]:\u001b[0;30m %s\u001b[0;0m",
        "\u001b[1;34m[ALERT]:\u001b[0;34m %s\u001b[0;0m",
        "\u001b[1;35m[CRITICAL]:\u001b[0;35m %s\u001b[0;0m",
        "\u001b[1;31m[ERROR]:\u001b[0;31m %s\u001b[0;0m",
        "\u001b[1;33m[WARNING]:\u001b[0;33m %s\u001b[0;0m",
        "\u001b[1;36m[NOTICE]:\u001b[0;36m %s\u001b[0;0m",
        "\u001b[1;32m[INFO]:\u001b[0;32m %s\u001b[0;0m",
    ];

    public enum {
        SYSLOG = 1,
        STDOUT = 2,
        FILE = 4
    }

    int msgOutput = STDOUT;
    int msgLevel = INFORMATION;

    void writeLog(string message, int msgLevel) {
        if (this.msgLevel > msgLevel)
            return;
        if (this.msgOutput & 1)
            syslog(sysLevel[msgLevel], message.toStringz());
        if (this.msgOutput & 6)
            message = Clock.currTime().format("%Y.%m.%d %H:%M:%S ") ~ color[msgLevel].format(message);
        if (this.msgOutput & 2)
            writeln(message);
        if (this.msgOutput & 4)
            writeFile(message);
    }

    void writeFile(string message) {
        if (!this.writeToFile)
            return;

        if (!this.path.exists) {
            this.writeToFile = false;
            this.warning("The log file does not exist: " ~ this.path);
        }

        File file;

        try {
            file = File(this.path, "a+");
            this.writeToFile = true;
        } catch (Exception e) {
            this.writeToFile = false;
            this.error("Unable to open the log file " ~ this.path);
            this.information(e);
            return;
        }

        try {            
            file.writeln(message);
        } catch (Exception e) {
            this.writeToFile = false;
            this.error("Unable to write to the log file " ~ this.path);
            this.information(e);
            return;
        }

        try {
            file.close();
        } catch (Exception e) {
            this.writeToFile = false;
            this.error("Unable to close the log file " ~ this.path);
            this.information(e);
            return;
        }
    }
    
public:
    @property static Log msg() {
        if (this.log is null)
            this.log = new Log;

        return this.log;
    }

    Log output(int msgOutput) { this.msgOutput = msgOutput; return this.log; }
    Log name(string nameProgram) { this.nameProgram = nameProgram; return this.log; }
    Log file(string path) { this.path = path; return this.log; }
    Log level(int msgLevel) { this.msgLevel = msgLevel; return this.log; }

    void alert(T)(T message) { writeLog(message.to!string, ALERT); }
    void critical(T)(T message) { writeLog(message.to!string, CRITICAL); }
    void error(T)(T message) { writeLog(message.to!string, ERROR); }
    void warning(T)(T message) { writeLog(message.to!string, WARNING); }
    void notice(T)(T message) { writeLog(message.to!string, NOTICE); }
    void information(T)(T message) { writeLog(message.to!string, INFORMATION); }
    void debugging(T)(T message) { writeLog(message.to!string, DEBUGGING); }

    alias a = alert;
    alias c = critical;
    alias e = error;
    alias w = warning;
    alias n = notice;
    alias i = information;
    alias d = debugging;
}
