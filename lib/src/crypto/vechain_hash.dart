import 'dart:typed_data';

import 'package:pointycastle/digests/blake2b.dart';
import 'package:pointycastle/digests/keccak.dart';

/// The two hash functions VeChainThor uses: BLAKE2b-256 and Keccak-256.
///
/// Why this exists: the VeChainThor node defines exactly these two hash
/// functions, both with a 32-byte output, and each one has a distinct
/// role:
///
/// - **BLAKE2b-256**: transaction signing hashes, transaction IDs, block
///   IDs, and the hash a fee delegator signs (VIP-191).
/// - **Keccak-256**: address derivation from a public key (the same as
///   Ethereum) and ABI encoding for smart contracts.
///
/// Keccak-256 here is the original ("legacy") Keccak used by Ethereum,
/// not the standardized SHA3-256. They differ only in padding, but
/// produce completely different hashes; using SHA3-256 by mistake would
/// derive wrong addresses.
///
/// Like the node, each function accepts either a single input or several
/// parts that are hashed as if they were concatenated. The node uses the
/// multi-part form, for example, to compute a transaction ID from its
/// signing hash and its sender address.
///
/// Example:
/// ```dart
/// final data = Uint8List.fromList(utf8.encode('VeChainThor'));
/// final id = VeChainHash.blake2b256(data);
/// print(id.length); // 32
///
/// // Hashing parts gives the same result as hashing them joined.
/// final a = Uint8List.fromList([1, 2]);
/// final b = Uint8List.fromList([3]);
/// final joined = VeChainHash.keccak256(Uint8List.fromList([1, 2, 3]));
/// final parts = VeChainHash.keccak256Concat([a, b]);
/// // joined and parts contain the same 32 bytes.
/// ```
///
/// See: https://github.com/vechain/thor/blob/master/thor/hash.go
class VeChainHash {
  const VeChainHash._();

  /// The length, in bytes, of every hash produced by this class.
  static const int hashLength = 32;

  /// Computes the BLAKE2b-256 hash of [data].
  ///
  /// Example:
  /// ```dart
  /// final hash = VeChainHash.blake2b256(Uint8List(0));
  /// print(VeChainHex.encode(hash));
  /// // 0x0e5751c026e543b2e8ab2eb06099daa1d1e5df47778f7787faab45cdf12fe3a8
  /// ```
  static Uint8List blake2b256(Uint8List data) => blake2b256Concat([data]);

  /// Computes the BLAKE2b-256 hash of all [parts], as if they were
  /// concatenated in order.
  ///
  /// An empty list hashes an empty input.
  ///
  /// Example:
  /// ```dart
  /// final txId = VeChainHash.blake2b256Concat([signingHash, origin]);
  /// ```
  static Uint8List blake2b256Concat(List<Uint8List> parts) {
    // The digest size must be set to 32: the pointycastle default is 64.
    final digest = Blake2bDigest(digestSize: hashLength);
    for (final part in parts) {
      digest.update(part, 0, part.length);
    }
    final output = Uint8List(hashLength);
    digest.doFinal(output, 0);
    return output;
  }

  /// Computes the Keccak-256 hash of [data].
  ///
  /// Example:
  /// ```dart
  /// final hash = VeChainHash.keccak256(Uint8List(0));
  /// print(VeChainHex.encode(hash));
  /// // 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470
  /// ```
  static Uint8List keccak256(Uint8List data) => keccak256Concat([data]);

  /// Computes the Keccak-256 hash of all [parts], as if they were
  /// concatenated in order.
  ///
  /// An empty list hashes an empty input.
  ///
  /// Example:
  /// ```dart
  /// final hash = VeChainHash.keccak256Concat([prefix, payload]);
  /// ```
  static Uint8List keccak256Concat(List<Uint8List> parts) {
    // KeccakDigest is the legacy Keccak used by Ethereum, not SHA3Digest.
    final digest = KeccakDigest(256);
    for (final part in parts) {
      digest.update(part, 0, part.length);
    }
    final output = Uint8List(hashLength);
    digest.doFinal(output, 0);
    return output;
  }
}
