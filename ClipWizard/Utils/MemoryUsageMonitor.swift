import Foundation

/// Utility for monitoring application memory usage
struct MemoryUsageMonitor {
    
    /// Get the current memory usage of the application
    /// - Returns: Memory usage in bytes
    static func currentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
    
    /// Get formatted memory usage string
    /// - Returns: Human-readable memory usage string
    static func formattedMemoryUsage() -> String {
        let bytes = currentMemoryUsage()
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
    }
    
    /// Log current memory usage
    static func logMemoryUsage(label: String = "Current memory usage") {
        logInfo("\(label): \(formattedMemoryUsage())")
    }
    
    /// Start periodic memory usage logging
    /// - Parameters:
    ///   - interval: Time interval in seconds between logs
    ///   - label: Label to prefix the log with
    /// - Returns: Timer that can be used to stop logging
    @discardableResult
    static func startPeriodicLogging(interval: TimeInterval = 60, label: String = "Memory usage") -> Timer {
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            logMemoryUsage(label: label)
        }
        
        // Log immediately
        logMemoryUsage(label: label)
        
        return timer
    }
}
