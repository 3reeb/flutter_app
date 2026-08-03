abstract final class QLNodeState {
  static const int idle = 0;
  static const int dirty = 1 << 0;
  static const int validating = 1 << 1;
  static const int hasError = 1 << 2;
  static const int hasWarning = 1 << 3;
  static const int syncing = 1 << 4;
  static const int hardwareLocked = 1 << 5;
  static const int streaming = 1 << 6;
  static const int disabled = 1 << 7;
  static const int readOnly = 1 << 8;
  static const int sleeping = 1 << 9;
}

class QLNodeError {
  final String message;
  final int severity;
  final String? code;
  const QLNodeError(this.message, {this.severity = 2, this.code});

  @override
  String toString() => 'QLNodeError[$code]: $message (Severity: $severity)';
}

abstract final class QLFieldFlags {
  static const int none = 0;
  static const int isVirtual = 1 << 0;
  static const int isComputed = 1 << 1;
  static const int isRequired = 1 << 2;
  static const int hasMany = 1 << 3;
  static const int isUnique = 1 << 4;
  static const int isIndexed = 1 << 5;
  static const int isHidden = 1 << 6;
  static const int isReadOnly = 1 << 7;
}

abstract class QLDisposable {
  void dispose();
}

typedef QLValidator<T> = QLNodeError? Function(T value, Object graph);
typedef QLFastMiddleware<T> = T Function(T incoming, T current);
typedef QLValueTransform<T> = T Function(T incoming);
