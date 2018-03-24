# SquidLogger
SquidLogger is a multicast logger to multiple logs on Swift.


```swift
NetworkLogger.debug("hello world.")
PaymentLogger.info("hello world.")
```
**Output**
```
📋 debug [Network] 2018-03-24 03:38:02.494 AppDelegate.swift(18) application(_:didFinishLaunchingWithOptions:) - hello world.
💡 info [Payment] 2018-03-24 03:38:02.494 AppDelegate.swift(18) application(_:didFinishLaunchingWithOptions:) - hello world.
```

# Why did I make this?
My project contains multiple logs. (e.g.: Crashlytics logging, Xcode console, our log server)  
I don't want to write the same code. Like the next.
```swift
let text = "Fail to fetching tha User data."
Crashlytics.log(text)
print(text)
OurLogServer.error(text)
```

I want to control logging per modules. Like the next.
- log to Networking is warning or more.
- log to Payment is debug or more.

Therefore I needed this logger.



# How to use

## Mostly simple

Initialize and default logger.
Log stream is only default console log stream if SquidLoggerManager.configure() arguments empty when initialize.

```swift
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

      // Initialize code
      SquidLoggerManager.configure()

      // Each logs with log level
      IkaLogger.debug("hello world.")
      IkaLogger.info("hello world.")
      IkaLogger.warn("hello world.")
      IkaLogger.error("hello world.")
      IkaLogger.fatal("hello world.")

      return true
    }
}
```

**Output**
```
📋 info [Default] 2018-03-24 03:38:02.494 AppDelegate.swift(18) application(_:didFinishLaunchingWithOptions:) - hello world.
💡 info [Default] 2018-03-24 03:38:02.494 AppDelegate.swift(19) application(_:didFinishLaunchingWithOptions:) - hello world.
⚠️ warn [Default] 2018-03-24 03:38:02.496 AppDelegate.swift(20) application(_:didFinishLaunchingWithOptions:) - hello world.
🚫 error [Default] 2018-03-24 03:38:02.496 AppDelegate.swift(21) application(_:didFinishLaunchingWithOptions:) - hello world.
💔 fatal [Default] 2018-03-24 03:38:02.496 AppDelegate.swift(22) application(_:didFinishLaunchingWithOptions:) - hello world.
```

**Attention**
This is sample so I don't recommend you. Because this library is a multicast logger and not a logger.
So confirm below.


# How to use detail

## Change a log level
`SquidLoggerManager.defaultLogLevel` will apply to all log streams.
```swift
SquidLoggerManager.configureLogLevel(to: .info)
SquidLoggerManager.defaultLogLevel = .warn
```

## Add new log streams
At first, implement a log stream.
```swift
struct ConsoleLogger: SquidLogStreaming {
    public func print<T>(_ object: T) {
        Swift.print(object)
    }
}
```

Next, add stream to SquidLoggerManager.
```swift
SquidLoggerManager.configure(streams: [ConsoleLogger()])
```

**Attention**
Will remove default log stream from managed log streams if added any new log stream.

## Change a log level of a log stream
A log stream(`ConsoleLogger`) has already been implemented.
```swift
SquidLoggerManager.configureLogLevel(to: .error, at: ConsoleLogger.self)
```

## Add new log modules

You just implement below if you want to use for networking area.

```swift
struct NetworkLogger: SquidLogger {
    static var category: String = "Network"
    static var logLevel: SquidLogLevel?
}
```

You will just call a NetworkLogger.
```swift
NetworkLogger.info("User data fetch completed")
```

**Attention**
SquidLogger isn't thread safe.
Because this library primary purpose is multicast.
logging is not important purpose.

## Change a log level of a log module

```swift
struct NetworkLogger: SquidLogger {
    static var category: String = "Network"
    static var logLevel: SquidLogLevel? = .debug
}

NetworkLogger.logLevel = .error
```

## Change a symbol of log level

At first, Implement symboler.
```swift
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
```

configure your symboler instance.
```swift
SquidLoggerManager.logLevelSymboler = MyLogLevelSymbol()
```

## Change a log message format

```swift
struct MyTextFormatter: SquidLogTextFormatter {
    func format<T>(_ params: SquidLogParameter<T>) -> String {
        return "\(params.object)"
    }
}
```

```swift
SquidLoggerManager.textFormatter = MyTextFormatter()
```

## Change a log message format of log stream

implement `SquidLogStreaming.makeLogText` method.

````swift
struct ConsoleLogger: SquidLogStreaming {
    func makeLogText<T>(_ params: SquidLogParameter<T>) -> String? {
        return "\(params.level):\(params.object)"
    }
}
```

## Filter a log message of log stream

Implement `SquidLogStreaming.filterLogText` method.

```swift
struct ConsoleLogger: SquidLogStreaming {
  func filterLogText(_ text: String) -> String {
      guard let regex = try? NSRegularExpression(pattern: "hello", options: []) else { return text }
      let range = NSRange(location: 0, length: text.count)
      return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "<FILTERED>")
  }
}

IkaLogger.warn("hello world.")

```

```
📋 warn [Default] 2018-03-24 03:38:02.494 AppDelegate.swift(18) application(_:didFinishLaunchingWithOptions:) - <FILTERED> world.
```

## About filtering of log level

|Final Level|SquidLogManager.<br>defaultLogLevel|SquidLogger.<br>logLevel|SquidLogStreaming.<br>logLevel|
|---|---|---|
|**debug**|**debug**|nil|nil|
|**info**|debug|**info**|nil|
|**warn**|debug|nil|**warn**|
|**warn**|debug|info|**warn**|
|**error**|**error**|nil|nil|
|**info**|error|**info**|nil|
|**warn**|error|nil|**warn**|
|**warn**|error|info|**warn**|


# Runtime Requirements

- Swift 3.2 or later
- iOS 9 or later
- Xcode 9.2 or later

# Library implementation policy

- Don't forget primary purpose.
- Lightweight
