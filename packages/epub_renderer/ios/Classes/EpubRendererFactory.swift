import Flutter
import Foundation

class EpubRendererFactory : NSObject, FlutterPlatformViewFactory {
  private let messeneger: FlutterBinaryMessenger

  init(messeneger: FlutterBinaryMessenger) {
    self.messeneger = messeneger
  }

  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    EpubRenderer(viewId: viewId, args: args as? [String : Any] ?? [:], messeneger: messeneger)
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
}