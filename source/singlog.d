/++
    Singleton logging module with thread-safety and flexible output targets.

    This module provides a simple, thread-safe logging utility with support for multiple output targets
    (syslog, standard output/error, file), configurable log levels, and optional colored console output.
    It is designed to be cross-platform, working on both Windows and POSIX systems.

    The logger is implemented as a singleton, ensuring a single instance throughout the application.
    It supports fluent configuration for ease of use and provides short aliases for common log levels.
+/
module singlog;

version(Windows) {
    import core.sys.windows.windows;
    import std.utf : toUTF8, toUTF16z;
} else version(Posix) {
    import core.sys.posix.syslog;
}

import core.sync.mutex : Mutex;
import std.string;
import std.stdio;
import std.conv;
import std.file;
import std.datetime;
import datefmt;

/++
    Singleton logging class with thread-safe operations and flexible output.

    The `Log` class is the core of the `singlog` module, providing a robust logging system with the following features:
    - **Thread-safety**: Uses a `Mutex` to ensure safe logging in multi-threaded applications.
    - **Cross-platform**: Supports Windows (Event Log, console) and POSIX (syslog, console) systems.
    - **Flexible output**: Allows logging to syslog, stdout/stderr (based on log level), and files.
    - **Log levels**: Supports seven levels (`DEBUGGING`, `ALERT`, `CRITICAL`, `ERROR`, `WARNING`, `NOTICE`, `INFORMATION`).
    - **Fluent interface**: Enables easy configuration chaining for output targets, levels, and more.
    - **Colored output**: Optional color support for console messages (STD output only).

    The class is a singleton, accessible via the static `msg` property or the global `log` alias.

    Example:
    ---
    import singlog;

    void main() {
        // Configure the logger
        Log logger = Log.msg;  // Get singleton instance
        logger.program("TestApp")
              .color(true)
              .level(Log.DEBUGGING)
              .output(Log.Output().std.file.syslog)
              .file("test.log");

        // Log messages with full method names
        logger.debugging("Starting in debug mode");
        logger.information("App is running");
        logger.error("An error occurred");

        // Log messages with aliases
        logger.d("Debug alias");
        logger.i("Info alias");
        logger.e("Error alias");

        // Temporary output override
        logger.now(Log.Output().std).notice("Temporary console message");
    }
    ---
+/
class Log {
private:
    static Log _log;                /// Singleton instance of the logger
    Mutex _mutex;                   /// Mutex for thread-safety
    string _path;                   /// Path to the log file
    File _file;                     /// File handle for logging
    bool _fileOpen = false;         /// Indicates if the log file is open
    wstring _name = "singlog";      /// Program name for syslog identification
    bool _writeToFile = true;       /// Flag to enable/disable file logging
    bool _color = false;            /// Flag to enable/disable colored console output
    int _output = STD;              /// Default output flags (STD by default)
    int _priority = INFORMATION;    /// Minimum log level for output
    int _nowOutput = 0;             /// Temporary output override for the next log call

    /++ Private constructor to enforce singleton pattern +/
    this() {
        _mutex = new Mutex();
    }

    /++ Destructor to ensure the log file is closed +/
    ~this() {
        synchronized (_mutex) {
            if (_fileOpen) {
                _file.close();
                _fileOpen = false;
            }
        }
    }

version(Windows) {
    immutable int[] _sysPriority = [0, 1, 1, 1, 2, 3, 3]; /// Mapping of log levels to syslog priorities
    immutable WORD[] _sysPriorityOS = [ /// Windows Event Log types
        EVENTLOG_SUCCESS,           // DEBUGGING
        EVENTLOG_ERROR_TYPE,        // ALERT, CRITICAL, ERROR
        EVENTLOG_WARNING_TYPE,      // WARNING
        EVENTLOG_INFORMATION_TYPE   // NOTICE, INFORMATION
    ];

    immutable WORD[] _colorCodes = [ /// Console color codes for each log level
        FOREGROUND_GREEN,                                       // DEBUGGING (green)
        FOREGROUND_BLUE,                                        // ALERT (blue)
        FOREGROUND_RED | FOREGROUND_BLUE,                       // CRITICAL (magenta)
        FOREGROUND_RED,                                         // ERROR (red)
        FOREGROUND_RED | FOREGROUND_GREEN,                      // WARNING (yellow)
        FOREGROUND_BLUE | FOREGROUND_GREEN,                     // NOTICE (cyan)
        FOREGROUND_RED | FOREGROUND_BLUE | FOREGROUND_GREEN     // INFORMATION (white)
    ];

    /++
        Writes a message to the Windows Event Log.

        Params:
            message = The message to log.
            priority = The Windows Event Log type (e.g., EVENTLOG_ERROR_TYPE).
    +/
    void writesyslog(string message, WORD priority) {
        auto wMessage = message.toUTF16z();
        HANDLE handleEventLog = RegisterEventSourceW(null, _name.toUTF16z());
        if (handleEventLog == null) return;
        ReportEventW(handleEventLog, priority, 0, 0, null, 1, 0, &wMessage, null);
        DeregisterEventSource(handleEventLog);
    }

    /++
        Outputs a colored log message to the console on Windows.

        Params:
            handle = The console handle (STD_OUTPUT_HANDLE or STD_ERROR_HANDLE).
            time = The timestamp of the message.
            message = The message to log.
            priority = The log level (used to select the color).
    +/
    void colorTextOutput(HANDLE handle, string time, string message, int priority) {
        CONSOLE_SCREEN_BUFFER_INFO defaultConsole;
        if (!GetConsoleScreenBufferInfo(handle, &defaultConsole)) return;

        wstring wTime = "%s ".format(time).to!wstring;
        wstring wType = _type[priority].to!wstring;
        wstring wMessage = " %s\n".format(message).to!wstring;

        switch (GetFileType(handle)) {
            case FILE_TYPE_CHAR:
                WriteConsoleW(handle, wTime.ptr, cast(DWORD)wTime.length, null, null);
                SetConsoleTextAttribute(handle, _colorCodes[priority] | FOREGROUND_INTENSITY);
                WriteConsoleW(handle, wType.ptr, cast(DWORD)wType.length, null, null);
                SetConsoleTextAttribute(handle, _colorCodes[priority]);
                WriteConsoleW(handle, wMessage.ptr, cast(DWORD)wMessage.length, null, null);
                SetConsoleTextAttribute(handle, defaultConsole.wAttributes);
                break;
            case FILE_TYPE_PIPE, FILE_TYPE_DISK:
                auto utf8Message = (wTime ~ wType ~ wMessage).toUTF8;
                WriteFile(handle, utf8Message.ptr, cast(DWORD)utf8Message.length, null, null);
                break;
            default:
                writesyslog("Unknown output file", _sysPriorityOS[_sysPriority[ERROR]]);
        }
    }

    /++
        Outputs a plain log message to the console on Windows.

        Params:
            handle = The console handle (STD_OUTPUT_HANDLE or STD_ERROR_HANDLE).
            time = The timestamp of the message.
            message = The message to log.
            priority = The log level (used to format the message).
    +/
    void defaultTextOutput(HANDLE handle, string time, string message, int priority) {
        wstring wMessage = "%s %s %s\n".format(time, _type[priority], message).to!wstring;
        switch (GetFileType(handle)) {
            case FILE_TYPE_CHAR:
                WriteConsoleW(handle, wMessage.ptr, cast(DWORD)wMessage.length, null, null);
                break;
            case FILE_TYPE_PIPE, FILE_TYPE_DISK:
                auto utf8Message = wMessage.toUTF8;
                WriteFile(handle, utf8Message.ptr, cast(DWORD)utf8Message.length, null, null);
                break;
            default:
                writesyslog("Unknown output file", _sysPriorityOS[_sysPriority[ERROR]]);
        }
    }

    /++
        Writes a message to the console on Windows, choosing stdout or stderr based on log level.

        Params:
            time = The timestamp of the message.
            message = The message to log.
            priority = The log level (ERROR and above go to stderr, others to stdout).

        Example:
        ---
        log.writestd("2025.03.23 12:00:00", "Test error", ERROR);  // Outputs to stderr
        log.writestd("2025.03.23 12:00:01", "Test info", INFORMATION);  // Outputs to stdout
        ---
    +/
    void writestd(string time, string message, int priority) {
        HANDLE handle = (priority <= ERROR) ? 
            GetStdHandle(STD_ERROR_HANDLE) : 
            GetStdHandle(STD_OUTPUT_HANDLE);
        _color ? colorTextOutput(handle, time, message, priority) : defaultTextOutput(handle, time, message, priority);
    }
} else version(Posix) {
    immutable int[] _sysPriority = [0, 1, 2, 3, 4, 5, 6]; /// Mapping of log levels to syslog priorities
    immutable int[] _sysPriorityOS = [ /// POSIX syslog priorities
        LOG_DEBUG,      // DEBUGGING
        LOG_ALERT,      // ALERT
        LOG_CRIT,       // CRITICAL
        LOG_ERR,        // ERROR
        LOG_WARNING,    // WARNING
        LOG_NOTICE,     // NOTICE
        LOG_INFO        // INFORMATION
    ];

    immutable string[] _colorCodes = [ /// ANSI color codes for console output
        "\x1b[1;32m%s\x1b[0;32m %s\x1b[0;0m",   // DEBUGGING (green)
        "\x1b[1;34m%s\x1b[0;34m %s\x1b[0;0m",   // ALERT (blue)
        "\x1b[1;35m%s\x1b[0;35m %s\x1b[0;0m",   // CRITICAL (magenta)
        "\x1b[1;31m%s\x1b[0;31m %s\x1b[0;0m",   // ERROR (red)
        "\x1b[1;33m%s\x1b[0;33m %s\x1b[0;0m",   // WARNING (yellow)
        "\x1b[1;36m%s\x1b[0;36m %s\x1b[0;0m",   // NOTICE (cyan)
        "\x1b[1;97m%s\x1b[0;97m %s\x1b[0;0m"     // INFORMATION (white)
    ];

    /++
        Writes a message to the console on POSIX, choosing stdout or stderr based on log level.

        Params:
            time = The timestamp of the message.
            message = The message to log.
            priority = The log level (ERROR and above go to stderr, others to stdout).

        Example:
        ---
        log.writestd("2025.03.23 12:00:00", "Critical failure", CRITICAL);  // Outputs to stderr
        log.writestd("2025.03.23 12:00:01", "System ready", NOTICE);  // Outputs to stdout
        ---
    +/
    void writestd(string time, string message, int priority) {
        if (priority <= ERROR) {
            stderr.writefln("%s %s", time, (_color ? _colorCodes[priority] : "%s %s").format(_type[priority], message));
        } else {
            writefln("%s %s", time, (_color ? _colorCodes[priority] : "%s %s").format(_type[priority], message));
        }
    }

    /++
        Writes a message to the POSIX syslog.

        Params:
            message = The message to log.
            priority = The syslog priority level (e.g., LOG_ERR).

        Example:
        ---
        log.writesyslog("System crash", ERROR);  // Logs to syslog with LOG_ERR
        ---
    +/
    void writesyslog(string message, int priority) {
        syslog(priority, message.toStringz());
    }
}

    /// Log level constants
    public enum : int {
        DEBUGGING   = 0,    /// Debugging messages (lowest priority)
        ALERT       = 1,    /// Alert messages (high priority)
        CRITICAL    = 2,    /// Critical errors
        ERROR       = 3,    /// General errors
        WARNING     = 4,    /// Warnings
        NOTICE      = 5,    /// Notices
        INFORMATION = 6     /// Informational messages (highest priority)
    }

    /// Output target flags
    public enum : int {
        SYSLOG = 1,     /// System log (Event Log on Windows, syslog on POSIX)
        STD    = 2,     /// Standard output (stdout for >= WARNING, stderr for <= ERROR)
        FILE   = 8      /// File output
    }

    immutable string[] _type = [ /// Log level prefixes for formatting
        "[DEBUG]:", "[ALERT]:", "[CRITICAL]:", "[ERROR]:", "[WARNING]:", "[NOTICE]:", "[INFO]:"
    ];

    /++
        Core logging function that writes a message to configured outputs.

        Params:
            message = The message to log.
            priority = The log level of the message.

        Example:
        ---
        log.writelog("Application started", INFORMATION);  // Logs to configured outputs
        log.writelog("Fatal error", CRITICAL);  // Logs to stderr and other outputs
        ---
    +/
    void writelog(string message, int priority) {
        synchronized (_mutex) {
            if (_priority > priority) return;
            int output = _nowOutput ? _nowOutput : _output;
            _nowOutput = 0;

            string time;
            if (output & (STD | FILE)) {
                time = Clock.currTime().format("%Y.%m.%d %H:%M:%S");
            }

            if (output & SYSLOG) writesyslog(message, _sysPriorityOS[_sysPriority[priority]]);
            if (output & STD) writestd(time, message, priority);
            if (output & FILE) writefile(time, message, priority);
        }
    }

    /++
        Writes a message to the configured log file.

        Params:
            time = The timestamp of the message.
            message = The message to log.
            priority = The log level of the message.

        Example:
        ---
        log.writefile("2025.03.23 12:00:00", "File operation failed", ERROR);  // Writes to log file
        ---
    +/
    void writefile(string time, string message, int priority) {
        if (!_writeToFile) return;

        synchronized (_mutex) {
            if (!_fileOpen) {
                try {
                    _file = File(_path, "a+");
                    _fileOpen = true;
                } catch (Exception e) {
                    _writeToFile = false;
                    now(this.output.std).error("Unable to open the log file " ~ _path);
                    information(e.msg);
                    return;
                }
            }

            try {
                _file.writefln("%s %s %s", time, _type[priority], message);
            } catch (Exception e) {
                _writeToFile = false;
                now(this.output.std).error("Unable to write to the log file " ~ _path);
                information(e.msg);
            }
        }
    }

public:
    /++
        Property to access the singleton instance of the logger.

        Returns:
            The single instance of the `Log` class.

        Example:
        ---
        auto logger = Log.msg;  // Access the singleton logger
        logger.information("Logger retrieved");
        ---
    +/
    @property static Log msg() {
        if (_log is null) {
            synchronized {
                if (_log is null) _log = new Log();
            }
        }
        return _log;
    }

    /++
        Sets the program name for syslog identification.

        Params:
            name = The name of the program.

        Returns:
            This `Log` instance for chaining.

        Example:
        ---
        log.program("MyProgram");  // Sets syslog identifier to "MyProgram"
        log.i("Program name set");
        ---
    +/
    Log program(string name) {
        synchronized (_mutex) { _name = name.to!wstring; }
        return this;
    }

    /++
        Sets the file path for logging.

        Params:
            path = The path to the log file.

        Returns:
            This `Log` instance for chaining.

        Example:
        ---
        log.file("myapp.log");  // Sets log file to "myapp.log"
        log.i("Log file configured");
        ---
    +/
    Log file(string path) {
        synchronized (_mutex) {
            if (_fileOpen) { _file.close(); _fileOpen = false; }
            _path = path;
            _writeToFile = true;
        }
        return this;
    }

    /++
        Sets the minimum log level.

        Params:
            priority = The minimum log level (e.g., DEBUGGING, ERROR).

        Returns:
            This `Log` instance for chaining.

        Example:
        ---
        log.level(log.level.warning);  // Only WARNING and above will be logged
        log.d("This won't show");  // Ignored due to level
        log.w("This will show");
        ---
    +/
    Log level(int priority) {
        synchronized (_mutex) { _priority = priority; }
        return this;
    }

    /++
        Enables or disables colored console output.

        Params:
            condition = `true` to enable colors, `false` to disable.

        Returns:
            This `Log` instance for chaining.

        Example:
        ---
        log.color(true);  // Enables colored output
        log.i("This will be colored");
        log.color(false);  // Disables colored output
        log.i("This will be plain");
        ---
    +/
    Log color(bool condition) {
        synchronized (_mutex) { _color = condition; }
        return this;
    }

    /++
        Starts configuring output targets using a fluent interface.

        Returns:
            An `Output` struct for chaining output target methods.

        Example:
        ---
        auto outs = log.output.std.file;  // Configures std and file output
        log.output(outs);
        log.i("Logged to console and file");
        ---
    +/
    Output output() {
        return Output();
    }

    /++
        Sets the default output targets.

        Params:
            outs = An `Output` struct with configured targets.

        Returns:
            This `Log` instance for chaining.

        Example:
        ---
        log.output(log.output.syslog.std);  // Sets output to syslog and console
        log.i("Logged to syslog and console");
        ---
    +/
    Log output(Output outs) {
        synchronized (_mutex) { _output = outs.value; }
        return this;
    }

    /++
        Temporarily overrides output targets for the next log call.

        Params:
            outs = An `Output` struct with temporary targets.

        Returns:
            A `Now` struct to chain the log call.

        Example:
        ---
        log.now(log.output.std).n("Temporary console output");  // Only to console
        log.i("Back to default outputs");
        ---
    +/
    Now now(Output outs) {
        synchronized (_mutex) { _nowOutput = outs.value; }
        return Now(this);
    }

    /++
        Logs an alert message (priority ALERT).

        Params:
            message = The message to log (converted to string).

        Example:
        ---
        log.alert("System alert!");  // Logs with ALERT level
        log.a(42);  // Logs "42" with ALERT level
        ---
    +/
    void alert(T)(T message) { writelog(message.to!string, ALERT); }

    /++
        Logs a critical error message (priority CRITICAL).

        Params:
            message = The message to log (converted to string).

        Example:
        ---
        log.critical("Critical failure");  // Logs with CRITICAL level
        log.c("Out of memory");  // Alias usage
        ---
    +/
    void critical(T)(T message) { writelog(message.to!string, CRITICAL); }

    /++
        Logs an error message (priority ERROR).

        Params:
            message = The message to log (converted to string).

        Example:
        ---
        log.error("File not found");  // Logs with ERROR level to stderr
        log.e("Error code: 404");  // Alias usage
        ---
    +/
    void error(T)(T message) { writelog(message.to!string, ERROR); }

    /++
        Logs a warning message (priority WARNING).

        Params:
            message = The message to log (converted to string).

        Example:
        ---
        log.warning("Low disk space");  // Logs with WARNING level
        log.w("Check disk");  // Alias usage
        ---
    +/
    void warning(T)(T message) { writelog(message.to!string, WARNING); }

    /++
        Logs a notice message (priority NOTICE).

        Params:
            message = The message to log (converted to string).

        Example:
        ---
        log.notice("User logged in");  // Logs with NOTICE level
        log.n("Session started");  // Alias usage
        ---
    +/
    void notice(T)(T message) { writelog(message.to!string, NOTICE); }

    /++
        Logs an informational message (priority INFORMATION).

        Params:
            message = The message to log (converted to string).

        Example:
        ---
        log.information("App started");  // Logs with INFORMATION level
        log.i("Version 1.0");  // Alias usage
        ---
    +/
    void information(T)(T message) { writelog(message.to!string, INFORMATION); }

    /++
        Logs a debugging message (priority DEBUGGING).

        Params:
            message = The message to log (converted to string).

        Example:
        ---
        log.debugging("Variable x = 5");  // Logs with DEBUGGING level
        log.d("Entering loop");  // Alias usage
        ---
    +/
    void debugging(T)(T message) { writelog(message.to!string, DEBUGGING); }

    /++ Alias for `alert` +/
    alias a = alert;
    /++ Alias for `critical` +/
    alias c = critical;
    /++ Alias for `error` +/
    alias e = error;
    /++ Alias for `warning` +/
    alias w = warning;
    /++ Alias for `notice` +/
    alias n = notice;
    /++ Alias for `information` +/
    alias i = information;
    /++ Alias for `debugging` +/
    alias d = debugging;

    /++
        Struct for fluent configuration of output targets.

        Provides methods to chain output targets, accumulating them into a bitmask.
    +/
    struct Output {
        private int value = 0;

        /++
            Adds syslog to the output targets.

            Example:
            ---
            log.output(log.output.syslog);  // Enables syslog output
            log.i("Logged to syslog");
            ---
        +/
        Output syslog() { value |= SYSLOG; return this; }

        /++
            Adds standard output (stdout/stderr) to the output targets.

            Example:
            ---
            log.output(log.output.std);  // Enables console output
            log.w("Logged to console");
            ---
        +/
        Output std() { value |= STD; return this; }

        /++
            Adds file output to the output targets.

            Example:
            ---
            log.output(log.output.file);  // Enables file output
            log.i("Logged to file");
            ---
        +/
        Output file() { value |= FILE; return this; }
    }

    /++
        Struct for fluent configuration of log levels.

        Provides methods to specify log levels.
    +/
    struct Level {
        /++ Returns the DEBUGGING level +/
        int debugging() { return DEBUGGING; }
        /++ Returns the ALERT level +/
        int alert() { return ALERT; }
        /++ Returns the CRITICAL level +/
        int critical() { return CRITICAL; }
        /++ Returns the ERROR level +/
        int error() { return ERROR; }
        /++ Returns the WARNING level +/
        int warning() { return WARNING; }
        /++ Returns the NOTICE level +/
        int notice() { return NOTICE; }
        /++ Returns the INFORMATION level +/
        int information() { return INFORMATION; }

        /++ Alias for `debugging` +/
        alias d = debugging;
        /++ Alias for `alert` +/
        alias a = alert;
        /++ Alias for `critical` +/
        alias c = critical;
        /++ Alias for `error` +/
        alias e = error;
        /++ Alias for `warning` +/
        alias w = warning;
        /++ Alias for `notice` +/
        alias n = notice;
        /++ Alias for `information` +/
        alias i = information;

        /++
            Example:
            ---
            log.level(log.level.d);  // Sets level to DEBUGGING
            log.d("Debug message");  // Visible
            ---
        +/
    }

    /++
        Helper method to start level configuration.

        Returns:
            A `Level` struct for chaining level methods.

        Example:
        ---
        log.level(log.level().warning);  // Sets level to WARNING
        log.i("This won't show");  // Ignored due to level
        log.w("This will show");
        ---
    +/
    Level level() { return Level(); }

    /++
        Struct for temporary output override.

        Provides methods to log messages with temporary output settings.
    +/
    struct Now {
        private Log _log;

        this(Log log) { _log = log; }

        /++
            Logs an alert message.

            Example:
            ---
            log.now(log.output.std).alert("Temp alert");  // Only to console
            ---
        +/
        void alert(T)(T message) { _log.alert(message); }

        /++
            Logs a critical error message.

            Example:
            ---
            log.now(log.output.file).c("Temp critical");  // Only to file
            ---
        +/
        void critical(T)(T message) { _log.critical(message); }

        /++
            Logs an error message.

            Example:
            ---
            log.now(log.output.std).e("Temp error");  // Only to stderr
            ---
        +/
        void error(T)(T message) { _log.error(message); }

        /++
            Logs a warning message.

            Example:
            ---
            log.now(log.output.syslog).w("Temp warning");  // Only to syslog
            ---
        +/
        void warning(T)(T message) { _log.warning(message); }

        /++
            Logs a notice message.

            Example:
            ---
            log.now(log.output.std).n("Temp notice");  // Only to stdout
            ---
        +/
        void notice(T)(T message) { _log.notice(message); }

        /++
            Logs an informational message.

            Example:
            ---
            log.now(log.output.file).i("Temp info");  // Only to file
            ---
        +/
        void information(T)(T message) { _log.information(message); }

        /++
            Logs a debugging message.

            Example:
            ---
            log.now(log.output.std).d("Temp debug");  // Only to stdout
            ---
        +/
        void debugging(T)(T message) { _log.debugging(message); }

        /++ Alias for `alert` +/
        alias a = alert;
        /++ Alias for `critical` +/
        alias c = critical;
        /++ Alias for `error` +/
        alias e = error;
        /++ Alias for `warning` +/
        alias w = warning;
        /++ Alias for `notice` +/
        alias n = notice;
        /++ Alias for `information` +/
        alias i = information;
        /++ Alias for `debugging` +/
        alias d = debugging;
    }
}

/++
    Global alias for easy access to the logger instance.

    The `log` alias provides a convenient shortcut to the singleton instance of the `Log` class,
    allowing direct access to all logging functionality without explicitly calling `Log.msg`.
    It supports the same methods, configuration options, and features as the `Log` class.

    Example:
    ---
    import singlog;

    void main() {
        // Configure the logger using the alias
        log.program("MyApp")
           .color(true)
           .level(log.level.debugging)  // Using log.level directly
           .output(log.output.std.file.syslog)
           .file("myapp.log");

        // Log messages with full method names
        log.debugging("App starting in debug mode");
        log.information("Initialization complete");
        log.error("Failed to load resource");

        // Log messages with aliases
        log.d("Debug message via alias");
        log.i("Info message via alias");
        log.e("Error message via alias");

        // Temporary output override
        log.now(log.output.std).n("Temporary console-only message");
    }
    ---
+/
alias log = Log.msg;
