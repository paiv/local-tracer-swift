import Foundation


class TraceEventSerialization {
    
    static func writeEvents(_ events: [LocalTracer.Event], toFileUrl fileUrl: URL, completion: @escaping (URL, Error?) -> Void) {
        guard let stream = OutputStream(toFileAtPath: fileUrl.path, append: false)
        else {
            completion(fileUrl, NSError())
            return
        }
        
        stream.open()
        defer {
            stream.close()
        }
        
        let obj: [AnyHashable: Any] = [
            "traceEvents": events.map(eventSerializer),
        ]
        
        var error: NSError?
        JSONSerialization.writeJSONObject(obj, to: stream, error: &error)
        completion(fileUrl, error)
    }
    
    @inlinable
    static func eventSerializer(_ event: LocalTracer.Event) -> [AnyHashable: Any] {
        switch event {
        case let .asyncEvent(asyncEvent):
            return eventSerializer(asyncEvent)
        }
    }
    
    @inlinable
    static func eventSerializer(_ event: LocalTracer.AsyncEvent) -> [AnyHashable: Any] {
        var obj: [AnyHashable: Any] = [
            "name": event.name as String,
            "cat": event.category as String,
            "ph": event.phase.rawValue as String,
            "ts": Int(event.timestamp.timeIntervalSince1970 * 1000000),
            "pid": event.processId as UInt64,
            "tid": event.threadId as UInt64,
            "id": event.id as UInt64,
        ]
        if let scope = event.scope {
            obj["scope"] = scope as String
        }
        if let args = event.args {
            obj["args"] = args
        }
        return obj
    }
}
