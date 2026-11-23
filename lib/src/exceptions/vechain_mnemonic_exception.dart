/// Exception thrown when a mnemonic, its entropy, its word count, or a
/// passphrase is invalid.
///
/// Why this exists: a mnemonic is the master secret of every account
/// derived from it. A mistyped word, a swapped word, or a wrong length
/// must be rejected with a clear message, never "repaired" into a
/// different mnemonic that would open different, empty accounts.
///
/// Messages never include the words themselves: an invalid word is
/// identified only by its position.
///
/// Example:
/// ```dart
/// try {
///   VeChainMnemonic.parse('abandon abandon ...');
/// } on VeChainMnemonicException catch (e) {
///   print(e.message); // Invalid mnemonic: ...
/// }
/// ```
class VeChainMnemonicException implements Exception {
  /// Creates a new [VeChainMnemonicException] with the given [message].
  const VeChainMnemonicException(this.message);

  /// A human-readable description of what went wrong.
  final String message;

  @override
  String toString() => 'VeChainMnemonicException: $message';
}
