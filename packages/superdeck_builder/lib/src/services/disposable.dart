/// An interface for objects that can be disposed.
abstract class Disposable {
  /// Dispose of any resources.
  Future<void> dispose();
}
