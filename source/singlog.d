module singlog;

version(Windows) {
    import core.sys.windows.windows;
    import std.utf : toUTF8, toUTF16z;
} else version(Posix)
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
    log.level(log.level.debugging);
    log.level(log.level.alert);
    log.level(log.level.critical);
    log.level(log.level.error);
    log.level(log.level.warning);
    log.level(log.level.notice);
    log.level(log.level.information);
    // Assigning a target output
    log.output(log.output.syslog.stderr.stdout.file);
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
    // Write message to specific outputs
    log.now(log.output.stdout.file).informations("Information message");
    ---
+/
class Log {
private:
    static Log _log;
    string _path;
    wstring _name = "singlog";
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
        auto wMessage = message.toUTF16z();
        HANDLE handleEventLog = RegisterEventSourceW(NULL, this._name.ptr);

        if (handleEventLog == NULL)
            return;
        
        ReportEventW(handleEventLog, priority, 0, 0, NULL, 1, 0, &wMessage, NULL);
        DeregisterEventSource(handleEventLog);
    }

    WORD[] _color = [
        FOREGROUND_GREEN,                                       // green
        FOREGROUND_BLUE,                                        // blue
        FOREGROUND_RED | FOREGROUND_BLUE,                       // magenta
        FOREGROUND_RED,                                         // red
        FOREGROUND_RED | FOREGROUND_GREEN,                      // yellow
        FOREGROUND_BLUE | FOREGROUND_GREEN,                     // cyan
        FOREGROUND_RED | FOREGROUND_BLUE | FOREGROUND_GREEN     // white
    ];

    void colorTextOutput(HANDLE handle, string time, string message, int priority) {
        CONSOLE_SCREEN_BUFFER_INFO defaultConsole;
        GetConsoleScreenBufferInfo(handle, &defaultConsole);

        wstring wTime = "%s ".format(time).to!wstring;
        wstring wType = this._type[priority].to!wstring;
        wstring wMessage = " %s\n".format(message).to!wstring;

        switch (GetFileType(handle)) {
            case FILE_TYPE_CHAR:
                WriteConsoleW(handle, wTime.ptr, cast(DWORD)wTime.length, NULL, NULL);
                SetConsoleTextAttribute(handle, this._color[priority] | FOREGROUND_INTENSITY);
                WriteConsoleW(handle, wType.ptr, cast(DWORD)wType.length, NULL, NULL);
                SetConsoleTextAttribute(handle, this._color[priority]);
                WriteConsoleW(handle, wMessage.ptr, cast(DWORD)wMessage.length, NULL, NULL);
                SetConsoleTextAttribute(handle, defaultConsole.wAttributes);
                break;
            case FILE_TYPE_PIPE, FILE_TYPE_DISK:
                auto utf8Message = (wTime ~ wType ~ wMessage).toUTF8;
                WriteFile(handle, utf8Message.ptr, cast(DWORD)utf8Message.length, NULL, NULL);
                break;
            default:
                writesyslog("Unknown output file", _sysPriorityOS[_sysPriority[ERROR]]);
        }
    }

    void defaultTextOutput(HANDLE handle, string time, string message, int priority) {
        wstring wMessage = "%s %s %s\n".format(time, this._type[priority], message).to!wstring;
        switch (GetFileType(handle)) {
            case FILE_TYPE_CHAR:
                WriteConsoleW(handle, wMessage.ptr, cast(DWORD)wMessage.length, NULL, NULL);
                break;
            case FILE_TYPE_PIPE, FILE_TYPE_DISK:
                auto utf8Message = wMessage.toUTF8;
                WriteFile(handle, utf8Message.ptr, cast(DWORD)utf8Message.length, NULL, NULL);
                break;
            default:
                writesyslog("Unknown output file", _sysPriorityOS[_sysPriority[ERROR]]);
        }
    }

    void writestdout(string time, string message, int priority) {
        HANDLE handle =  GetStdHandle(STD_OUTPUT_HANDLE);
        this._ccolor ?
            colorTextOutput(handle, time, message, priority) :
                defaultTextOutput(handle, time, message, priority);
    }

    void writestderr(string time, string message, int priority) {
        HANDLE handle =  GetStdHandle(STD_ERROR_HANDLE);
        this._ccolor ?
            colorTextOutput(handle, time, message, priority) :
                defaultTextOutput(handle, time, message, priority);
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

    void writestderr(string time, string message, int priority) {
        stderr.writefln("%s %s",
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
        STDERR = 4,
        FILE = 8
    }

    int _nowoutput = 0;
    int _output = STDOUT;
    int _priority = INFORMATION;

    void writelog(string message, int priority) {
        string time;
        int output = this._nowoutput ? this._nowoutput : this._output;
        this._nowoutput = 0;
        if (this._priority > priority)
            return;
        if (output & 1)
            writesyslog(message, _sysPriorityOS[_sysPriority[priority]]);
        if (output & 14)
            time = Clock.currTime().format("%Y.%m.%d %H:%M:%S");
        if (output & 2 && priority >= WARNING)
            writestdout(time, message, priority);
        if (output & 4 && priority <= ERROR)
            writestderr(time, message, priority);
        if (output & 8)
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
            this.now(output.stderr).error("Unable to open the log file " ~ this._path);
            this.information(e);
            return;
        }

        try {            
            file.writefln("%s %s %s", time, this._type[priority], message);
        } catch (Exception e) {
            this._writeToFile = false;
            this.now(output.stderr).error("Unable to write to the log file " ~ this._path);
            this.information(e);
            return;
        }

        try {
            file.close();
        } catch (Exception e) {
            this._writeToFile = false;
            this.now(output.stderr).error("Unable to close the log file " ~ this._path);
            this.information(e);
            return;
        }
    }

    struct Output {
        int _output = STDOUT;
        int _newoutput = 0;

        int output() { return this._newoutput ? this._newoutput : this._output; }
    public:
        Output syslog() { this._newoutput |= SYSLOG; return this; }
        Output stdout() { this._newoutput |= STDOUT; return this; }
        Output stderr() { this._newoutput |= STDERR; return this; }
        Output file() { this._newoutput |= FILE; return this; }
    }

    struct Level {
    public:
        int debugging() { return DEBUGGING; }
        int alert() { return ALERT; }
        int critical() { return CRITICAL; }
        int error() { return ERROR; }
        int warning() { return WARNING; }
        int notice() { return NOTICE; }
        int information() { return INFORMATION; }

        alias d = debugging;
        alias a = alert;
        alias c = critical;
        alias e = error;
        alias w = warning;
        alias n = notice;
        alias i = information;
    }

    struct Now {
        this(Output outs) {
            _log._nowoutput = outs.output();
        }

    public:
        void alert(T)(T message) { _log.alert(message); }
        void critical(T)(T message) { _log.critical(message); }
        void error(T)(T message) { _log.error(message); }
        void warning(T)(T message) { _log.warning(message); }
        void notice(T)(T message) { _log.notice(message); }
        void information(T)(T message) { _log.information(message); }
        void debugging(T)(T message) { _log.debugging(message); }

        alias a = alert;
        alias c = critical;
        alias e = error;
        alias w = warning;
        alias n = notice;
        alias i = information;
        alias d = debugging;
    }
public:
    @property static Log msg() {
        if (this._log is null)
            this._log = new Log;

        return this._log;
    }

    Output output() { return Output(); }
    Level level() { return Level(); }
    Now now(Output outs) { return Now(outs); }

    Log output(Output outs) { this._output = outs.output(); return this._log; }
    deprecated("Use passing the argument as a `log.output.<outs>` object")
    Log output(int outs) { this._output = outs; return this._log; }
    Log program(string name) { this._name = name.to!wstring; return this._log; }
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
