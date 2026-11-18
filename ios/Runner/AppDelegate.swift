import Flutter
import UIKit

/// Yawala Files - iOS runner bootstrap.
///
/// Registers the `com.yawalasiwala/files` method channel so the Dart layer
/// can drive UIDocumentPicker-based import/export, volume enumeration and
/// security-scoped directory access. Values below are safe-fallback stubs
/// until the real document-picker integration lands.
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.yawalasiwala/files",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        switch call.method {
        case "pickFiles", "pickDirectory":
          result(nil)
        case "listStorageVolumes":
          result([[
            "name": "On My iPhone",
            "rootPath": "/",
            "isRemovable": false,
            "freeBytes": 0,
            "totalBytes": 0,
          ]])
        case "requestDirectoryAccess":
          result("unsupported")
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
