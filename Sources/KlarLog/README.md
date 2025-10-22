#  KlarLog

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
