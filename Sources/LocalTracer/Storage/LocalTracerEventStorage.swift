import Foundation


public protocol LocalTracerEventStorage {

    func appendEvent(_ event: LocalTracer.Event)
    func exportToFile(_ fileUrl: URL, purgeEvents: Bool, completion: @escaping (URL, Error?) -> Void)
}
