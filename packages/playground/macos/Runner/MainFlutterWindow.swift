import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private let bookmarkManager = SecurityScopedBookmarkManager()

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    let registrar = flutterViewController.registrar(
      forPlugin: "SecurityScopedBookmarks")
    let bookmarkChannel = FlutterMethodChannel(
      name: "dev.superdeck.playground/security_scoped_bookmarks",
      binaryMessenger: registrar.messenger)
    let bookmarkManager = self.bookmarkManager
    bookmarkChannel.setMethodCallHandler { call, result in
      bookmarkManager.handle(call, result: result)
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
