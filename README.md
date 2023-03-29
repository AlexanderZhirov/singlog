# singlog

[![license](https://img.shields.io/github/license/AlexanderZhirov/singlog.svg?sort=semver&style=for-the-badge&color=green)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html)
[![main](https://img.shields.io/badge/dynamic/json.svg?label=git.zhirov.kz&style=for-the-badge&url=https://git.zhirov.kz/api/v1/repos/dlang/singlog/tags&query=$[0].name&color=violet)](https://git.zhirov.kz/dlang/singlog)
[![githab](https://img.shields.io/github/v/tag/AlexanderZhirov/singlog.svg?sort=semver&style=for-the-badge&color=blue&label=github)](https://github.com/AlexanderZhirov/singlog)
[![dub](https://img.shields.io/dub/v/singlog.svg?sort=semver&style=for-the-badge&color=orange)](https://code.dlang.org/packages/singlog)

Singleton for simple logging

## Basic Usage

```d
import singlog;

void main()
{
    log.level(log.DEBUG);
    // write to syslog and file
    log.output(log.SYSLOG | log.FILE);
    log.file("./file.log");
    log.warning("Hello, World!");
    log.w("The same thing");
}
```

## Examples

Setting the error output level:

```d
log.level(log.DEBUG);
log.level(log.ALERT);
log.level(log.CRIT);
log.level(log.ERR);
log.level(log.WARNING);
log.level(log.NOTICE);
log.level(log.INFO);
```

Assigning a target output:

```d
log.output(log.SYSLOG);
log.output(log.STDOUT);

```

Setup and allowing writing to a file:

```d
log.output(log.FILE);
log.file("./file.log");
```

Output of messages to the log:

```d
log.a("Alert message")          =>    log.alert("Alert message");
log.c("Critical message")       =>    log.critical("Critical message");
log.e("Error message")          =>    log.error("Error message");
log.w("Warning message")        =>    log.warning("Warning message");
log.n("Notice message")         =>    log.notice("Notice message");
log.i("Information message")    =>    log.information("Information message");
log.d("Debugging message")      =>    log.debugging("Debugging message");
```

## Dub

Add a dependency on `"singlog": "~>0.2.1"`.
