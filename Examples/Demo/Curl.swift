import Foundation


class Curl {
    
    init() {
        session = URLSession(configuration: .default)
    }
    
    let session: URLSession

    func getUrl(_ url: URL, completion: @escaping (Result<String, Error>) -> Void) {
        let request = URLRequest(url: url)
        let handler = { (data:Data?, response:URLResponse?, error:Error?) -> Void in
            if let error = error {
                completion(Result.failure(error))
            }
            else if let data = data {
                if let body = String(data: data, encoding: .utf8) {
                    completion(Result.success(body))
                }
                else {
                    completion(Result.failure(NSError.appError("invalid response format")))
                }
            }
            else {
                completion(Result.failure(NSError.appError("unknown error")))
            }
        }
        var trace: AppTracer.Trace?
        let task = session.dataTask(with: request) { (data:Data?, response:URLResponse?, error:Error?) in
            trace?.end(response)
            if Thread.isMainThread {
                handler(data, response, error)
            }
            else {
                DispatchQueue.main.async {
                    handler(data, response, error)
                }
            }
        }
        trace = AppTracer.shared.startProcessingUrlSessionTask(task)
        task.resume()
    }
}


extension NSError {
    
    static func appError(_ description: String) -> NSError {
        NSError(domain: "DemoAppErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey:description])
    }
}
