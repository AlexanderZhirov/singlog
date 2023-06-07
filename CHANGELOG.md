# Changelog

## [v0.4.0](https://git.zhirov.kz/dlang/singlog/compare/v0.3.2...v0.4.0) (2023.06.07)

- Part of the code has been changed/rewritten

### New

- Color output of messages to the terminal and console

### Bug fixes

- In Windows, unicode messages are output without distortion to the system log and console (thanks [Adam D. Ruppe](https://arsdnet.net/))

## [v0.3.2](https://git.zhirov.kz/dlang/singlog/compare/v0.3.1...v0.3.2) (2023.06.01)

- Printing information about the type of the logged message to the standard output stream and file
- Printing the date and time to the standard output stream

## [v0.3.1](https://git.zhirov.kz/dlang/singlog/compare/v0.3.0...v0.3.1) (2023.05.30)

### Bug fixes

- Log of debug messages

## [v0.3.0](https://git.zhirov.kz/dlang/singlog/compare/v0.2.1...v0.3.0) (2023.04.28)

- Minor changes

### New

- Windows OS Logging support

## [v0.2.1](https://git.zhirov.kz/dlang/singlog/compare/v0.2.0...v0.2.1) (2023.03.29)

### New

- Added aliases for the short form of function calls

### Bug fixes

- Calling the main object

## [v0.2.0](https://git.zhirov.kz/dlang/singlog/compare/v0.1.0...v0.2.0) (2023.03.29)

- Removed functions `fileOn()` and `fileOff()`

### New

- Simultaneous writing to the standard stream, syslog and file by binary setting the output flag

## [v0.1.0](https://git.zhirov.kz/dlang/singlog/commits/df602a8d0083249068b480e4a92cf7932f2c582b) (2023.03.23)

### The first stable working release

- Output to the standard stream or syslog
- Enable an entry in the file
