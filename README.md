![singlog](singlog.png)

[![license](https://img.shields.io/github/license/AlexanderZhirov/singlog.svg?sort=semver&style=for-the-badge&color=green)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html)
[![main](https://img.shields.io/badge/dynamic/json.svg?label=git.zhirov.kz&style=for-the-badge&url=https://git.zhirov.kz/api/v1/repos/dlang/singlog/tags&query=$[0].name&color=violet)](https://git.zhirov.kz/dlang/singlog)
[![githab](https://img.shields.io/github/v/tag/AlexanderZhirov/singlog.svg?sort=semver&style=for-the-badge&color=blue&label=github)](https://github.com/AlexanderZhirov/singlog)
[![dub](https://img.shields.io/dub/v/singlog.svg?sort=semver&style=for-the-badge&color=orange)](https://code.dlang.org/packages/singlog)
[![linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://www.linux.org/)
[![windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://support.microsoft.com/en-US/windows)

Singleton for simple logging

## Basic Usage

```d
import singlog;

void main(string[] argv) {
    log.output(log.SYSLOG | log.STDOUT | log.FILE)  // write to syslog, standard output stream and file
        .name(argv[0])                              // program name as an identifier (for Windows OS)
        .level(log.DEBUGGING)                       // logging level
        .file("./test.log");                        // the path to the log file

    log.e("This is an error message");
    log.error("And this is also an error message");
    log.w("This is a warning message");
    log.i("This is an information message");
}
```

## Examples

Setting the name of the logged program (it matters for Windows OS):

```d
log.name("My program");
```

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

## DUB

Add a dependency on `"singlog": "~>0.3.0"`.
