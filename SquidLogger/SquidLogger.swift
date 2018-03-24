//
//  SquidLogger.swift
//  SquidLogger
//
//  Created by motoki kawakami on 2018/03/23.
//  Copyright © 2018年 mothule. All rights reserved.
//

import Foundation

// MARK: - Manager ===================
public class SquidLoggerManager {
    /// default log level in SquidLogger
    public static var defaultLogLevel: SquidLogLevel = .info
    
    /// logs will are flushed to these.
    public static var logStreams: [SquidLogStreaming] = []
    
    /// symbol converter will use to convert to symbol from log level.
    /// symbols will are displayed to logs.
    public static var logLevelSymboler: SquidLogLevelSymbol = SquidLogLevelDefaultSymbol()
    
    
    public static var textFormatter: SquidLogTextFormatter = SquidLogDefaultTextFormatter()
    
    /// should call in order to initialize.
    public static func configure( streams: [SquidLogStreaming] = [SquidConsoleLogger()]) {
        logStreams = streams
    }
    
    /// configure a log stream's log level
    public static func configureLogLevel<T>(to level: SquidLogLevel, at target: T.Type) {
        guard let index = logStreams.index(where: { type(of: $0) == target }) else {
            assertionFailure("\(target) was not found in log streams")
            return
        }
        logStreams[index].logLevel = level
    }
    public static func configureLogLevel(to level: SquidLogLevel) {
        defaultLogLevel = level
    }
    
    static func print<T>(_ params: SquidLogParameter<T>) {
        let defaultLogText = textFormatter.format(params)
        logStreams.forEach({ logStream in
            logStream.printWithFiltering(params, defaultLogText: defaultLogText)
        })
    }
}

// MARK: - Logger ===================
/// logger protocol of SquidLogger.
/// Implementing this protocol will can you control the log per module.
public protocol SquidLogger {
    // MARK: Required
    static var category: String { get }
    
    // MARK: Optional
    /// will used default log level if nil
    static var logLevel: SquidLogLevel? { get }
}

extension SquidLogger {
    static var logLevel: SquidLogLevel? { return nil }
    
    public static func debug<T>(_ object: T, file: String = #file, line: UInt = #line, function: String = #function) {
        let level: SquidLogLevel = .debug
        let params = SquidLogParameter(object: object, level: level, category: category, file: file, line: line, function: function)
        self.print(params)
    }
    public static func info<T>(_ object: T, file: String = #file, line: UInt = #line, function: String = #function) {
        let level: SquidLogLevel = .info
        let params = SquidLogParameter(object: object, level: level, category: category, file: file, line: line, function: function)
        self.print(params)
    }
    public static func warn<T>(_ object: T, file: String = #file, line: UInt = #line, function: String = #function) {
        let level: SquidLogLevel = .warn
        let params = SquidLogParameter(object: object, level: level, category: category, file: file, line: line, function: function)
        self.print(params)
    }
    public static func error<T>(_ object: T, file: String = #file, line: UInt = #line, function: String = #function) {
        let level: SquidLogLevel = .error
        let params = SquidLogParameter(object: object, level: level, category: category, file: file, line: line, function: function)
        self.print(params)
    }
    public static func fatal<T>(_ object: T, file: String = #file, line: UInt = #line, function: String = #function) {
        let level: SquidLogLevel = .fatal
        let params = SquidLogParameter(object: object, level: level, category: category, file: file, line: line, function: function)
        self.print(params)
    }
    public static func none<T>(_ object: T, file: String = #file, line: UInt = #line, function: String = #function) {
        let level: SquidLogLevel = .none
        let params = SquidLogParameter(object: object, level: level, category: category, file: file, line: line, function: function)
        self.print(params)
    }
    
    static var logLevelOrDefault: SquidLogLevel {
        return logLevel ?? SquidLoggerManager.defaultLogLevel
    }

    fileprivate static func print<T>(_ params: SquidLogParameter<T>) {
        guard logLevelOrDefault.canFlushAs(params.level) else { return }
        SquidLoggerManager.print(params)
    }
}

// TODO: SquidLogのメソッド内でSquidLogManagerを呼んでいるメソッドは
// SquidLogManagerに実装または新たに実体処理を抽出したほうがよさげ。
public protocol SquidLogTextFormatter {
    func format<T>(_ params: SquidLogParameter<T>) -> String
}

public struct SquidLogDefaultTextFormatter: SquidLogTextFormatter {
    public func format<T>(_ params: SquidLogParameter<T>) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        let text = "\(params.level.description()) \(params.level) [\(params.category)] \(df.string(from: Foundation.Date())) \(params.fileName)(\(params.line)) \(params.function) - \(params.object)"
        return text
    }
}

public struct IkaLogger: SquidLogger {
    public static var category: String = "Default"
    public static var logLevel: SquidLogLevel?
}

// MARK: - Stream ===================
/// log stream protocol
public protocol SquidLogStreaming {
    // MARK: Required
    func print<T>(_ object: T)
    
    // MARK: Optional
    /// will used default log level if nil
    var logLevel: SquidLogLevel? { get set }

    /// can customize log for this stream, default is nil.
    func makeLogText<T>(_ params: SquidLogParameter<T>) -> String?
    
    /// can filter body text for this stream, default do nothing.
    func filterLogText(_ text: String) -> String
}

extension SquidLogStreaming {
    public var logLevel: SquidLogLevel? { return nil }
    var logLevelOrDefault: SquidLogLevel {
        return logLevel ?? SquidLoggerManager.defaultLogLevel
    }
    public func makeLogText<T>(_ params: SquidLogParameter<T>) -> String? { return nil }
    public func filterLogText(_ text: String) -> String { return text }
    func makeFilteredLogText<T>(_ params: SquidLogParameter<T>) -> String? {
        guard let text = makeLogText(params) else { return nil }
        return filterLogText(text)
    }
    
    func printWithFiltering<T>(_ params: SquidLogParameter<T>, defaultLogText: String) {
        guard logLevelOrDefault.canFlushAs(params.level) else { return }
        let finalText = makeFilteredLogText(params) ?? defaultLogText
        self.print(finalText)
    }
}

/// Default log stream
public struct SquidConsoleLogger: SquidLogStreaming {
    public var logLevel: SquidLogLevel?
    
    public init() {}
    public func print<T>(_ object: T) {
        Swift.print(object)
    }
}

// MARK: - Others ===================
/// parameter when print to log.
public struct SquidLogParameter<T> {
    public let object: T
    public let level: SquidLogLevel
    public let category: String
    public let file: String // #file
    public let line: UInt // #line
    public let function: String // #function
    
    public var fileName: String { return URL(string: file)?.lastPathComponent ?? "" }
}

/// log level symbol converter
public protocol SquidLogLevelSymbol {
    func toSymbol(from level: SquidLogLevel) -> String
}

/// default log level symbol converter
public struct SquidLogLevelDefaultSymbol: SquidLogLevelSymbol {
    public func toSymbol(from level: SquidLogLevel) -> String {
        switch level {
        case .info:  return "💡"
        case .debug: return "📋"
        case .warn:  return "⚠️"
        case .error: return "🚫"
        case .fatal: return "💔"
        case .none:  return ""
        }
    }
}

/// log level types
public enum SquidLogLevel: Int, Comparable, Equatable {
    case debug = 1
    case info = 2
    case warn = 3
    case error = 4
    case fatal = 5
    case none = 6
    
    public func description() -> String {
        return SquidLoggerManager.logLevelSymboler.toSymbol(from: self)
    }
    
    public static func <(lhs: SquidLogLevel, rhs: SquidLogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    public static func ==(lhs: SquidLogLevel, rhs: SquidLogLevel) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
    func canFlushAs(_ level: SquidLogLevel) -> Bool {
        return self <= level
    }
}
