/// Base exception for builder-related errors
abstract class BuilderException implements Exception {
  String get message;
  
  @override
  String toString() => message;
}

/// Exception for format errors in deck files
class DeckFormatException extends BuilderException {
  final String content;
  final int position;
  final String _message;
  
  DeckFormatException(this._message, this.content, this.position);
  
  @override
  String get message => 'Format error at position $position: $_message';
}
