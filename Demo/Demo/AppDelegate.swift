//
//  AppDelegate.swift
//  Demo
//
//  Created by motoki kawakami on 2018/03/24.
//  Copyright © 2018年 mothule. All rights reserved.
//

import UIKit
import SquidLogger

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        SquidLoggerManager.configure(streams: [ConsoleLogger()])
        SquidLoggerManager.defaultLogLevel = .debug
        SquidLoggerManager.configureLogLevel(to: .info)
        

        SquidLoggerManager.configureLogLevel(to: .error, at: ConsoleLogger.self)
        SquidLoggerManager.logLevelSymboler = MyLogLevelSymbol()
        SquidLoggerManager.textFormatter = MyTextFormatter()
        
        IkaLogger.debug("hello world.")
        IkaLogger.info("hello world.")
        IkaLogger.warn("hello world.")
        IkaLogger.error("hello world.")
        IkaLogger.fatal("hello world.")
        
        NetworkLogger.logLevel = .error

        
        return true
    }
}

struct MyTextFormatter: SquidLogTextFormatter {
    func format<T>(_ params: SquidLogParameter<T>) -> String {
        return "\(params.object)"
    }
}


struct MyLogLevelSymbol: SquidLogLevelSymbol {
    func toSymbol(from level: SquidLogLevel) -> String {
        switch level {
        case .info:  return "I"
        case .debug: return "D"
        case .warn:  return "W"
        case .error: return "E"
        case .fatal: return "F"
        case .none:  return ""
        }
    }
}


struct NetworkLogger: SquidLogger {
    static var category: String = "Network"
    static var logLevel: SquidLogLevel?
}



struct ConsoleLogger: SquidLogStreaming {
    var logLevel: SquidLogLevel?
    
    func makeLogText<T>(_ params: SquidLogParameter<T>) -> String? {
        return "\(params.level):\(params.object)"
    }
    
    func filterLogText(_ text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: "hello", options: []) else { return text }
        let range = NSRange(location: 0, length: text.count)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "<FILTERED>")
    }
    
    public func print<T>(_ object: T) {
        Swift.print(object)
    }
}
