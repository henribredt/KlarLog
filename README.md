# KlarLog

A lightweight, type-safe logging framework for Swift with powerful destination-based routing.

### Features

- **Type-Safe Categories** - Define logging categories in a compile-time checked registry
- **Dynamic Member Lookup** - Clean dot-notation syntax for accessing loggers
- **Multiple Destinations** - Route logs to console, files, and custom destinations
- **File Logging** - Built-in `LocalFileDestination` with automatic size management
- **OS.Log Integration** - Built-in `ConsoleDestination` uses `os.Logger` for Xcodes Debug Console and Console.app integration
- **Modern Concurrency** - Built with Swift concurrency

### Installation

Add KlarLog via Swift Package Manager in Xcode: **File → Add Package Dependencies**
```
https://github.com/henribredt/KlarLog
```


### Quick Start
Configure KlarLog on app launch. Provide your configured `CategoryLoggers`and `LogDestinations` as structs.
To make your instance globally available create a new file `KlarLogConfig.swift` and add steps 1.-3. to that file.
#### 1. Define your CategoryLoggers
```swift
public struct CategoryLoggers {
    // Add your `CategoryLogger`s
    public let network = CategoryLogger(category: "network")
    public let database = CategoryLogger(category: "database")
}
```

#### 2. Define Your LoggerDestinations
```swift
public struct LogDestinations {
    // create private destinations by default
    private let console = ConsoleDestination()
    // create a public destination if you require access druing runtime, e.g. for collecting logs
    public let file = LocalFileDestination(fileURL: .documentDirectory, maxMessages: 800)
}
```

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
logger.network.info("Starting request")
logger.network.debug("URL: \(url)")
logger.database.error("Connection failed")
```
In this example there are two destinations setup, so KlarLog will log to OS.Log and to a local file.

### Log Levels

- `debug` - Detailed diagnostic information
- `info` - General informational messages
- `notice` - Normal but significant events
- `warning` - Warning conditions
- `error` - Error conditions
- `critical` - Critical conditions

### Reading Logs
```swift
// Access file destination via dynamic member lookup
let logs = await log.fileDestination.readLogs()

// Clear logs
await log.fileDestination.clearLogs()
```

### Custom Destinations
You can add custom Destinations by conforming to the `LogDestination` protocol to trigger custom actions when a log event is triggerd.
Simply add an instance of your `LogDestination` in step 2 of the Quick Start.
```swift
struct AnalyticsDestination: LogDestination {
    let apiURL: URL
    
    func log(subsystem: String, category: String, level: ExposedCategoryLogger.Level, message: String) {
        Task {
            var request = URLRequest(url: apiURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let payload = [
                "subsystem": subsystem,
                "category": category,
                "level": level.rawValue,
                "message": message,
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
            
            request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
            
            try? await URLSession.shared.data(for: request)
        }
    }
}
```

# OSLog hints

## Writing Log messages
- Use String interpolation to access runtime data. Messages can contain a wide range of data types. Including custom Types if they conform to `CustomStringConvertible`.
- Non-numeric runtime data like a String or an Object will be redacted in the logs by default <private> – for privacy reasons so that the logs do not show personal information. For data that is not sensitive, set the privacy level: `logger.log("Ordered smoothie \(smoothieName, privacy: .public)")`. Logs can be accessed by anyone who has access to the physical device, never log personal information. You can use an equality reserving hash for senitive information: ` logger.log("Paid with bank account: \(accountNumber, privacy: .private(mask: .hash))")`
- Use optional format parameters: `logger.log("\(data, format: .hex, align: . right(columns: width))")`. Explore the full range of options using Xcodes code completion.

## Choosing a Log level
Listed in increasing relevance:
- Debug: Useful only during debugging (Not persisted)
- Info: Helpful but not essential for troubleshooting (Persisted only during logcollect)
- Notice (Default): Essential for troubleshooting (Persisted up to storage limit)
- Error: Errors seen during app execution (Persisted up to storage limit)
- Fault: Bug in program (Persisted up to storage limit)

##Signposts
- use to trace performance-critical paths in Instruments. Mark the beginning and end of a task with a signpost.
- Read More https://developer.apple.com/documentation/os/recording-performance-data

## Xcode
- Use the Metadata Options button 􀜊 in the lower left of the Debug Console. Or Select a single Log and press space to view full metadata of a single Log.
- Use the Filterbar next to the 􀈑 to narrow down the logs you see. Filter for specific Categories, Subsystems, Libraries and more.
- Perform a secondary click on a Log to hide/show similar Logs. This is a nice way to clean your logs.
- You can build up chains of multiple Filters in the Filterbar. Click the 􀆈 to set _is_ / _is not_ and _contains_ / _equals_.
- Hover over Logs to view the source location in the right lower corner.

- General tip: use _p_ when inspecting variabels with LLDB.



- use categories for different areas of the project
- OSLogStore
- OSLog is a tracing facility -> Instruments

### Ressources
- (WWDC23: Debug with structured logging)[https://developer.apple.com/videos/play/wwdc2023/10226]
- (WWDC20: Explore logging in Swift)[https://developer.apple.com/videos/play/wwdc2020/10168]
- (WWDC18: Measuring Performance using Logging)[https://developer.apple.com/videos/play/wwdc2018/405]
 


### Use in other packages
//  Re-exports PoolLoggerKit to make the logger available
//  to all files in PoolBusinessKit without requiring separate imports.
//
@_exported import PoolLoggerKit
