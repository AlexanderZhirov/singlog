module singlog;

import core.sys.posix.syslog;
import std.stdio;
import std.conv;
import std.meta;
import std.file;
import std.datetime;
import datefmt;

alias log = log;

/++
    Singleton for simple logging

    ---
    // Setting the error output level
    log.level(log.DEBUG);
    log.level(log.ALERT);
    log.level(log.CRIT);
    log.level(log.ERR);
    log.level(log.WARNING);
    log.level(log.NOTICE);
    log.level(log.INFO);
    // Assigning a target output
    log.output(log.SYSLOG);
    log.output(log.STDOUT);
    log.output(log.FILE);
    // Setup and allowing writing to a file
    log.file("./file.log");
    log.fileOn();
    log.fileOff();
    // Output of messages to the log
    log.alert("Alert message");
    log.critical("Critical message");
    log.error("Error message");
    log.warning("Warning message");
    log.notice("Notice message");
    log.informations("Information message");
    log.debugging("Debugging message");
    ---
+/
class Log
{
    private static Log log;
    private string path;
    private bool writeToFile = true;
    private static SysTime time;

    // Target output
    enum {
        SYSLOG = 1,
        STDOUT = 2,
        FILE = 4
    }

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
        if (this.msgOutput & 1)
            syslog(priority, (message ~ "\0").ptr);
        if (this.msgOutput & 2)
            writeln(message);
        if (this.msgOutput & 4)
            writeFile(message);
    }

    private void writeFile(string message)
    {
        if (!this.writeToFile)
            return;

        if (this.path.exists)
            this.writeToFile = true;
        else
        {
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
            this.critical(e);
            return;
        }

        try {            
            file.writeln(this.time.format("%Y.%m.%d %H:%M:%S: ") ~ message);
        } catch (Exception e) {
            this.writeToFile = false;
            this.error("Unable to write to the log file " ~ this.path);
            this.critical(e);
            return;
        }

        try {
            file.close();
        } catch (Exception e) {
            this.writeToFile = false;
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

    void alert(T)(T message) { writeLog(message.to!string, ALERT, LOG_ALERT); }
    void critical(T)(T message) { writeLog(message.to!string, CRIT, LOG_CRIT); }
    void error(T)(T message) { writeLog(message.to!string, ERR, LOG_ERR); }
    void warning(T)(T message) { writeLog(message.to!string, WARNING, LOG_WARNING); }
    void notice(T)(T message) { writeLog(message.to!string, NOTICE, LOG_NOTICE); }
    void information(T)(T message) { writeLog(message.to!string, INFO, LOG_INFO); }
    void debugging(T)(T message) {writeLog(message.to!string, DEBUG, LOG_DEBUG); }
}
