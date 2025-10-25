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
        destinations: [ConsoleDestination()]
    )
    public let authentification = CategoryLogger(
        category: "auth",
        destinations: [ConsoleDestination()]
    )
}

// 3. Create a globally accessible KlarLog instance with the CategoryLoggers
let logger = KlarLog(with: CategoryLoggers(), subsystem: Bundle.main.bundleIdentifier ?? "com.example.app")

struct SampleView: View {
    var body: some View {
        Text("KlarLog")
            .onAppear {
                // 4. Use logger
                logger.general.info("View appeard")
            }
    }
}
