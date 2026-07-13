import Cocoa
import FlutterMacOS
import UniformTypeIdentifiers

private enum SecurityScopedBookmarkError: LocalizedError {
  case invalidArgument(String)
  case invalidBookmark
  case accessDenied(String)

  var errorDescription: String? {
    switch self {
    case .invalidArgument(let method):
      return "Invalid argument for \(method)."
    case .invalidBookmark:
      return "The stored security-scoped bookmark is invalid."
    case .accessDenied(let path):
      return "Could not start security-scoped access to \(path)."
    }
  }
}

final class SecurityScopedBookmarkManager {
  private var activeURLs: [String: URL] = [:]

  deinit {
    for url in activeURLs.values {
      url.stopAccessingSecurityScopedResource()
    }
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    do {
      switch call.method {
      case "pickDeckFile":
        result(try pickDeckFile())
      case "startAccessing":
        guard let bookmark = call.arguments as? String, !bookmark.isEmpty else {
          throw SecurityScopedBookmarkError.invalidArgument(call.method)
        }
        result(try startAccessing(bookmark: bookmark))
      case "stopAccessing":
        guard let bookmark = call.arguments as? String, !bookmark.isEmpty else {
          throw SecurityScopedBookmarkError.invalidArgument(call.method)
        }
        stopAccessing(bookmark: bookmark)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    } catch {
      result(
        FlutterError(
          code: "SECURITY_SCOPED_BOOKMARK_ERROR",
          message: error.localizedDescription,
          details: nil))
    }
  }

  private func pickDeckFile() throws -> [String: String]? {
    let panel = NSOpenPanel()
    panel.title = "Open deck"
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.canChooseFiles = true

    if #available(macOS 11.0, *) {
      if let markdown = UTType(filenameExtension: "md") {
        panel.allowedContentTypes = [markdown]
      }
    } else {
      panel.allowedFileTypes = ["md"]
    }

    guard panel.runModal() == .OK, let url = panel.url else {
      return nil
    }

    // URLs returned by NSOpenPanel carry temporary Powerbox access. Persist
    // that access as a bookmark, then balance the temporary grant. Dart starts
    // the bookmark before reading the selected file.
    defer { url.stopAccessingSecurityScopedResource() }
    let bookmark = try makeBookmark(for: url)
    return ["path": url.path, "bookmark": bookmark]
  }

  private func startAccessing(bookmark: String) throws -> [String: String] {
    if let url = activeURLs[bookmark] {
      return ["path": url.path, "bookmark": bookmark]
    }
    guard let data = Data(base64Encoded: bookmark) else {
      throw SecurityScopedBookmarkError.invalidBookmark
    }

    var isStale = false
    let url = try URL(
      resolvingBookmarkData: data,
      options: [.withSecurityScope],
      relativeTo: nil,
      bookmarkDataIsStale: &isStale)
    guard url.startAccessingSecurityScopedResource() else {
      throw SecurityScopedBookmarkError.accessDenied(url.path)
    }

    do {
      let activeBookmark = isStale ? try makeBookmark(for: url) : bookmark
      activeURLs[activeBookmark] = url
      return ["path": url.path, "bookmark": activeBookmark]
    } catch {
      url.stopAccessingSecurityScopedResource()
      throw error
    }
  }

  private func stopAccessing(bookmark: String) {
    activeURLs.removeValue(forKey: bookmark)?.stopAccessingSecurityScopedResource()
  }

  private func makeBookmark(for url: URL) throws -> String {
    let data = try url.bookmarkData(
      options: [.withSecurityScope],
      includingResourceValuesForKeys: nil,
      relativeTo: nil)
    return data.base64EncodedString()
  }
}
