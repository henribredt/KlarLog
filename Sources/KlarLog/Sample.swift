//
//  Sample.swift
//  KlarLog
//
//  Created by Henri Bredt on 25.10.25.
//

import SwiftUI

// Setup the Logger
public struct CategoryLoggers {
    public let general = CategoryLogger(
        category: "general",
        destinations: [ConsoleDestination()]
    )
    public let authentification = CategoryLogger(
        category: "auth",
        destinations: [ConsoleDestination()]
    )
}

let logger = KlarLog(with: CategoryLoggers(), subsystem: Bundle.main.bundleIdentifier ?? "com.example.app")

struct SampleView: View {
    var body: some View {
        Text("KlarLog")
            .onAppear {
                logger.general.info("View appeard")
            }
    }
}
