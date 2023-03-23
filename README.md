# singlog

Singleton for simple logging

## Basic Usage

```d
import simplog;

void main()
{
    Log.msg.level(Log.DEBUG);
    Log.msg.output(Log.SYSLOG);
    Log.msg.file("./file.log");
    Log.msg.warning("Hello, World!");
}
```

## Examples

Setting the error output level:

```d
Log.msg.level(Log.DEBUG);
Log.msg.level(Log.ALERT);
Log.msg.level(Log.CRIT);
Log.msg.level(Log.ERR);
Log.msg.level(Log.WARNING);
Log.msg.level(Log.NOTICE);
Log.msg.level(Log.INFO);
```

Assigning a target output:

```d
Log.msg.output(Log.SYSLOG);
Log.msg.output(Log.STDOUT);
```

Setup and allowing writing to a file:

```d
Log.msg.file("./file.log");
Log.msg.fileOn();
Log.msg.fileOff();
```

Output of messages to the log:

```d
Log.msg.alert("Alert message");
Log.msg.critical("Critical message");
Log.msg.error("Error message");
Log.msg.warning("Warning message");
Log.msg.notice("Notice message");
Log.msg.informations("Information message");
Log.msg.debugging("Debugging message");
```

## Dub

Add a dependency on `"singlog": "~>0.1.0"`.
