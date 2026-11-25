/// Exception thrown when an HD wallet operation is invalid: a malformed
/// derivation path, a wrong seed or chain code length, a child index
/// out of range, or an operation that needs a private key on a
/// watch-only key.
///
/// Why this exists: HD derivation turns one seed into every account of a
/// wallet. A mistake here, such as a malformed path silently read as a
/// different one, would derive different, empty accounts. This exception
/// stops the operation with a precise message instead.
///
/// Messages never include key material, chain codes or seeds.
///
/// Example:
/// ```dart
/// try {
///   hdKey.derive('m/0/1/4/2/4/h');
/// } on VeChainHDKeyException catch (e) {
///   print(e.message); // Invalid derivation path ...
/// }
/// ```
class VeChainHDKeyException implements Exception {
  /// Creates a new [VeChainHDKeyException] with the given [message].
  const VeChainHDKeyException(this.message);

  /// A human-readable description of what went wrong.
  final String message;

  @override
  String toString() => 'VeChainHDKeyException: $message';
}
