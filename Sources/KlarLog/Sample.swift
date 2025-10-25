//
//  Sample.swift
//  KlarLog
//

import SwiftUI

// 1. Setup the CategoryLoggers
public struct CategoryLoggers {
    // 2. Add new `CategoryLogger`s here and conigure them
    public let general = CategoryLogger(
        category: "general",
        destinations: [
            ConsoleDestination(),
            LocalFileDestination(fileURL: .documentsDirectory, maxMessages: 1000)
        ]
    )
    public let authentification = CategoryLogger(
        category: "auth",
        destinations: [ConsoleDestination()]
    )
}

// 3. Create a globally accessible KlarLog instance with the CategoryLoggers
let logger = KlarLog(with: CategoryLoggers(), subsystem: Bundle.main.bundleIdentifier ?? "com.example.app")

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
            //  logs = logger.base.base.destinations.fi
            } label: {
                Text("Load logs")
            }

        }
    }
}
