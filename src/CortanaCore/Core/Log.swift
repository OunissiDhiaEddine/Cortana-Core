import os

/// Central loggers. View with Console.app or `log stream --predicate 'subsystem == "dhia.Cortana-Core"'`.
enum Log {
    private static let subsystem = "dhia.Cortana-Core"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let chat = Logger(subsystem: subsystem, category: "chat")
    static let engine = Logger(subsystem: subsystem, category: "engine")
}
