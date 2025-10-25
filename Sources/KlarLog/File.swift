//
//  File.swift
//  KlarLog
//
//  Created by Henri Bredt on 23.10.25.
//

import Foundation
import OSLog
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            
            Button {
                logger.general.warning("Charge authorized")
            } label: {
                Text("Log")
            }

        }
        .padding()
        .onAppear {
            print("setup")
            Logger(subsystem: "test", category: "love").info("hi")
            logger.general.warning("Charge authorized")
        }
    }
}

#Preview {
    ContentView()
}


// MARK: Global Logger configuration
public struct CategoryLoggers {
    public let general = CategoryLogger(
        category: "general",
        destinations: [
            ConsoleDestination()
        ]
    )
}

// Example Usage (kept additive; remove if you already have a usage block)
let logger = TypedLogger(with: CategoryLoggers(), subsystem: "com.example.app")
