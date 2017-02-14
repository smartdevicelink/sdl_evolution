# Redesign iOS Logging

* Proposal: [SDL-NNNN](nnnn-ios-logging-redesign.md)
* Author: [Joel Fischer](https://github.com/joeljfischer), [Alex Muller](https://github.com/asm09fsu)
* Status: **Awaiting review**
* Impacted Platforms: iOS

## Introduction
This proposal is a full redesign of the internal logging framework used by SDL, `SDLDebugTool`. The goal is to provide flexible and fast logging for internal and related developer usage.

## Motivation
The current system was written quite a long time ago and is not particularly fast, nor flexible. It provides some basic file logging and console logging, but does not provide a developer many options to log related logs or to customize and filter the output as desired. We need a better logging framework in order to add more logs than currently exist, make sure they're fast, and provide developers with the tools and flexibility to debug their code.

## Proposed solution
The proposed solution is to provide a few additional features:

* Most logs (see "Detailed solution") disabled when the app is created in `RELEASE` mode instead of `DEBUG`.
* Provide multiple levels of logging, such as `Verbose` (see below, "Detailed solution" for a full list).
* Better log formatting with simple and detailed logs, providing features such as which queue, file, method, and module the log was sent on.
* Async by default logging, with error logs being synchronous by default.
* Filters allow only logs that pass a check to be logged.

This proposal is a major version change because it would remove two classes: `SDLDebugTool` is the currently logging class, however, removing this class should have a minimal impact. Second, this change would remove `SDLConsoleController`, which has remained stagnant for many years. An extensible logging solution would allow others to create something similar to this if desired.

Finally, this proposal would also encompass using this new framework to enhance logging throughout the library using the new log levels and modules in addition to adding log messages throughout the SDL library.

## Detailed solution
Much of this is adapted from a logging library I wrote, [SuperLogger](https://github.com/livio/SuperLogger), which has been open-sourced by Livio.

This proposal would split the logging tool into several classes instead of the current one class. Each destination for a log, e.g. file or console, will be a separate class. An instance of each class that is actively receiving logs will be held by the central logger controller.

### Logging Controller
The `SDLLogManager` is a public class that will largely be managed internally but will be the primary place developers would place filters, create modules, set logging level, etc., to customize SDL logging. The `SDLLogManager` will be initialized with a configuration (see below "Configuration"). The `SDLLogManager` will not be managed explicitly by the `SDLLifecycleManager` though it will be started by it. Due to its need to be called globally and for macros to call into it, the `SDLLogManager` will be a singleton object. In `SDLLifecycleManager`'s initialization, it will pass the configuration into the `SDLLogManager`; this means that `SDLLogManager` cannot be used before this point. Since this should be done in the app's `AppDelegate`, this should be very early in the process. This configuration cannot be reset at runtime once it has been set, it will throw an exception if this happens.

The public interface will look something like this:

```objc
@interface SDLLogManager : NSObject

@property (copy, nonatomic, readonly) NSSet<SDLLogFileModule *> *logModules;
@property (assign, nonatomic, readonly) NSSet<id<SDLLogTarget>> *logTargets;
@property (copy, nonatomic, readonly) NSSet<SDLLogFilterBlock> *logFilters;

@property (assign, nonatomic, readonly, getter=isAsynchronous) BOOL asynchronous;
@property (assign, nonatomic, readonly, getter=areErrorsAsynchronous) BOOL errorsAsynchronous;

// Any modules that do not have an explicitly specified level will by default use the global log level;
@property (assign, nonatomic) SDLLogLevel globalLogLevel;

+ (SDLLogManager *)sharedManager;

#pragma mark - Singleton methods
/*
 * These are automatically called on the `sharedManager`.
 */
+ (void)startWithConfiguration:(SDLLogConfiguration *)configuration;

// This would be used internally to send out a log to the loggers
+ (void)logWithLevel:(SDLLogLevel)level
            fileName:(NSString *)fileName
        functionName:(NSString *)functionName
                line:(NSInteger)line
        formatMessage:(NSString *)message, ... NS_FORMAT_FUNCTION(5, 6);

// This would be used internally for the Swift extension to send out a fully formed message
+ (void)logWithLevel:(SDLLogLevel)level
            fileName:(NSString *)fileName
        functionName:(NSString *)functionName
                line:(NSInteger)line
            message:(NSString *)message;

@end
```

#### Swift Support
To support Swift developers well, we will need to support an additional framework, `SDLLoggerSwift` that Swift developers may import (or copy into their project, as it is a single file). This is necessary because for the code to work well in Swift, it will need to be written in Swift. If it is not written in Swift, we will not be able to automatically pull file / function / line information as we can when Obj-C developers use the macros. The Swift file would look like this:

```swift

open class SDLLoggerSwift {
    // Verbose
    open class func v(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        SDLLogManager.log(with: .verbose, fileName: file, functionName: function, line: line, message: "\(message())")
    }

    // Debug
    open class func d(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        SDLLogManager.log(with: .debug, fileName: file, functionName: function, line: line, message: "\(message())")
    }

    // Warning
    open class func w(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        SDLLogManager.log(with: .warning, fileName: file, functionName: function, line: line, message: "\(message())")
    }

    // Error
    open class func e(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        SDLLogManager.log(with: .error, fileName: file, functionName: function, line: line, message: "\(message())")
    }
}
```

It would then be used by the Swift developer like so:

```swift
let log = SDLLogSwift.self
log.e("Test something \(NSDate())")
```

### Configuration
The logging system will have an initial configuration of modules and format set by an immutable object `SDLLogConfiguration`, which will be passed to the `SDLConfiguration` upon setting up the `SDLManager`. `SDLConfiguration` will add a new initializer that may take a `SDLLogConfiguration`; older initializers will set up the default log configuration.

The following will be set up into the configuration ahead of time:
```objc
typedef NS_ENUM(NSUInteger, SDLLogFormatType) {
    SDLLogFormatTypeSimple,
    SDLLogFormatTypeDefault,
    SDLLogFormatTypeDetailed,
};

// Any custom logging modules used by the developer's code. Defaults to none.
@property (copy, nonatomic) NSSet<SDLLogFileModule *> *logModules;

// Where the logs will attempt to output. Defaults to Console.
@property (assign, nonatomic) NSSet<id<SDLLogTarget>> *logTargets;

// What log filters will run over this session. Defaults to none.
@property (copy, nonatomic) NSSet<SDLLogFilterBlock> *logFilters;

// How detailed of logs will be output. Defaults to Default.
@property (assign, nonatomic) SDLLogFormatType formatType;

// Whether or not logs will be run on a separate queue, asynchronously, allowing the following code to run before the log completes. Or if it will occur synchronously, which will prevent logs from being missed, but will slow down surrounding code. Defaults to YES.
@property (assign, nonatomic, getter=isAsynchronous) BOOL asynchronous;

// Whether or not error logs will be dispatched to loggers asynchronously. Defaults to NO.
@property (assign, nonatomic, getter=areErrorsAsynchronous) BOOL errorsAsynchronous;

 // Any modules that do not have an explicitly specified level will by default use the global log level. Defaults to Error.
@property (assign, nonatomic) SDLLogLevel globalLogLevel;
```

### Formatting
We will provide a few format types:

**Simple**
```objc
[NSString stringWithFormat:@"%@ %@ (SDL)%@ – %@\n", dateString, logCharacter, moduleName, message];
09:52:07:324 🔹 (SDL)Protocol – a random test i guess
```

**Default**
```objc
[NSString stringWithFormat:@"%@ %@ (SDL)%@:%@:%@ – %@\n", dateString, logCharacter, moduleName, fileName, (long)line, message];
09:52:07:324 🔹 (SDL)Protocol:SDLV2ProtocolHeader:25 – Some log message
```

**Detailed**
```objc
[NSString stringWithFormat:@"%@ %@ %@ %@:(SDL)%@:%@:%@ – %@\n", dateString, logCharacter, logLevelString, queueLabel, moduleName, functionName, (long)line, message];
09:52:07:324 🔹 DEBUG com.apple.main-thread:(SDL)Protocol:[SDLV2ProtocolHeader parse:]:74 – Some log message
```

#### Macros
Macros are a way to make it easy to call the logging API while allowing the system to capture almost all of the information for you. Additionally, they are the way of compiling out debug level logs and below in RELEASE mode.

Developers using Objective-C (macros are Obj-C only) will be able to call logs pertaining to their SDL integration and have them tie in with the rest of the SDL logging.

There will be separate macros for each logging level, similar to "Swift Support" above.

```objc
SDLLogV(@"Test verbose");
SDLLogD(@"Test debug");
SDLLogW(@"Test warning");
SDLLogE(@"Test error");
```

### Logs
An `SDLLogModel` object will contain all of the information necessary to format and log a string. This will be a private class. It will contain something like the following properties:

```objc
@interface SDLLogModel : NSObject <NSCopying>

@property (copy, nonatomic, readonly) NSString *message;
@property (copy, nonatomic, readonly) NSDate *timestamp;
@property (assign, nonatomic, readonly) SDLLogLevel level;
@property (copy, nonatomic, readonly) NSString *queueLabel;
@property (copy, nonatomic, readonly) NSString *moduleName;
@property (copy, nonatomic, readonly) NSString *fileName;
@property (copy, nonatomic, readonly) NSString *functionName;
@property (assign, nonatomic, readonly) NSInteger line;

- (void)initWith...
```

#### Log Levels
There are six log levels in order from least important to most important. Setting the system to level "Debug" would output Debug and *above* logs, i.e., Warning, and Error.
* Verbose - A log that is not considered important and is more likely to be noise than helpful.
* Debug - A log that may be important in debugging situations.
* Warning - A RELEASE level log that outputs a non-fatal error.
* Error - A RELEASE level log that outputs a fatal error.

### Logging Targets
We would provide three logging targets (below) that may be enabled by the developer. There will be a protocol `SDLLogTarget` that each default logging target will conform to; if the developer wishes to create more logging targets, they may do that themselves as well and simply add them into the configuration. The protocol would look like this:

```objc
@protocol SDLLogTarget <NSObject>
@required

+ (id<SDLLogTarget>)logger;
- (BOOL)setupLogger;
- (void)logWithLog:(SDLLogModel *)log formattedLog:(NSString *)stringLog;
- (void)teardownLogger;

@end
```

#### Console Logging
Console logging (pre-iOS 10) is done through the Syslog APIs, using the `write` function. This will simply take the formatted string and log it.

#### OS Logging
`os_log` is an iOS 10+ logging addition that provides several features that would be very helpful for developers such as native filtering and channel support. Because this is iOS 10+ only, if this is activated by the developer on a pre-iOS 10 device, an error message will print and this logging output will be disabled.

We will use [os_log_create](https://developer.apple.com/reference/kernel/1643798-os_log_create?language=objc) to create a channel/subsystem for SDL specific logging, using categories to align with modules (below) for better filtering.

The various levels of logging would correspond with various logging levels (above "Log Types"), probably like this:

* Verbose - os_log_debug
* Debug - os_log_info
* Warning - os_log
* Error - os_log_error

#### File Logging
File logging is currently done with a single file that is overwritten when a new `SDLManager` is initialized. The new system would keep a rolling log of three files in a directory with files sorted by file name – the current timestamp.

### Filtering
`SDLLogFilter` will be a public class allowing developers to filter logs to only allow specific ones. This will be useful for debugging. Filtering allows the developer to have logs pass a check before they are able to be logged. This would be by allowing / disallowing logs that have a message containing a string or passing a regex check, or allowing / disallowing certain modules, files, or queues. It may look something like this:

```objc
@interface SDLLogFilter : NSObject

+ (SDLLogFilterBlock)filterByDisallowingString:(NSString *)string caseInsensitive:(BOOL)caseInsensitive;
+ (SDLLogFilterBlock)filterByAllowingString:(NSString *)string caseInsensitive:(BOOL)caseInsensitive;
+ (SDLLogFilterBlock)filterByDisallowingRegex:(NSRegularExpression *)regex;
+ (SDLLogFilterBlock)filterByAllowingRegex:(NSRegularExpression *)regex;
+ (SDLLogFilterBlock)filterByAllowingModules:(NSSet<SDLLogFileModule *> *)modules;
+ (SDLLogFilterBlock)filterByDisallowingModules:(NSSet<SDLLogFileModule *> *)modules;
+ (SDLLogFilterBlock)filterByAllowingFileNames:(NSSet<NSString *> *)fileNames;
+ (SDLLogFilterBlock)filterByDisallowingFileNames:(NSSet<NSString *> *)fileNames;
+ (SDLLogFilterBlock)filterByAllowingQueues:(NSSet<NSString *> *)queueNames;
+ (SDLLogFilterBlock)filterByDisallowingQueues:(NSSet<NSString *> *)queueNames;

@end
```

An `SDLLogFilterBlock` takes a log in and returns whether or not the log passes, a `YES` result will log the message:

```objc
typedef BOOL (^SDLLogFilterBlock)(SDLLogModel *log);
```

### Modules
`SDLLogFileModule` is a public class allowing developers to tie their own SDL files into modules if desired. All SDL classes will do this by default to enable easier debugging. Modules are groups of files defined ahead of time. A module may have a different logging level than the rest of the system. For example, if the developer wishes to output detailed logs for the file manager, they could specify that the File module use Verbose logging while the rest of SDL and their own code uses a global level of Release. Developers should be able to inspect SDL modules on `SDLLogManager` and alter log levels for internal modules.

```objc
@interface SDLLogFileModule : NSObject

@property (copy, nonatomic, readonly) NSString *name;
@property (copy, nonatomic, readonly) NSSet<NSString *> *files;
@property (assign, nonatomic) SDLLogLevel logLevel;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithName:(NSString *)name files:(NSSet<NSString *> *)files level:(SDLLogLevel)level NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithName:(NSString *)name files:(NSSet<NSString *> *)files;
- (BOOL)containsFile:(NSString *)fileName;

@end
```

## Potential downsides
There are a few potential downsides.

1. Adding logs slows down the library? This is largely mitigated in a few ways. First, by compiling out most logs in RELEASE mode, the library will only attempt to log Warning and Error logs for apps in the app store. Second, if developers disable all logging, even release mode logs will only do a quick check and then return. Third, most logs are done asynchronously on a serial dispatch queue and will use a dormant CPU core if available, the current logger does none of this.

2. Complicated? This proposal has significantly more parts than the existing logging solution. However, it is not especially complicated and will be rather extensible, allowing us to add additional logger outputs with relative ease. Due to its spread out class structure we can privatize significant portions of the library and leaving only the API surface necessary for developers to interact with as public.

## Impact on existing code
Removing `SDLDebugTool` and `SDLConsoleController` would cause a major version change. Adding additional logs throughout the entire SDL library may slow the library down slightly to perform those logs; however, since the logs would mostly be Debug and below level logs, those logs will be compiled out of RELEASE mode. The remaining logs (primarily errors) can be turned off by the developer, causing a minimal performance hit. This is very likely to be more performant than current logging in any case.

## Alternatives considered
The major alternative would be to use a third party library to provide similar functionality without having to develop it ourselves. However, that would cause us to have a 3rd party dependency, which may not be desirable.
