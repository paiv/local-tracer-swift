import Foundation
import LocalTracer


class AppTracer {
    static let shared: AppTracer = {
        let storage = LocalTracerInMemoryEventStorage()
        let backend = LocalTracer(storage: storage)
        return AppTracer(backend: backend)
    }()
    
    private let backend: LocalTracer
    
    init(backend: LocalTracer) {
        self.backend = backend
    }
}


extension AppTracer {

    typealias Event = LocalTracer.Event
    
    class Trace {
        weak var owner: AppTracer?
        let startEvent: Event
        
        init(start: Event) {
            self.startEvent = start
        }
        
        static func tracer(_ tracer: AppTracer, startTrace name: String, category: String, args: [AnyHashable: Any]? = nil) -> Trace {
            let event = tracer.backendTraceStart(name: name, category: category, args: args)
            let trace = Trace(start: event)
            trace.owner = tracer
            return trace
        }
        
        func end(args: [AnyHashable: Any]? = nil) {
            _ = owner?.backendTraceEnd(startEvent, args: args)
        }
        
        func end(_ response: URLResponse?) {
            var args: [AnyHashable: Any]? = nil
            if let response = response as? HTTPURLResponse {
                args = [
                    "statusCode": response.statusCode,
                ]
                if let value = response.allHeaderFields["Date"] as? String {
                    args?["Date"] = value
                }
            }
            end(args: args)
        }
    }
}


extension AppTracer {
    
    func backendTraceStart(name: String, category: String, args: [AnyHashable: Any]? = nil) -> Event {
        backend.traceStart(name, category: category, args: args)
    }
    
    func backendTraceEnd(_ event: Event, args: [AnyHashable: Any]? = nil) -> Event {
        backend.traceEnd(event, args: args)
    }
    
    func startProcessingUserRequest(name: String, args: [AnyHashable: Any]? = nil) -> Trace {
        Trace.tracer(self, startTrace: name, category: "user", args: args)
    }

    func startProcessingUrlSessionTask(_ task: URLSessionTask) -> Trace {
        var args: [AnyHashable: Any]? = nil
        if let request = task.originalRequest,
           let url = request.url,
           let httpMethod = request.httpMethod {
            args = [
                "url": url.absoluteString as String,
                "httpMethod": httpMethod as String,
            ]
        }
        let name = task.originalRequest?.url?.path ?? "http_request"
        let event = backend.traceStart(name, category: "network", args: args)
        let trace = Trace(start: event)
        trace.owner = self
        return trace
    }
    
    func exportAndPurgeTracelog(_ completion: @escaping (URL, Error?) -> Void) {
        backend.exportEventsAndResetStorage { (fileUrl: URL, error: Error?) -> Void in
            DispatchQueue.main.async {
                completion(fileUrl, error)
            }
        }
    }
}
