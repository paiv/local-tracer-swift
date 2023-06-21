import Foundation


public class LocalTracerInMemoryEventStorage : LocalTracerEventStorage {
    
    public init() {
    }
    
    public typealias Event = LocalTracer.Event
    
    private(set) var events: [Event] = []
    private let dispatchQueue = DispatchQueue(label: "LocalTracerInMemoryEventStorage")
    
    public func appendEvent(_ event: Event) {
        dispatchQueue.async { [weak self] in
            self?.events.append(event)
        }
    }
    
    public func exportToFile(_ fileUrl: URL, purgeEvents: Bool, completion: @escaping (URL, Error?) -> Void) {
        let events = dispatchQueue.sync {
            let events = self.events
            if purgeEvents {
                self.events = []
            }
            return events
        }
        
        DispatchQueue.global().async {
            TraceEventSerialization.writeEvents(events, toFileUrl: fileUrl, completion: completion)
        }
    }
}
