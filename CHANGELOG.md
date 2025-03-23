# Changelog

## [1.0.0] - 2025-03-23

### Added
- **Thread-safety**: Added a `Mutex` to ensure thread-safe logging operations across all methods (`_mutex` in `Log` class).
- **Destructor**: Implemented `~this()` to properly close the log file when the `Log` instance is destroyed.
- **File handle management**: Introduced `_file` (File handle) and `_fileOpen` (flag) for better file management, reducing repeated file opening/closing.
- **Enhanced documentation**: Added detailed DDoc comments for the module, `Log` class, and all public/private methods, including examples.
- **Immutable arrays**: Made `_sysPriority`, `_sysPriorityOS`, `_color` (Windows), `_colorCodes` (both platforms), and `_type` arrays immutable for better safety and performance.
- **Singleton initialization**: Improved singleton pattern with double-checked locking in `@property static Log msg()` for thread-safe initialization.
- **Fluent interface naming**: Renamed output-related enums (`SYSLOG`, `STD`, `FILE`) and methods (`std`, `syslog`, `file`) for consistency and clarity (e.g., `STDOUT` → `STD`).
- **Error handling**: Enhanced error reporting in `writefile` by logging exception messages instead of the full exception object.

### Changed
- **Output handling**:
  - Removed separate `writestdout` and `writestderr` methods; consolidated into a single `writestd` method that dynamically selects `stdout` or `stderr` based on log level (`ERROR` and above go to `stderr`, others to `stdout`).
  - Adjusted output enum values: `SYSLOG = 1`, `STD = 2`, `FILE = 8` (removed `STDERR = 4` as it's now handled by `STD`).
- **Windows-specific**:
  - Renamed `_color` to `_colorCodes` for consistency with POSIX.
  - Updated `writesyslog` to use `toUTF16z()` for `_name` and added null checks.
- **POSIX-specific**:
  - Renamed `_color` to `_colorCodes` and simplified console output logic in `writestd`.
  - Changed `writesyslog` to pass priority directly instead of mapping it.
- **Log level filtering**: Moved priority check (`_priority > priority`) into `writelog` under the mutex for consistency.
- **File logging**:
  - Simplified `writefile` by maintaining an open `File` handle (`_file`) instead of opening/closing on each write.
  - Removed redundant file existence check (`this._path.exists`) as `File` opening handles it implicitly.
- **Configuration methods**: Made all setters (`program`, `file`, `level`, `color`, `output`) thread-safe with `synchronized (_mutex)`.
- **Naming consistency**:
  - Renamed `Output.output()` to internal use; public access is via `Output` struct methods.

### Removed
- **Deprecated method**: Removed the deprecated `Log output(int outs)` method; users must now use the fluent `Output` struct.
- **Redundant output flags**: Removed `STDERR` from output enum as it's now handled dynamically by `STD`.
- **Unnecessary struct fields**: Removed `_output` and `_newoutput` from `Output` struct; replaced with a single `value` field.
- **Redundant methods**: Removed separate `writestdout` and `writestderr` in favor of `writestd`.

### Fixed
- **Windows console output**: Added error checking in `colorTextOutput` and `defaultTextOutput` with `GetConsoleScreenBufferInfo`.
- **File closing**: Ensured proper file closure in `file` method when changing the log file path.

### Breaking Changes
- **Output enum changes**: 
  - `STDOUT` renamed to `STD`, `STDERR` removed; code relying on `STDERR = 4` will need adjustment.
  - Users must update output configuration to use `STD` instead of separate `STDOUT`/`STDERR`.
- **Method removal**: Code using the deprecated `Log output(int outs)` must switch to `Log.output(Output)`.
- **Console output behavior**: Messages with priority `ERROR` and above now go to `stderr` by default when `STD` is enabled, which may change existing output redirection logic.

## [0.5.0] - 2023-07-21

### New

- Added the ability to output messages to the standard error stream. Now messages above the `WARNING` level will not be output to the `stdout`. To output them, need to use `stderr`
- Write message to specific outputs via `log.now`
- Now `log.output` allows to set the output as an argument
- Now `log.level` allows to set the level as an argument

### Bug fixes

- Fixed streams redirection in Windows

## [0.4.0] - 2023-06-07

- Part of the code has been changed/rewritten

### New

- Color output of messages to the terminal and console

### Bug fixes

- In Windows, unicode messages are output without distortion to the system log and console (thanks [Adam D. Ruppe](https://arsdnet.net/))

## [0.3.2] - 2023-06-01

- Printing information about the type of the logged message to the standard output stream and file
- Printing the date and time to the standard output stream

## [0.3.1] - 2023-05-30

### Bug fixes

- Log of debug messages

## [0.3.0] - 2023-04-28

- Minor changes

### New

- Windows OS Logging support

## [0.2.1] - 2023-03-29

### New

- Added aliases for the short form of function calls

### Bug fixes

- Calling the main object

## [0.2.0] - 2023-03-29

- Removed functions `fileOn()` and `fileOff()`

### New

- Simultaneous writing to the standard stream, syslog and file by binary setting the output flag

## [0.1.0] - 2023-03-23

### The first stable working release

- Output to the standard stream or syslog
- Enable an entry in the file
