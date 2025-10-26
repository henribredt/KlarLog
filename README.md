# KlarLog

![Swift 6](https://img.shields.io/badge/Swift-6-orange?logo=swift) ![iOS](https://img.shields.io/badge/iOS-16.0+-green) [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A lightweight, type-safe logging framework for Swift with powerful destination-based routing.

## Features
- **Multiple Destinations** - Route logs to console, files, and custom destinations
- **File Logging** - Built-in `LocalFileDestination` with automatic size management
- **OSLog Integration** - Built-in `ConsoleDestination` uses `OSLog` for Xcodes Debug Console and Console.app integration with SwiftUI Preview support
- **Type-Safe Category Loggers** - Access loggers from a compile-time checked registry
- **Dynamic Member Lookup** - Clean dot-notation syntax for accessing loggers and log destinations
- **Modern Concurrency** - Built with Swift Concurrency for Swift 6

## Installation

Add KlarLog via Swift Package Manager in Xcode: **File → Add Package Dependencies**
```
https://github.com/henribredt/KlarLog.git
```

## Quick Start
Configure KlarLog on app launch. Provide configured `CategoryLoggers`and `LogDestinations` as structs.

To make your instance globally available, add a new file `KlarLogConfig.swift` to your project and add [Step 1](Destination), [Setp 2](Define-Your-LoggerDestinations) and [Step 3](Create-Your-Logger) to that file. Then use it to log thoughout your project as shown in [Setp 4](Start-Logging).

#### 1. Define your CategoryLoggers
```swift
struct CategoryLoggers: Sendable {
    // Add your `CategoryLogger`s
    public let network = CategoryLogger(category: "network")
    public let database = CategoryLogger(category: "database")
}
```
> [!TIP]
> The `CategoryLogger` instances organize your logs by domain or feature, making it easier to filter and search through logs. If you don't want to use different categories simply create one general `CategoryLogger`.

#### 2. Define Your LoggerDestinations
```swift
struct LogDestinations: Sendable {
    // create private destinations by default
    private let consoleDestination = ConsoleDestination()
    // create a public destination if you require access druing runtime, e.g. for collecting logs
    public let fileDestination = LocalFileDestination(fileLocationURL: .documentsDirectory)
}
```
> [!TIP]
> The `LogDestination` instances determine where logs are sent. Whether to the system console, local files, remote servers, or other custom outputs.

#### 3. Create Your Logger
```swift
let logger = KlarLog(
    with: CategoryLoggers(),
    toDestinations: LogDestinations(),
    subsystem: Bundle.main.bundleIdentifier ?? "com.example.app"
)
```

#### 4. Start Logging
```swift
// In this example there are two destinations setup, so KlarLog will output to both destinations

logger.network.info("Starting request")
logger.network.debug("URL: \(url)")
logger.database.error("Connection failed")
```


## Log Destinations
KlarLog allows you to route logs to mutliple log destinations. You can also add custom log destinations by conforming to the `LogDestination` protocol.

For each destination you can configure `logForLogLevels`. The destination will only log for `LogLevel`s listed in that array. This helps to control logging granularity and ebables you to use differnt configurations in Debug und Release:
```swift
#if DEBUG
public let fileDestination = LocalFileDestination(
    logForLogLevels: LogLevel.allCases,
    fileLocationURL: .documentsDirectory
)
#else
public let fileDestination = LocalFileDestination(
    logForLogLevels: [.warning, .error],
    fileLocationURL: .documentsDirectory
)
#endif
```

### Build-in Log Destinations

#### 🖥️ ConsoleDestination
Outputs logs with `OSLog`. In SwiftUI Previews, where `OSLog` is unavailable it fallbacks to `print`.
```swift
private let consoleDestination = ConsoleDestination()
```

#### 💾 LocalFileDestination
Maintains a local persistent log file and automatically manages its size by removing old entries when the maximum message count is reached using FIFO.
```swift
public let fileDestination = LocalFileDestination(
    logForLogLevels: [.critical, .error, .warning],
    fileLocationURL: .documentDirectory,
    fileName: "app-logs",
    maxMessages: 800
)
```
If you declare `LocalFileDestination`as `public` in your `LogDestinations`, you can retieve the object from the `KlarLog` instance.
```swift
let logs = await logger.destinations.fileDestination.readLogs()
await logger.destinations.fileDestination.clearLogs()
```

### Custom Log Destinations
You can add custom Destinations by conforming to the `LogDestination` protocol to trigger custom actions when a log event is triggerd.
Simply add an instance of your `LogDestination` in [Step 2](Define-Your-LoggerDestinations) of the Quick Start.
```swift
/// Sample custom log destination

struct AnalyticsDestination: LogDestination, Sendable {    
    // Protocol conformance
    // Only messages whose level is included in this collection should be handled
    public var logForLogLevels: [LogLevel]
    
    let apiURL: URL
    
    func log(subsystem: String, category: String, level: LogLevel, message: String) {
        // Only perform the action of this destination if it was configured to act on this log level.
        guard logForLogLevels.contains(level) else {
            return
        }
        
        // Send to analytics server ...
    }
}
```
> [!IMPORTANT]
>
> In your custom `LogDestination` implementation you are responsible for implementing `logForLogLevels` checks and only acting on log messages that are included in the `logForLogLevels` configuration like in the example above.

## Log Levels

- `debug` - Detailed diagnostic information
- `info` - General informational messages
- `notice` - Normal but significant events
- `warning` - Warning conditions
- `error` - Error conditions
- `critical` - Critical conditions

## License

`KlarLog` is released under the MIT License. See [LICENSE](LICENSE) for details.

---

## General Debugging tips
- In Xcode use the Metadata Options button (toggle icon) in the lower left of the Debug Console to select which information of a log will be shown.
- Select a single Log message and press space to view full metadata of a single Log.
- Use the Filterbar in the Debug Console to narrow down the logs you see. Filter for specific Categories, Subsystems, Libraries and more.
- Perform a secondary click on a Log to hide/show similar Logs. This is a nice way to clean your logs and focus on whats important to you.
- You can build up chains of multiple Filters in the Filterbar. When you have a filter selected, click the Type button to set _is_ / _is not_ and _contains_ / _equals_.
- OSLog is a tracing facility -> Instruments
- General tip: use _p_ to inspect variabels with LLDB.

#### Ressources
- (WWDC23: Debug with structured logging)[https://developer.apple.com/videos/play/wwdc2023/10226]
- (WWDC20: Explore logging in Swift)[https://developer.apple.com/videos/play/wwdc2020/10168]
- (WWDC18: Measuring Performance using Logging)[https://developer.apple.com/videos/play/wwdc2018/405]

---

# Unsupproted OSLog features
OSLog provides more powerful logging featues that are currently not yet supported in KlarLog.
- Custom types. OSLog Messages can contain a wide range of data types, including custom Types if they conform to `CustomStringConvertible`.
- Privacy level: Non-numeric runtime data like a String or an Object will be redacted in the logs by default <private> – for privacy reasons so that the logs do not show personal information. For data that is not sensitive, with OSLLog you can set the privacy level: `logger.log("Ordered smoothie \(smoothieName, privacy: .public)")`. Logs can be accessed by anyone who has access to the physical device, so never log personal information. You can use an equality reserving hash for senitive information: ` logger.log("Paid with bank account: \(accountNumber, privacy: .private(mask: .hash))")` in OSLog.
- Optional format parameters: `logger.log("\(data, format: .hex, align: . right(columns: width))")`. Explore the full range of options using Xcodes code completion.
- Signposts: use to trace performance-critical paths in Instruments. Mark the beginning and end of a task with a signpost. Read More https://developer.apple.com/documentation/os/recording-performance-data



