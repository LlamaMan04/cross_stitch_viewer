/// Base class for expected domain validation and document decoding failures.
class DomainException implements Exception {
  /// Creates a domain error with a user-safe message and optional JSON path.
  const DomainException(this.message, {this.path});

  /// Explains what domain or document condition failed.
  final String message;

  /// Identifies the JSON field or model path associated with the failure.
  final String? path;

  /// Formats the message with its path when one is available.
  @override
  String toString() => path == null ? message : '$message ($path)';
}

/// Reports values that violate domain invariants.
class DocumentValidationException extends DomainException {
  /// Creates a validation failure for an invalid model value.
  const DocumentValidationException(super.message, {super.path});
}
