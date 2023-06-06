module singlog;

version(Windows)
    import core.sys.windows.windows;
else version(Posix)
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
    log.program("My program");
    // Setting the status of color text output
    log.color(true);
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
    static Log _log;
    string _path;
    string _name = "singlog";
    bool _writeToFile = true;
    bool _ccolor = false;
    
    this() {}

version(Windows) {
    int[] _sysPriority = [0, 1, 1, 1, 2, 3, 3];

    WORD[] _sysPriorityOS = [
        EVENTLOG_SUCCESS,
        EVENTLOG_ERROR_TYPE,
        EVENTLOG_WARNING_TYPE,
        EVENTLOG_INFORMATION_TYPE
    ];

    void writesyslog(string message, WORD priority) {
        import std.utf: toUTF16z;
        auto wMessage = message.toUTF16z();
        HANDLE handleEventLog = RegisterEventSourceA(NULL, this._name.toStringz());

        if (handleEventLog == NULL)
            return;
        
        ReportEventW(handleEventLog, priority, 0, 0, NULL, 1, 0, &wMessage, NULL);
        DeregisterEventSource(handleEventLog);
    }

    WORD[] _color = [
        FOREGROUND_GREEN,
        FOREGROUND_BLUE,
        FOREGROUND_RED | FOREGROUND_BLUE,
        FOREGROUND_RED,
        FOREGROUND_RED | FOREGROUND_GREEN,
        FOREGROUND_BLUE | FOREGROUND_GREEN,
        FOREGROUND_RED | FOREGROUND_BLUE | FOREGROUND_GREEN
    ];

    void colorTextOutput(string time, wstring message, int priority) {
        HANDLE handle =  GetStdHandle(STD_OUTPUT_HANDLE);
        CONSOLE_SCREEN_BUFFER_INFO defaultConsole;
        GetConsoleScreenBufferInfo(handle, &defaultConsole);

        writef("%s ", time);
        SetConsoleTextAttribute(handle, this._color[priority] | FOREGROUND_INTENSITY);
        write(this._type[priority]);
        SetConsoleTextAttribute(handle, this._color[priority]);
        WriteConsoleW(handle, message.ptr, cast(DWORD)message.length, NULL, NULL);
        SetConsoleTextAttribute(handle, defaultConsole.wAttributes);
    }

    void defaultTextOutput(string time, wstring message, int priority) {
        HANDLE handle =  GetStdHandle(STD_OUTPUT_HANDLE);
        writef("%s %s", time, this._type[priority]);
        WriteConsoleW(handle, message.ptr, cast(DWORD)message.length, NULL, NULL);
    }

    void writestdout(string time, string message, int priority) {
        wstring wMessage = " %s\n".format(message).to!wstring;
        this._ccolor ?
            colorTextOutput(time, wMessage, priority) :
                defaultTextOutput(time, wMessage, priority);
    }

} else version(Posix) {
    int[] _sysPriority = [0, 1, 2, 3, 4, 5, 6];

    int[] _sysPriorityOS = [
        LOG_DEBUG,
        LOG_ALERT,
        LOG_CRIT,
        LOG_ERR,
        LOG_WARNING,
        LOG_NOTICE,
        LOG_INFO
    ];

    string[] _color = [
        "\x1b[1;32m%s\x1b[0;32m %s\x1b[0;0m",   // green
        "\x1b[1;34m%s\x1b[0;34m %s\x1b[0;0m",   // blue
        "\x1b[1;35m%s\x1b[0;35m %s\x1b[0;0m",   // magenta
        "\x1b[1;31m%s\x1b[0;31m %s\x1b[0;0m",   // red
        "\x1b[1;33m%s\x1b[0;33m %s\x1b[0;0m",   // yellow
        "\x1b[1;36m%s\x1b[0;36m %s\x1b[0;0m",   // cyan
        "\x1b[1;97m%s\x1b[0;97m %s\x1b[0;0m",   // white
    ];

    void writestdout(string time, string message, int priority) {
        writefln("%s %s",
                time,
                (this._ccolor ? this._color[priority] : "%s %s").format(this._type[priority], message)
        );
    }

    void writesyslog(string message, int priority) {
        syslog(priority, message.toStringz());
    }
}

    public enum {
        DEBUGGING   = 0,
        ALERT       = 1,
        CRITICAL    = 2,
        ERROR       = 3,
        WARNING     = 4,
        NOTICE      = 5,
        INFORMATION = 6
    }

    string[] _type = [
        "[DEBUG]:",
        "[ALERT]:",
        "[CRITICAL]:",
        "[ERROR]:",
        "[WARNING]:",
        "[NOTICE]:",
        "[INFO]:"
    ];

    public enum {
        SYSLOG = 1,
        STDOUT = 2,
        FILE = 4
    }

    int _output = STDOUT;
    int _priority = INFORMATION;

    void writelog(string message, int priority) {
        string time;
        if (this._priority > priority)
            return;
        if (this._output & 1)
            writesyslog(message, _sysPriorityOS[_sysPriority[priority]]);
        if (this._output & 6)
            time = Clock.currTime().format("%Y.%m.%d %H:%M:%S");
        if (this._output & 2)
            writestdout(time, message, priority);
        if (this._output & 4)
            writefile(time, message, priority);
    }

    void writefile(string time, string message, int priority) {
        if (!this._writeToFile)
            return;

        if (!this._path.exists) {
            this._writeToFile = false;
            this.warning("The log file does not exist: " ~ this._path);
        }

        File file;

        try {
            file = File(this._path, "a+");
            this._writeToFile = true;
        } catch (Exception e) {
            this._writeToFile = false;
            this.error("Unable to open the log file " ~ this._path);
            this.information(e);
            return;
        }

        try {            
            file.writefln("%s %s %s", time, this._type[priority], message);
        } catch (Exception e) {
            this._writeToFile = false;
            this.error("Unable to write to the log file " ~ this._path);
            this.information(e);
            return;
        }

        try {
            file.close();
        } catch (Exception e) {
            this._writeToFile = false;
            this.error("Unable to close the log file " ~ this._path);
            this.information(e);
            return;
        }
    }
    
public:
    @property static Log msg() {
        if (this._log is null)
            this._log = new Log;

        return this._log;
    }

    Log output(int outs) { this._output = outs; return this._log; }
    Log program(string name) { this._name = name; return this._log; }
    Log file(string path) { this._path = path; return this._log; }
    Log level(int priority) { this._priority = priority; return this._log; }
    Log color(bool condition) { this._ccolor = condition; return this._log; }

    void alert(T)(T message) { writelog(message.to!string, ALERT); }
    void critical(T)(T message) { writelog(message.to!string, CRITICAL); }
    void error(T)(T message) { writelog(message.to!string, ERROR); }
    void warning(T)(T message) { writelog(message.to!string, WARNING); }
    void notice(T)(T message) { writelog(message.to!string, NOTICE); }
    void information(T)(T message) { writelog(message.to!string, INFORMATION); }
    void debugging(T)(T message) { writelog(message.to!string, DEBUGGING); }

    alias a = alert;
    alias c = critical;
    alias e = error;
    alias w = warning;
    alias n = notice;
    alias i = information;
    alias d = debugging;
}
