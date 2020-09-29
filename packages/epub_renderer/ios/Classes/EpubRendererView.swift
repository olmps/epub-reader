import UIKit
import ELReader

protocol ReaderDelegate: AnyObject {
  func bookDidLoad(withSuccess success: Bool)
  func didMove(toPage page: Int)
  func didFinishMedia(atPage page: Int)
}

class EpubRendererView: UIViewController {

  private let minReadTime: Double
  private let isAudioEnabled: Bool
  private var reader: ELReader!
  private var currentPage: Int = 0

  weak var delegate: ReaderDelegate?

  required init(epubUrl: String, authToken: String, isAudioEnabled: Bool, minReadTime: Double) {
    let headers: [String: Any] = ["Authorization": "Bearer \(authToken)"]
    self.minReadTime = minReadTime
    self.isAudioEnabled = isAudioEnabled

    super.init(nibName: nil, bundle: nil)

    self.reader = ELReader(parentViewController: self, 
                          withEpubPath: epubUrl, 
                          withDownloadHeaders: headers,
                          withAudio: isAudioEnabled, 
                          highlightText: true)

    reader.loadDelegate = self
    reader.eventsDelegate = self
  }

  required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  func go(toPage page: Int) {
    reader.goTo(page)
    currentPage = page
  }

  func play() {
    reader.playMediaOverlay()
  }
    
  func pause() {
    reader.pauseMediaOverlay()
  }
}

extension EpubRendererView: ELReaderLoadDelegate {
  func bookDidNotLoad(_ reader: ELReader) {
    delegate?.bookDidLoad(withSuccess: false)
  }
    
  func bookDidLoad(_ reader: ELReader) {
    delegate?.bookDidLoad(withSuccess: true)
  }
}

extension EpubRendererView: ELReaderEventsDelegate {
  func didChangeLocation(_ locationNumber: Int) {
    delegate?.didMove(toPage: locationNumber)
    currentPage = locationNumber
  }
    
  // TODO(girotto): I don't know if this is necessary (it return the number of pages)
  func didCalculateLocationNumbers(_ totalLocations: Int) {
    print("didCalculateLocationNumbers")
  }
    
  func didFinishLocationAudio() {
    delegate?.didMove(toPage: currentPage)
  }
}