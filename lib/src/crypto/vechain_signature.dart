import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:vechain_flutter_sdk/src/address/vechain_address.dart';
import 'package:vechain_flutter_sdk/src/codec/vechain_hex.dart';
import 'package:vechain_flutter_sdk/src/crypto/vechain_secp256k1.dart';
import 'package:vechain_flutter_sdk/src/exceptions/vechain_crypto_exception.dart';

/// A secp256k1 signature as VeChainThor uses it: 65 bytes made of r
/// (32), s (32) and a recovery byte (0 or 1).
///
/// Why this exists: a VeChainThor transaction does not carry the
/// sender's public key. The node recovers it from the signature and the
/// signed hash, and from it derives the sender's address. The same
/// mechanism identifies the gas payer under fee delegation (VIP-191)
/// and the signer of a certificate (VIP-192). This class holds a
/// validated signature and performs that recovery.
///
/// Design decisions:
///
/// - The recovery byte is 0 or 1, as in the official VeChain SDK, not
///   27 or 28 as in Ethereum transactions.
/// - [VeChainSignature.fromBytes] rejects a high S (greater than n / 2),
///   because the VeChainThor transaction pool rejects such signatures
///   to prevent signature malleability. Signatures produced by this SDK
///   always have a low S.
///
/// Example:
/// ```dart
/// final hash = VeChainHash.keccak256(message);
/// final signature = keyPair.sign(hash);
/// print(signature.bytes.length); // 65
/// print(signature.recoverAddress(hash) == keyPair.address); // true
/// ```
///
/// See:
/// - https://github.com/vechain/vechain-sdk-js/blob/main/packages/core/src/secp256k1/Secp256k1.ts
/// - https://github.com/vechain/thor/blob/master/tx/transaction.go
@immutable
class VeChainSignature {
  const VeChainSignature._({
    required this.r,
    required this.s,
    required this.recovery,
  });

  /// Creates a signature from its 65 bytes: r (32) + s (32) + recovery
  /// (1).
  ///
  /// Throws a [VeChainCryptoException] if the length is not 65, if r or
  /// s is outside [1, n - 1], if s is greater than n / 2, or if the
  /// recovery byte is not 0 or 1.
  ///
  /// Example:
  /// ```dart
  /// final signature = VeChainSignature.fromBytes(
  ///   VeChainHex.decode('0xf8fe82c7...6b934d7200'),
  /// );
  /// ```
  factory VeChainSignature.fromBytes(Uint8List bytes) {
    // Check the layout before reading any field.
    if (bytes.length != length) {
      throw VeChainCryptoException(
        'Invalid signature: expected $length bytes, got ${bytes.length}.',
      );
    }
    final r = VeChainSecp256k1.bytesToBigInt(bytes.sublist(0, 32));
    final s = VeChainSecp256k1.bytesToBigInt(bytes.sublist(32, 64));
    final recovery = bytes[64];

    // r and s must be valid scalars of the curve.
    final order = VeChainSecp256k1.order;
    if (r <= BigInt.zero || r >= order || s <= BigInt.zero || s >= order) {
      throw const VeChainCryptoException(
        'Invalid signature: r and s must be between 1 and the secp256k1 '
        'curve order minus 1.',
      );
    }

    // The node rejects a high S, so it is never accepted here either.
    if (s > VeChainSecp256k1.halfOrder) {
      throw const VeChainCryptoException(
        'Invalid signature: s is greater than half the curve order. '
        'VeChainThor only accepts low-S signatures.',
      );
    }

    if (recovery != 0 && recovery != 1) {
      throw VeChainCryptoException(
        'Invalid signature: the recovery byte must be 0 or 1, got '
        '$recovery.',
      );
    }
    return VeChainSignature._(r: r, s: s, recovery: recovery);
  }

  /// Length of a signature, in bytes.
  static const int length = 65;

  /// The r value of the signature.
  final BigInt r;

  /// The s value of the signature, always at most n / 2.
  final BigInt s;

  /// The recovery byte, 0 or 1: the parity of the Y coordinate of the
  /// point R, used to recover the signer's public key.
  final int recovery;

  /// The 65 bytes of this signature: r (32) + s (32) + recovery (1).
  Uint8List get bytes => Uint8List.fromList([
        ...VeChainSecp256k1.bigIntToBytes(r, 32),
        ...VeChainSecp256k1.bigIntToBytes(s, 32),
        recovery,
      ]);

  /// Recovers the 65-byte uncompressed public key of the signer of the
  /// 32-byte [hash].
  ///
  /// Throws a [VeChainCryptoException] if [hash] is not 32 bytes or no
  /// public key can be recovered.
  Uint8List recoverPublicKey(Uint8List hash) =>
      VeChainSecp256k1.recoverPublicKey(hash, bytes);

  /// Recovers the address of the signer of the 32-byte [hash].
  ///
  /// Example:
  /// ```dart
  /// final signer = signature.recoverAddress(hash);
  /// print(signer == keyPair.address); // true
  /// ```
  VeChainAddress recoverAddress(Uint8List hash) =>
      VeChainAddress.fromPublicKey(recoverPublicKey(hash));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VeChainSignature &&
          other.r == r &&
          other.s == s &&
          other.recovery == recovery;

  @override
  int get hashCode => Object.hash(r, s, recovery);

  /// The signature as `0x` plus 130 hex digits.
  @override
  String toString() => VeChainHex.encode(bytes);
}
