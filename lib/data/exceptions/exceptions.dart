class AppException implements Exception {
  final _message;
  final _prefix;

  AppException([this._message, this._prefix]);

  String toString() {
    return '$_prefix$_message';
  }
}

class InngageException extends AppException {
  InngageException([String message]) : super(message, 'Inngage api exception');
}
