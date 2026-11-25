import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/signers/ecdsa_signer.dart';
import 'package:vechain_flutter_sdk/src/exceptions/vechain_crypto_exception.dart';

/// Internal secp256k1 operations shared by keys, addresses and
/// signatures.
///
/// Why this exists: VeChainThor accounts use the secp256k1 elliptic
/// curve, the same as Ethereum. Key pairs, address derivation and
/// signatures all need to validate private keys, derive public keys,
/// compress and decompress points, sign hashes and recover the signer's
/// public key. Keeping those operations here gives them one strict
/// implementation.
///
/// Design decisions:
///
/// - Public keys are decoded and validated explicitly instead of with
///   pointycastle's `decodePoint`, which does not check that an
///   uncompressed point is on the curve, accepts encodings VeChain never
///   uses (`0x00`, `0x06`, `0x07`), and signals an invalid compressed
///   point by throwing an `Error`.
/// - Signatures use RFC 6979 (a deterministic nonce derived with
///   HMAC-SHA256) and are always normalized to a low S, because the
///   VeChainThor transaction pool rejects signatures with a high S.
/// - pointycastle does not compute the recovery byte or recover public
///   keys, so both are implemented here (SEC 1, section 4.1.6).
///
/// This class is internal to the SDK and not exported. Use
/// `VeChainKeyPair`, `VeChainAddress` and `VeChainSignature` instead.
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

  /// Length of a message hash that can be signed, in bytes.
  static const int hashLength = 32;

  /// Length of a signature (r + s + recovery), in bytes.
  static const int signatureLength = 65;

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
  /// is an integer in the range `[1, n - 1]`.
  static BigInt get order => _domain.n;

  /// Half the curve order, n / 2: the largest S a low-S signature can
  /// have.
  static BigInt get halfOrder => order >> 1;

  /// Whether [privateKey] is 32 bytes and in the range `[1, n - 1]`.
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
    if (!isValidPrivateKey(privateKey)) throw _invalidPrivateKey();

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

  /// Validates [publicKey] (compressed or uncompressed) and returns it
  /// in compressed form (33 bytes): `0x02` or `0x03` + X.
  ///
  /// Throws a [VeChainCryptoException] if [publicKey] is not a valid
  /// secp256k1 public key.
  static Uint8List compressPublicKey(Uint8List publicKey) {
    // Validate first; this also inflates a compressed input.
    final uncompressed = decodePublicKey(publicKey);

    // The prefix encodes the parity of Y: 0x02 if even, 0x03 if odd.
    return Uint8List.fromList([
      if (uncompressed.last.isOdd) 0x03 else 0x02,
      ...uncompressed.sublist(1, 1 + _coordinateLength),
    ]);
  }

  /// Signs a 32-byte [hash] with [privateKey], returning 65 bytes:
  /// r (32) + s (32) + recovery (1, either 0 or 1).
  ///
  /// The signature is deterministic (RFC 6979) and always has a low S.
  ///
  /// Throws a [VeChainCryptoException] if [hash] is not 32 bytes or
  /// [privateKey] is invalid.
  static Uint8List sign(Uint8List hash, Uint8List privateKey) {
    _requireHash(hash);
    if (!isValidPrivateKey(privateKey)) throw _invalidPrivateKey();

    // RFC 6979: the nonce k is derived from the key and the hash with
    // HMAC-SHA256; the null digest means the hash is signed as given.
    final signer = ECDSASigner(null, HMac(SHA256Digest(), 64))
      ..init(
        true,
        PrivateKeyParameter<ECPrivateKey>(
          ECPrivateKey(bytesToBigInt(privateKey), _domain),
        ),
      );
    final raw = signer.generateSignature(hash) as ECSignature;

    // The transaction pool rejects a high S, so always use n - s then.
    final signature = raw.normalize(_domain);

    // The recovery byte is whichever of 0 or 1 gives back our own key.
    final publicKey = derivePublicKey(privateKey);
    for (var recovery = 0; recovery < 2; recovery++) {
      final candidate = _recover(hash, signature.r, signature.s, recovery);
      if (candidate != null && _bytesEqual(candidate, publicKey)) {
        return Uint8List.fromList([
          ...bigIntToBytes(signature.r, _coordinateLength),
          ...bigIntToBytes(signature.s, _coordinateLength),
          recovery,
        ]);
      }
    }

    // Recovery ids 2 and 3 need r >= n, with odds of about 2^-128.
    throw const VeChainCryptoException(
      'Signing failed: no recovery byte of 0 or 1 matches the signer.',
    );
  }

  /// Recovers the 65-byte uncompressed public key that produced
  /// [signature] (r + s + recovery) over the 32-byte [hash].
  ///
  /// Throws a [VeChainCryptoException] if [hash] is not 32 bytes, if the
  /// signature is malformed, or if no public key can be recovered.
  static Uint8List recoverPublicKey(Uint8List hash, Uint8List signature) {
    _requireHash(hash);

    // Check the layout: 65 bytes, r and s in range, recovery 0 or 1.
    if (signature.length != signatureLength) {
      throw VeChainCryptoException(
        'Invalid signature: expected $signatureLength bytes, got '
        '${signature.length}.',
      );
    }
    final r = bytesToBigInt(signature.sublist(0, 32));
    final s = bytesToBigInt(signature.sublist(32, 64));
    final recovery = signature[64];
    if (!_isInOrderRange(r) || !_isInOrderRange(s)) {
      throw const VeChainCryptoException(
        'Invalid signature: r and s must be between 1 and the secp256k1 '
        'curve order minus 1.',
      );
    }
    if (recovery != 0 && recovery != 1) {
      throw VeChainCryptoException(
        'Invalid signature: the recovery byte must be 0 or 1, got '
        '$recovery.',
      );
    }

    final publicKey = _recover(hash, r, s, recovery);
    if (publicKey == null) {
      throw const VeChainCryptoException(
        'Invalid signature: no public key can be recovered from it.',
      );
    }
    return publicKey;
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

  /// Recovers the uncompressed public key for (r, s, recovery) over
  /// [hash], or returns null if there is none (SEC 1, section 4.1.6).
  static Uint8List? _recover(
    Uint8List hash,
    BigInt r,
    BigInt s,
    int recovery,
  ) {
    // R is the point with X = r; the recovery byte is the parity of Y.
    Uint8List rUncompressed;
    try {
      rUncompressed = decodePublicKey(
        Uint8List.fromList([
          if (recovery == 1) 0x03 else 0x02,
          ...bigIntToBytes(r, _coordinateLength),
        ]),
      );
    } on VeChainCryptoException {
      return null;
    }
    final rPoint = _domain.curve.decodePoint(rUncompressed)!;

    // Q = r^-1 (s R - e G), computed as u1 G + u2 R.
    final e = bytesToBigInt(hash) % order;
    final rInverse = r.modInverse(order);
    final u1 = ((order - e) * rInverse) % order;
    final u2 = (s * rInverse) % order;
    final q = (_domain.G * u1)! + (rPoint * u2);

    if (q == null || q.isInfinity) return null;
    return q.getEncoded(false);
  }

  /// Throws unless [hash] is exactly 32 bytes.
  static void _requireHash(Uint8List hash) {
    if (hash.length != hashLength) {
      throw VeChainCryptoException(
        'Invalid hash: expected $hashLength bytes, got ${hash.length}.',
      );
    }
  }

  /// Whether [value] is in the range `[1, n - 1]`.
  static bool _isInOrderRange(BigInt value) =>
      value > BigInt.zero && value < order;

  /// Whether (x, y) satisfies the secp256k1 equation y^2 = x^3 + 7.
  static bool _isOnCurve(BigInt x, BigInt y) {
    if (x >= _fieldPrime || y >= _fieldPrime) return false;
    final left = (y * y) % _fieldPrime;
    final right =
        (x.modPow(BigInt.from(3), _fieldPrime) + _curveB) % _fieldPrime;
    return left == right;
  }

  /// Whether [a] and [b] contain the same bytes.
  static bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// The exception for a private key that is out of range.
  static VeChainCryptoException _invalidPrivateKey() =>
      const VeChainCryptoException(
        'Invalid private key: expected 32 bytes representing an integer '
        'between 1 and the secp256k1 curve order minus 1.',
      );

  /// The exception for a public key that is not a valid curve point.
  static VeChainCryptoException _notOnCurve() => const VeChainCryptoException(
        'Invalid public key: the point is not on the secp256k1 curve.',
      );
}
