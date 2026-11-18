/// Exception thrown when an address is malformed or fails its EIP-55
/// checksum.
///
/// Why this exists: an address is where funds go. A malformed address,
/// a short one, or one with a mistyped character must be rejected before
/// anything is sent to it, instead of being padded or accepted as-is.
///
/// Example:
/// ```dart
/// try {
///   VeChainAddress.parse('0xcaffee');
/// } on VeChainAddressException catch (e) {
///   print(e.message); // Invalid address "0xcaffee": ...
/// }
/// ```
class VeChainAddressException implements Exception {
  /// Creates a new [VeChainAddressException] with the given [message].
  const VeChainAddressException(this.message);

  /// A human-readable description of what went wrong.
  final String message;

  @override
  String toString() => 'VeChainAddressException: $message';
}
