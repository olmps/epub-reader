import Flutter
import UIKit

public class SwiftEpubRendererPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "epub_renderer", binaryMessenger: registrar.messenger())
    let instance = SwiftEpubRendererPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    registrar.register(
        EpubRendererFactory(messeneger: registrar.messenger()),
        withId: "epub_renderer_view"
    )
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    print("IOS WAS CALLED")
    result("iOS " + UIDevice.current.systemVersion)
  }
}
