![singlog](singlog.png)

[![license](https://img.shields.io/github/license/AlexanderZhirov/singlog.svg?sort=semver&style=for-the-badge&color=green)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html)
[![main](https://img.shields.io/badge/dynamic/json.svg?label=git.zhirov.kz&style=for-the-badge&url=https://git.zhirov.kz/api/v1/repos/dlang/singlog/tags&query=$[0].name&color=violet&logo=D)](https://git.zhirov.kz/dlang/singlog)
[![githab](https://img.shields.io/github/v/tag/AlexanderZhirov/singlog.svg?sort=semver&style=for-the-badge&color=blue&label=github&logo=D)](https://github.com/AlexanderZhirov/singlog)
[![dub](https://img.shields.io/dub/v/singlog.svg?sort=semver&style=for-the-badge&color=orange&logo=D)](https://code.dlang.org/packages/singlog)
[![linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://www.linux.org/)
[![windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://support.microsoft.com/en-US/windows)

Singleton for simple logging

## Basic Usage

```d
import singlog;

void main(string[] argv) {
    log.output(log.output.syslog.stderr.stdout.file)    // write to syslog, standard error/output streams and file
        .program(argv[0])                               // program name as an identifier (for Windows OS)
        .level(log.level.debugging)                     // logging level
        .color(true)                                    // color text output
        .file("./test.log");                            // the path to the log file

    log.i("This is an information message");
    log.n("This is a notice message");
    log.w("This is a warning message");
    log.e("This is an error message");
    log.c("This is a critical message");
    log.a("This is an alert message");
    log.d("This is a debug message");

    log.now(log.output.stdout).n("This error message will only be written to the standard output stream");
    log.now(log.output.syslog.file).c("This error message will only be written to the syslog and file");
}
```

![output](tests/terminal.png)

![output](tests/cmd.png)

## Examples

Setting the name of the logged program (it matters for Windows OS):

```d
log.program("My program");
```

Setting the status of color text output (`false` by default):

```d
log.color(true);
```

Setting the error output level:

```d
log.level(log.level.debugging);
log.level(log.level.alert);
log.level(log.level.critical);
log.level(log.level.error);
log.level(log.level.warning);
log.level(log.level.notice);
log.level(log.level.information);
```

Assigning a target output:

```d
log.output(log.output.syslog.stderr.stdout);
```

Setup and allowing writing to a file:

```d
log.output(log.output.file);
log.file("./file.log");
```

Write messages to the log:

```d
log.a("Alert message")          =>    log.alert("Alert message");
log.c("Critical message")       =>    log.critical("Critical message");
log.e("Error message")          =>    log.error("Error message");
log.w("Warning message")        =>    log.warning("Warning message");
log.n("Notice message")         =>    log.notice("Notice message");
log.i("Information message")    =>    log.information("Information message");
log.d("Debugging message")      =>    log.debugging("Debugging message");
```

Write message to specific outputs:

```d
log.now(log.output.stdout).n("This error message will only be written to the standard output stream");
log.now(log.output.syslog.file).c("This error message will only be written to the syslog and file");
```

## DUB

Add a dependency on `"singlog": "~>0.5.0"`.
