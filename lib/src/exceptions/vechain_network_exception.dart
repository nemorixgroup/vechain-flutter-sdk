/// Exception thrown when a VeChain network definition is invalid.
///
/// Why this exists: a network definition is the root of everything the
/// SDK does. Its chain tag is embedded in every transaction to prevent
/// cross-chain replay, and its node URL is where every request goes. A
/// malformed genesis ID or node URL must fail loudly at creation time,
/// with a message that says exactly what is wrong, instead of producing
/// a network that silently signs transactions for the wrong chain or
/// sends requests nowhere.
///
/// Keeping this as its own type (rather than a generic [ArgumentError])
/// lets calling code catch configuration problems specifically and tell
/// them apart from other SDK failures.
///
/// Example:
/// ```dart
/// try {
///   VeChainNetwork.custom(
///     name: 'my-node',
///     genesisId: '0x1234',
///     nodeUrl: 'https://my-node.example.com',
///   );
/// } on VeChainNetworkException catch (e) {
///   print(e.message); // Invalid genesis ID "0x1234": ...
/// }
/// ```
class VeChainNetworkException implements Exception {
  /// Creates a new [VeChainNetworkException] with the given [message].
  const VeChainNetworkException(this.message);

  /// A human-readable description of what went wrong.
  final String message;

  @override
  String toString() => 'VeChainNetworkException: $message';
}
