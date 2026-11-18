import Cocoa
import FlutterMacOS

/// Yawala Files - macOS runner bootstrap.
class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    registerNativeBindingStubs(with: flutterViewController)
    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  /// Registers the `com.yawalasiwala/files` method channel with safe-fallback
  /// responses until the real NSOpenPanel / NSVolume enumeration lands.
  private func registerNativeBindingStubs(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.yawalasiwala/files",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "pickFiles", "pickDirectory":
        result(nil)
      case "listStorageVolumes":
        result([[
          "name": "Macintosh HD",
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
}
