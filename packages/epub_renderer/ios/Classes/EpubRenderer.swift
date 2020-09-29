import Flutter
import UIKit
import Foundation
import ELReader

class EpubRenderer: NSObject, FlutterPlatformView {

  private let channel: FlutterMethodChannel
  private let args: [String: Any]
  private var readerView: EpubRendererView?

  init(viewId: Int64, args: [String: Any], messeneger: FlutterBinaryMessenger) {
    self.args = args
    channel = FlutterMethodChannel(name: "epub_renderer_view_\(viewId)", binaryMessenger: messeneger)
  }

  func view() -> UIView { getOrSetupReader() }

  private func getOrSetupReader() -> UIView {
    if let currentReaderView = readerView { return currentReaderView.view }
    
    let epubUrl = args["EpubUrl"] as? String ?? ""
    let authToken = args["AuthToken"] as? String ?? ""
    let isAudioEnabled = args["IsAudioEnabled"] as? Bool ?? false
    let minReadTime = args["MinReadTime"] as? Double ?? 1.0

    readerView = EpubRendererView(epubUrl: epubUrl,
                                    authToken: authToken, 
                                    isAudioEnabled: isAudioEnabled,
                                    minReadTime: minReadTime)
    readerView!.delegate = self

    return readerView!.view // TODO: this work?
  }
}

extension EpubRenderer: ReaderDelegate {
  func bookDidLoad(withSuccess success: Bool) {
    channel.invokeMethod("bookDidLoad", arguments: ["success": success])
  }

  func didMove(toPage page: Int) {
    channel.invokeMethod("didMoveToPage", arguments: ["page": page])
  }

  func didFinishMedia(atPage page: Int) {
    channel.invokeMethod("didFinishMediaAtPage", arguments: ["page": page])
  }
}