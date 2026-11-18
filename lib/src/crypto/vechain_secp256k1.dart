import 'dart:typed_data';

import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';
import 'package:vechain_flutter_sdk/src/exceptions/vechain_crypto_exception.dart';

/// Internal secp256k1 operations shared by keys and addresses.
///
/// Why this exists: VeChainThor accounts use the secp256k1 elliptic
/// curve, the same as Ethereum. Both key pairs and address derivation
/// need to validate private keys, derive public keys, and turn a
/// compressed public key back into its full form. Keeping those
/// operations here gives them one strict implementation.
///
/// Design decision: public keys are decoded and validated explicitly
/// instead of with pointycastle's `decodePoint`, which does not check
/// that an uncompressed point is on the curve, accepts encodings VeChain
/// never uses (`0x00`, `0x06`, `0x07`), and signals an invalid
/// compressed point by throwing an `Error`. This class only accepts
/// `0x02`/`0x03` (33 bytes) or `0x04` (65 bytes), checks the curve
/// equation, and decompresses points itself.
///
/// This class is internal to the SDK and not exported. Use
/// `VeChainKeyPair` and `VeChainAddress` instead.
///
/// Example:
/// ```dart
/// final publicKey = VeChainSecp256k1.derivePublicKey(privateKey);
/// print(publicKey.length); // 65
/// ```
///
/// See: https://github.com/vechain/vechain-sdk-js/blob/main/packages/core/src/secp256k1/Secp256k1.ts
class VeChainSecp256k1 {
  const VeChainSecp256k1._();

  /// Length of a private key, in bytes.
  static const int privateKeyLength = 32;

  /// Length of a compressed public key (`0x02` or `0x03` + X), in bytes.
  static const int compressedPublicKeyLength = 33;

  /// Length of an uncompressed public key (`0x04` + X + Y), in bytes.
  static const int uncompressedPublicKeyLength = 65;

  /// Length of one curve coordinate (X or Y), in bytes.
  static const int _coordinateLength = 32;

  /// The secp256k1 domain parameters (curve, generator, order).
  static final ECDomainParameters _domain = ECCurve_secp256k1();

  /// The secp256k1 field prime p = 2^256 - 2^32 - 977.
  static final BigInt _fieldPrime = BigInt.parse(
    'fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f',
    radix: 16,
  );

  /// The constant b of the secp256k1 equation y^2 = x^3 + b.
  static final BigInt _curveB = BigInt.from(7);

  /// The order n of the secp256k1 generator point. A valid private key
  /// is an integer in the range [1, n - 1].
  static BigInt get order => _domain.n;

  /// Whether [privateKey] is 32 bytes and in the range [1, n - 1].
  static bool isValidPrivateKey(Uint8List privateKey) {
    if (privateKey.length != privateKeyLength) return false;
    final value = bytesToBigInt(privateKey);
    return value > BigInt.zero && value < order;
  }

  /// Derives the public key for [privateKey]: 65 bytes uncompressed by
  /// default, or 33 bytes when [compressed] is true.
  ///
  /// Throws a [VeChainCryptoException] if [privateKey] is invalid.
  static Uint8List derivePublicKey(
    Uint8List privateKey, {
    bool compressed = false,
  }) {
    // Never derive anything from an out-of-range key.
    if (!isValidPrivateKey(privateKey)) {
      throw const VeChainCryptoException(
        'Invalid private key: expected 32 bytes representing an integer '
        'between 1 and the secp256k1 curve order minus 1.',
      );
    }

    // The public key is the generator point multiplied by the key.
    final point = (_domain.G * bytesToBigInt(privateKey))!;
    return point.getEncoded(compressed);
  }

  /// Validates [publicKey] (compressed or uncompressed) and returns it
  /// in uncompressed form (65 bytes, starting with `0x04`).
  ///
  /// Throws a [VeChainCryptoException] if the encoding is not one
  /// VeChain uses, or if the point is not on the secp256k1 curve.
  static Uint8List decodePublicKey(Uint8List publicKey) {
    // Accept only the two encodings VeChain uses, with matching length.
    final prefix = publicKey.isEmpty ? -1 : publicKey[0];
    final isCompressed = (prefix == 0x02 || prefix == 0x03) &&
        publicKey.length == compressedPublicKeyLength;
    final isUncompressed =
        prefix == 0x04 && publicKey.length == uncompressedPublicKeyLength;
    if (!isCompressed && !isUncompressed) {
      throw VeChainCryptoException(
        'Invalid public key: expected 33 bytes starting with 0x02 or '
        '0x03, or 65 bytes starting with 0x04; got ${publicKey.length} '
        'bytes.',
      );
    }

    // An uncompressed key must satisfy the curve equation as given.
    final x = bytesToBigInt(publicKey.sublist(1, 1 + _coordinateLength));
    if (isUncompressed) {
      final y = bytesToBigInt(publicKey.sublist(1 + _coordinateLength));
      if (!_isOnCurve(x, y)) throw _notOnCurve();
      return Uint8List.fromList(publicKey);
    }

    // A compressed key is rebuilt from X: y = sqrt(x^3 + 7) mod p.
    if (x >= _fieldPrime) throw _notOnCurve();
    final rightSide =
        (x.modPow(BigInt.from(3), _fieldPrime) + _curveB) % _fieldPrime;

    // Since p = 3 (mod 4), the square root is one modular power.
    final exponent = (_fieldPrime + BigInt.one) >> 2;
    var y = rightSide.modPow(exponent, _fieldPrime);

    // Not every X has a point: the root must square back exactly.
    if ((y * y) % _fieldPrime != rightSide) throw _notOnCurve();

    // The prefix picks the root: 0x02 for an even Y, 0x03 for an odd Y.
    final wantsOddY = prefix == 0x03;
    if (y.isOdd != wantsOddY) y = _fieldPrime - y;

    return Uint8List.fromList([
      0x04,
      ...bigIntToBytes(x, _coordinateLength),
      ...bigIntToBytes(y, _coordinateLength),
    ]);
  }

  /// Converts big-endian [bytes] to a non-negative [BigInt].
  static BigInt bytesToBigInt(Uint8List bytes) {
    var result = BigInt.zero;
    for (final byte in bytes) {
      result = (result << 8) | BigInt.from(byte);
    }
    return result;
  }

  /// Converts a non-negative [value] to exactly [length] big-endian
  /// bytes, padding with leading zeros.
  static Uint8List bigIntToBytes(BigInt value, int length) {
    final result = Uint8List(length);
    var remaining = value;
    // Fill from the last byte backwards, 8 bits at a time.
    for (var i = length - 1; i >= 0; i--) {
      result[i] = (remaining & BigInt.from(0xff)).toInt();
      remaining = remaining >> 8;
    }
    return result;
  }

  /// Whether (x, y) satisfies the secp256k1 equation y^2 = x^3 + 7.
  static bool _isOnCurve(BigInt x, BigInt y) {
    if (x >= _fieldPrime || y >= _fieldPrime) return false;
    final left = (y * y) % _fieldPrime;
    final right =
        (x.modPow(BigInt.from(3), _fieldPrime) + _curveB) % _fieldPrime;
    return left == right;
  }

  /// The exception for a public key that is not a valid curve point.
  static VeChainCryptoException _notOnCurve() => const VeChainCryptoException(
        'Invalid public key: the point is not on the secp256k1 curve.',
      );
}
