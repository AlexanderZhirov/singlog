module singlog;

import core.sys.posix.syslog;
import std.stdio;
import std.conv;
import std.meta;
import std.file;
import std.datetime;
import datefmt;

/++
    Singleton for simple logging

    ---
    // Setting the error output level
    Log.msg.level(Log.DEBUG);
    Log.msg.level(Log.ALERT);
    Log.msg.level(Log.CRIT);
    Log.msg.level(Log.ERR);
    Log.msg.level(Log.WARNING);
    Log.msg.level(Log.NOTICE);
    Log.msg.level(Log.INFO);
    // Assigning a target output
    Log.msg.output(Log.SYSLOG);
    Log.msg.output(Log.STDOUT);
    // Setup and allowing writing to a file
    Log.msg.file("./file.log");
    Log.msg.fileOn();
    Log.msg.fileOff();
    // Output of messages to the log
    Log.msg.alert("Alert message");
    Log.msg.critical("Critical message");
    Log.msg.error("Error message");
    Log.msg.warning("Warning message");
    Log.msg.notice("Notice message");
    Log.msg.informations("Information message");
    Log.msg.debugging("Debugging message");
    ---
+/
class Log
{
    private static Log log;
    private string path;
    private bool writeToFile = false;
    private bool fileExist = true;
    private static SysTime time;

    // Target output
    enum {SYSLOG, STDOUT}

    // Message output level
    enum {
        DEBUG   = 0,
        CRIT    = 1,
        ERR     = 2,
        WARNING = 3,
        NOTICE  = 4,
        INFO    = 5,
        ALERT   = 6
    }
    
    int msgOutput = STDOUT;
    int msgLevel = INFO;

    private this() {}

    private void writeLog(string message, int msgLevel, int priority)
    {
        if (this.msgLevel > msgLevel)
            return;
        if (this.msgOutput == STDOUT)
            writeln(message);
        else if (this.msgOutput == SYSLOG)
            syslog(priority, (message ~ "\0").ptr);
        writeFile(message);
    }

    private void writeFile(string message)
    {
        if (!this.writeToFile || !this.fileExist)
            return;

        if (this.path.exists)
            this.fileExist = true;
        else
        {
            this.fileExist = false;
            this.warning("The log file does not exist: " ~ this.path);
            this.fileExist = true;
        }

        File file;

        try {
            file = File(this.path, "a+");
        } catch (Exception e) {
            this.fileOff();
            this.error("Unable to open the log file " ~ this.path);
            this.critical(e);
            return;
        }

        try {            
            file.writeln(this.time.format("%Y.%m.%d %H:%M:%S: ") ~ message);
        } catch (Exception e) {
            this.fileOff();
            this.error("Unable to write to the log file " ~ this.path);
            this.critical(e);
            return;
        }

        try {
            file.close();
        } catch (Exception e) {
            this.fileOff();
            this.error("Unable to close the log file " ~ this.path);
            this.critical(e);
            return;
        }
    }
    
    @property static Log msg()
    {
        if (this.log is null)
        {
            this.log = new Log;
            this.time = Clock.currTime();
        }

        return this.log;
    }

    void output(int msgOutput) { this.msgOutput = msgOutput; }
    void level(int msgLevel) { this.msgLevel = msgLevel; }
    void file(string path) { this.path = path; }

    void fileOn() { this.writeToFile = true; }
    void fileOff() { this.writeToFile = false; }

    void alert(T)(T message) { writeLog(message.to!string, ALERT, LOG_ALERT); }
    void critical(T)(T message) { writeLog(message.to!string, CRIT, LOG_CRIT); }
    void error(T)(T message) { writeLog(message.to!string, ERR, LOG_ERR); }
    void warning(T)(T message) { writeLog(message.to!string, WARNING, LOG_WARNING); }
    void notice(T)(T message) { writeLog(message.to!string, NOTICE, LOG_NOTICE); }
    void information(T)(T message) { writeLog(message.to!string, INFO, LOG_INFO); }
    void debugging(T)(T message) {writeLog(message.to!string, DEBUG, LOG_DEBUG); }
}
