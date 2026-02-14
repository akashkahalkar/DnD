//
//  DnDApp.swift
//  DnD
//
//  Created by Akash on 12/02/26.
//

import SwiftUI
import Foundation
import os

@main
struct DnDApp: App {
    init() {
        StartupDiagnostics.mark("App init start")
        Font.setupFonts()
        StartupDiagnostics.mark("App init complete")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    StartupDiagnostics.mark("WindowGroup ContentView appeared")
                }
        }
    }
}

enum StartupDiagnostics {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "DnD", category: "startup")
    private static let startUptime = ProcessInfo.processInfo.systemUptime
    
    static func mark(_ message: String) {
        let elapsed = ProcessInfo.processInfo.systemUptime - startUptime
        let formatted = String(format: "%.3f", elapsed)
        logger.info("\(message, privacy: .public) (+\(formatted, privacy: .public)s)")
        print("[Startup] \(message) (+\(formatted)s)")
    }
    
    static func timed<T>(_ label: String, _ operation: () throws -> T) rethrows -> T {
        mark("\(label) started")
        let operationStart = ProcessInfo.processInfo.systemUptime
        defer {
            let elapsed = ProcessInfo.processInfo.systemUptime - operationStart
            let formatted = String(format: "%.3f", elapsed)
            mark("\(label) finished in \(formatted)s")
        }
        return try operation()
    }
}
