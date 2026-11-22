import 'dart:math';
import 'dart:typed_data';

import 'package:vechain_flutter_sdk/src/address/vechain_address.dart';
import 'package:vechain_flutter_sdk/src/crypto/vechain_secp256k1.dart';
import 'package:vechain_flutter_sdk/src/crypto/vechain_signature.dart';
import 'package:vechain_flutter_sdk/src/exceptions/vechain_crypto_exception.dart';

/// A secp256k1 key pair for a VeChainThor account: a private key, its
/// public key in both formats, and the account address.
///
/// Why this exists: every VeChainThor account is controlled by a
/// secp256k1 private key. From it come the public key (used to verify
/// signatures) and the address (where the account receives funds).
/// This class bundles the three, validated once at creation, so the rest
/// of the SDK never handles an unchecked key. It also signs hashes, so
/// the private key never has to leave it.
///
/// Design decisions:
///
/// - Keys are generated with `Random.secure()` from `dart:math`, which
///   works the same on every platform, and any value outside the valid
///   range [1, n - 1] is discarded and drawn again.
/// - Getters return copies, so callers cannot modify the stored keys.
/// - [toString] shows only the address, never the private key, so a key
///   pair printed in a log does not leak its secret.
///
/// Example:
/// ```dart
/// final keyPair = VeChainKeyPair.generate();
/// print(keyPair.address); // 0x... (EIP-55 checksum)
/// print(keyPair.publicKey.length); // 65
///
/// final restored = VeChainKeyPair.fromPrivateKey(keyPair.privateKey);
/// print(restored.address == keyPair.address); // true
/// ```
///
/// See: https://github.com/vechain/vechain-sdk-js/blob/main/packages/core/src/secp256k1/Secp256k1.ts
class VeChainKeyPair {
  VeChainKeyPair._({
    required Uint8List privateKey,
    required Uint8List publicKey,
    required Uint8List compressedPublicKey,
    required this.address,
  })  : _privateKey = privateKey,
        _publicKey = publicKey,
        _compressedPublicKey = compressedPublicKey;

  /// Creates a key pair from an existing 32-byte [privateKey].
  ///
  /// Throws a [VeChainCryptoException] if [privateKey] is not 32 bytes or
  /// is outside the range [1, n - 1], where n is the secp256k1 order.
  ///
  /// Example:
  /// ```dart
  /// final keyPair = VeChainKeyPair.fromPrivateKey(
  ///   VeChainHex.decode(
  ///     '0x5434c159b817c377a55f6be66369622976014e78bce2adfd3e44e5de88ce502f',
  ///   ),
  /// );
  /// print(keyPair.address); // 0x769E8AA372c8309c834EA6749B88861FF73581FF
  /// ```
  factory VeChainKeyPair.fromPrivateKey(Uint8List privateKey) {
    // Copy first, so later changes to the caller's list cannot alter it.
    final key = Uint8List.fromList(privateKey);

    // Validates the key and runs the one expensive curve multiplication.
    final publicKey = VeChainSecp256k1.derivePublicKey(key);

    return VeChainKeyPair._(
      privateKey: key,
      publicKey: publicKey,
      compressedPublicKey: _compress(publicKey),
      address: VeChainAddress.fromPublicKey(publicKey),
    );
  }

  /// Generates a new key pair from a cryptographically secure random
  /// source.
  ///
  /// Example:
  /// ```dart
  /// final keyPair = VeChainKeyPair.generate();
  /// ```
  factory VeChainKeyPair.generate() {
    final random = Random.secure();
    Uint8List candidate;

    // Draw 32 random bytes until they form a key in [1, n - 1].
    do {
      candidate = Uint8List.fromList(
        List<int>.generate(
          VeChainSecp256k1.privateKeyLength,
          (_) => random.nextInt(256),
        ),
      );
    } while (!VeChainSecp256k1.isValidPrivateKey(candidate));

    return VeChainKeyPair.fromPrivateKey(candidate);
  }

  final Uint8List _privateKey;
  final Uint8List _publicKey;
  final Uint8List _compressedPublicKey;

  /// The account address derived from this key pair.
  final VeChainAddress address;

  /// The 32-byte private key (a copy).
  ///
  /// Keep it secret: anyone holding it controls the account.
  Uint8List get privateKey => Uint8List.fromList(_privateKey);

  /// The 65-byte uncompressed public key, `0x04` + X + Y (a copy).
  Uint8List get publicKey => Uint8List.fromList(_publicKey);

  /// The 33-byte compressed public key, `0x02` or `0x03` + X (a copy).
  Uint8List get compressedPublicKey => Uint8List.fromList(_compressedPublicKey);

  /// Signs a 32-byte [hash] with this key pair's private key.
  ///
  /// The signature is deterministic (RFC 6979): the same hash always
  /// gives the same signature. It always has a low S, as the VeChainThor
  /// transaction pool requires.
  ///
  /// Throws a [VeChainCryptoException] if [hash] is not 32 bytes.
  ///
  /// Example:
  /// ```dart
  /// final hash = VeChainHash.keccak256(message);
  /// final signature = keyPair.sign(hash);
  /// print(signature.recoverAddress(hash) == keyPair.address); // true
  /// ```
  VeChainSignature sign(Uint8List hash) =>
      VeChainSignature.fromBytes(VeChainSecp256k1.sign(hash, _privateKey));

  /// Shows only the address; the private key is never printed.
  @override
  String toString() => 'VeChainKeyPair(address: $address)';

  /// Compresses a 65-byte uncompressed public key to 33 bytes.
  static Uint8List _compress(Uint8List publicKey) {
    // The prefix encodes the parity of Y: 0x02 if even, 0x03 if odd.
    final isYOdd = publicKey.last.isOdd;
    return Uint8List.fromList([
      if (isYOdd) 0x03 else 0x02,
      ...publicKey.sublist(1, 33),
    ]);
  }
}
