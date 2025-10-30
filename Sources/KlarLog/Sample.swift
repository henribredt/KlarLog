//
//  Sample.swift
//  KlarLog
//

import SwiftUI

// 1. Setup the CategoryLoggers
struct CategoryLoggers: Sendable {
    // 2. Add new `CategoryLogger`s here and conigure them
    public let general = CategoryLogger(category: "general")
    public let auth = CategoryLogger(category: "auth")
}

struct LogDestinations: Sendable {
    // create a private destination if the destionation will not be accessed later
    private let console = ConsoleDestination()
    // create a public destination to acesss it late, e.g. for collecting logs
    #if DEBUG
    public let file = LocalFileDestination(
        logForLogLevels: LogLevel.allCases,
        fileLocationURL: .documentsDirectory,
        maxMessages: 1000
    )
    #else
    public let file = LocalFileDestination(
           logForLogLevels: [.warning, .error],
           fileLocationURL: .documentsDirectory,
       )
    #endif
}

// 3. Create a globally accessible KlarLog instance with the CategoryLoggers
let logger = KlarLog(
    with: CategoryLoggers(),
    toDestinations: LogDestinations(),
    subsystem: Bundle.main.bundleIdentifier ?? "com.example.app"
)

struct SampleView: View {
    @State private var logs: String = ""
    @State private var requestCount: Int = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("KlarLog Sample")
                .font(.headline)
                .onAppear {
                    // 4.1 Basic logging
                    logger.general.info("App launched")

                    // 4.2 Structured logging with metadata
                    logger.general.info("App launched", metadata: [
                        "version": "1.0.0",
                        "device": "iPhone",
                        "timestamp": Date().timeIntervalSince1970
                    ])
                }

            Text(logs)
                .font(.caption)
                .multilineTextAlignment(.leading)

            Button {
                // Basic logging
                logger.auth.notice("Signed out")

                // Structured logging with metadata
                logger.auth.notice("User signed out", metadata: [
                    "userId": "12345",
                    "sessionDuration": 3600.5,
                    "wasAutomatic": false
                ])
            } label: {
                Text("Sign out")
            }

            Button {
                requestCount += 1

                // Structured logging for network requests
                logger.general.info("API request completed", metadata: [
                    "url": "https://api.example.com/users",
                    "method": "GET",
                    "status": 200,
                    "duration": 0.45,
                    "requestCount": requestCount
                ])
            } label: {
                Text("Simulate API Request (\(requestCount))")
            }

            Button {
                // Error logging with context
                logger.general.error("Failed to save data", metadata: [
                    "error": "File not found",
                    "path": "/tmp/data.json",
                    "retryCount": 3
                ])
            } label: {
                Text("Log Error with Context")
            }

            Button {
                // 5. Access file logger logs
                let fileDestination = logger.destinations.file
                Task {
                    let allLogs = await fileDestination.readLogs()
                    logs = allLogs.suffix(3).joined(separator: "\n")
                }
            } label: {
                Text("Load Last 3 Logs")
            }
        }
        .padding()
    }
}
