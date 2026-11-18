/// Exception thrown when a cryptographic input is invalid, such as a
/// private key outside the secp256k1 range or a public key that is not
/// a point on the curve.
///
/// Why this exists: keys are the most sensitive data the SDK handles. An
/// invalid key must never be "fixed" or used anyway, because it could
/// derive a wrong address or produce signatures nobody can verify. This
/// exception stops the operation with a precise message.
///
/// Messages never include private key material.
///
/// Example:
/// ```dart
/// try {
///   VeChainKeyPair.fromPrivateKey(Uint8List(32)); // all zeros
/// } on VeChainCryptoException catch (e) {
///   print(e.message); // Invalid private key: ...
/// }
/// ```
class VeChainCryptoException implements Exception {
  /// Creates a new [VeChainCryptoException] with the given [message].
  const VeChainCryptoException(this.message);

  /// A human-readable description of what went wrong.
  final String message;

  @override
  String toString() => 'VeChainCryptoException: $message';
}
