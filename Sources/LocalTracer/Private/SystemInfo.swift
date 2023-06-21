import Foundation


class SystemInfo {

    static func processId() -> UInt64 {
        let pid = getpid()
        return UInt64(bitPattern: Int64(pid))
    }
    
    static func threadId() -> UInt64 {
        var threadId: UInt64 = 0
        pthread_threadid_np(nil, &threadId)
        return threadId
    }
}
