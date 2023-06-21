import Foundation


public class LocalTracer {

	public enum Event {
		case asyncEvent(AsyncEvent)
	}

	public typealias Storage = LocalTracerEventStorage
	private let storage: Storage

	public init(storage: some Storage) {
		self.storage = storage
	}
    
    private var lastEventId: UInt64 = 0
    
    private func generateEventId() -> Event.EventId {
        let value = OSAtomicIncrement64(&lastEventId)
        let eventId = Event.EventId(value)
        return eventId
    }
}


public extension LocalTracer.Event {

	typealias EventId = UInt64
	typealias Category = String
	typealias Scope = String

	enum Phase : String {
		case asyncStart = "b"
		case asyncEnd = "e"
        case asyncInstance = "n"
	}
}

public extension LocalTracer {

	class AsyncEvent {
        public typealias Phase = Event.Phase
        public typealias EventId = Event.EventId
        public typealias Category = Event.Category
        public typealias Scope = Event.Scope
        
        public let timestamp: Date
        public let processId: UInt64
        public let threadId: UInt64
		public let name: String
		public let phase: Phase
		public let id: EventId
		public let category: Category
		public let scope: Scope?
        public let args: [AnyHashable: Any]?

		public init(name: String, phase: Phase, id: EventId, category: Category, scope: Scope?, args: [AnyHashable: Any]?) {
            self.timestamp = Date()
            self.processId = SystemInfo.processId()
            self.threadId = SystemInfo.threadId()
			self.name = name
			self.phase = phase
			self.id = id
			self.category = category
			self.scope = scope
            self.args = args
		}
        
        public convenience init(name: String, phase: Phase, parent: AsyncEvent, args: [AnyHashable: Any]? = nil) {
            self.init(name: name, phase: phase, id: parent.id, category: parent.category, scope: parent.scope, args: args)
        }
	}

    func traceStart(_ name: String, category: Event.Category, args: [AnyHashable: Any]? = nil) -> Event {
        let eventId = generateEventId()
        let asyncEvent = AsyncEvent(name: name, phase: .asyncStart, id: eventId, category: category, scope: nil, args: args)
        let event: Event = .asyncEvent(asyncEvent)
        storage.appendEvent(event)
		return event
	}

	func traceStart(_ name: String, parent: Event) -> Event {
        switch parent {
        case let .asyncEvent(parent):
            let asyncEvent = AsyncEvent(name: name, phase: .asyncStart, parent: parent)
            let event = Event.asyncEvent(asyncEvent)
            storage.appendEvent(event)
            return event
        }
	}
    
    func traceEnd(_ event: Event, args: [AnyHashable: Any]? = nil) -> Event {
        switch event {
        case let .asyncEvent(parent):
            let asyncEvent = AsyncEvent(name: parent.name, phase: .asyncEnd, parent: parent, args: args)
            let event = Event.asyncEvent(asyncEvent)
            storage.appendEvent(event)
            return event
        }
    }
    
    func traceInstance(_ name: String, category: Event.Category, args: [AnyHashable: Any]? = nil) -> Event {
        let eventId = generateEventId()
        let asyncEvent = AsyncEvent(name: name, phase: .asyncInstance, id: eventId, category: category, scope: nil, args: args)
        let event: Event = .asyncEvent(asyncEvent)
        storage.appendEvent(event)
        return event
    }
    
    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = "yyyyMMddHHmmss"
        return formatter
    }()

    func exportEventsAndResetStorage(_ completion: @escaping (URL, Error?) -> Void) {
        let now = Date()
        let timestamp = LocalTracer.timestampFormatter.string(from: now)
        let temp = FileManager.default.temporaryDirectory
        let fileUrl = temp.appendingPathComponent("export-\(timestamp).json", isDirectory: false)
        storage.exportToFile(fileUrl, purgeEvents: true, completion: completion)
    }
}
