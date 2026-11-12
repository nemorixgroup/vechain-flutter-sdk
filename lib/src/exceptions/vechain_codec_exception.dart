/// Exception thrown when data cannot be decoded from its text
/// representation, such as a malformed hex string.
///
/// Why this exists: hex strings are how VeChainThor represents hashes,
/// addresses, signatures, and raw transactions in its APIs. A malformed
/// one (an invalid character, or a missing digit from a bad copy and
/// paste) must fail loudly with a clear message, instead of being
/// silently "repaired" into different bytes that would produce, for
/// example, a different address.
///
/// Keeping this separate from `VeChainNetworkException` lets calling
/// code tell "this text is not valid data" apart from "this network
/// definition is invalid".
///
/// Example:
/// ```dart
/// try {
///   VeChainHex.decode('0xfoe');
/// } on VeChainCodecException catch (e) {
///   print(e.message); // Invalid hex string "0xfoe": ...
/// }
/// ```
class VeChainCodecException implements Exception {
  /// Creates a new [VeChainCodecException] with the given [message].
  const VeChainCodecException(this.message);

  /// A human-readable description of what went wrong.
  final String message;

  @override
  String toString() => 'VeChainCodecException: $message';
}
