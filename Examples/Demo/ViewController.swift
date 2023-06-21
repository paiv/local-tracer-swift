import UIKit


class ViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var plainTextSwitch: UISwitch!
    
    @IBAction func handleDownloadButton(_ button: UIBarButtonItem) {
        let pageId = button.tag
        let isPlaintext = plainTextSwitch.isOn
        selectedPage = pageId
        handleDownloadPage(pageId, plaintextModeOn: isPlaintext)
    }
    
    @IBAction func handlePlainTextSwitch(_ sender: Any) {
        let isPlaintext = plainTextSwitch.isOn
        if let pageId = selectedPage {
            handleDownloadPage(pageId, plaintextModeOn: isPlaintext)
        }
    }
    
    @IBAction func handleTracelogButton(_ sender: Any) {
        exportTracelog()
    }
    
    var selectedPage: Int?
    var curl: Curl?
}


extension ViewController {
    
    func handleDownloadPage(_ pageId: Int, plaintextModeOn: Bool) {
        let pages: [Int:String] = [
            1001:"https://www.example.com/page1",
            1002:"https://www.example.com/page2",
            1003:"https://www.example.com/page3",
        ]
        let html2txt = "https://www.w3.org/services/html2txt?url="
        let page = pages[pageId]!
        let pageUrl: URL
        if plaintextModeOn {
            pageUrl = URL(string: html2txt + page)!
        }
        else {
            pageUrl = URL(string: page)!
        }

        let trace = AppTracer.shared.startProcessingUserRequest(name: "download_page", args: ["pageId":pageId, "page":page])

        textView.text = "Loading..."
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) { [weak self] in
            self?.downloadPageUrl(pageUrl) { [weak self] result in
                self?.processDownloadResult(result)
                trace.end()
            }
        }
    }
    
    func processDownloadResult(_ result: Result<String, Error>) {
        switch result {
        case let .success(body):
            textView.text = body
        case let .failure(error):
            textView.text = error.localizedDescription
        }
    }
    
    func downloadPageUrl(_ url: URL, completion: @escaping (Result<String, Error>) -> Void) {
        let curl = Curl()
        self.curl = curl
        curl.getUrl(url, completion: completion)
    }
    
    func exportTracelog() {
        AppTracer.shared.exportAndPurgeTracelog() { [weak self] (fileUrl:URL, error:Error?) in
            if let error = error {
                NSLog("Failed exporting events: \(error)")
            }

            self?.presentSharingControllerForTracelog(fileUrl)
        }
    }
    
    func presentSharingControllerForTracelog(_ fileUrl: URL) {
        let controller = UIActivityViewController(activityItems: [fileUrl], applicationActivities: nil)
        present(controller, animated: true)
    }
}
