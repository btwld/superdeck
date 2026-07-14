import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private static let initialContentSize = NSSize(width: 1440, height: 900)
  private static let minimumContentSize = NSSize(width: 1200, height: 700)

  private let bookmarkManager = SecurityScopedBookmarkManager()

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Both editor sidebars are visible by default. The template's 800-point
    // window leaves the central editor with almost no width, so start at a
    // useful desktop size and prevent the window from shrinking back into that
    // unusable layout.
    self.contentMinSize = Self.minimumContentSize
    if self.contentLayoutRect.width < Self.minimumContentSize.width ||
      self.contentLayoutRect.height < Self.minimumContentSize.height {
      self.setContentSize(Self.initialContentSize)
      self.center()
    }

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
