//
//  Sample.swift
//  KlarLog
//

import SwiftUI

// 1. Setup the CategoryLoggers
struct CategoryLoggers: Sendable {
    // 2. Add new `CategoryLogger`s here and conigure them
    public let general = CategoryLogger(category: "general")
    public let authentification = CategoryLogger(category: "auth")
}

struct LogDestinations: Sendable {
    // create a private destination if the destionation will not be accessed later
    private let console = ConsoleDestination()
    // create a public destination to acesss it late, e.g. for collecting logs
    #if DEBUG
    public let file = LocalFileDestination(
        logForLogLevels: LogLevel.allCases,
        fileLocationURL: .documentsDirectory,
        maxMessages: 800
    )
    #else
    public let file = LocalFileDestination(
           logForLogLevels: [.warning, .error],
           fileLocationURL: .documentsDirectory,
           maxMessages: 800
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
    var body: some View {
        VStack{
            Text("KlarLog")
                .onAppear {
                    // 4. Use logger
                    logger.general.info("View appeard")
                }
            
            Button {
            // TODO: GET ACCESSS TO LOGS
                let fileDestination = logger.destinations.file
                Task{
                    logs = await fileDestination.readLogs().first ?? "no log"
                }
                
            } label: {
                Text("Load logs")
            }

        }
    }
}
