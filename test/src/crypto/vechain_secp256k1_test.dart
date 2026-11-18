import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vechain_flutter_sdk/src/crypto/vechain_secp256k1.dart';
import 'package:vechain_flutter_sdk/vechain_flutter_sdk.dart';

// ---- Official vectors (vechain-sdk-js Address and Secp256k1 tests) ----

const _privateKeyA =
    '0x5434c159b817c377a55f6be66369622976014e78bce2adfd3e44e5de88ce502f';
const _publicKeyA =
    '0x04a6711e14234b1d4e69aeed2acf18b9c3bd0e97db317b509516bd3a87e5b732685ccaf855d9f8a955bc1f420b4ebf8f682c2e480d98a360e7fd0c08e6eef65607';

const _privateKeyB =
    '0x7582be841ca040aa940fff6c05773129e135623e41acce3e0b8ba520dc1ae26a';
const _publicKeyB =
    '0x04b90e9bb2617387eba4502c730de65a33878ef384a46f1096d86f2da19043304afa67d0ad09cf2bea0c6f2d1767a9e62a7a7ecc41facf18f2fa505d92243a658f';
const _compressedPublicKeyB =
    '0x03b90e9bb2617387eba4502c730de65a33878ef384a46f1096d86f2da19043304a';

// ---- Independently computed vectors ----

/// Compressed form of [_publicKeyA] (odd Y, prefix 0x03).
const _compressedPublicKeyA =
    '0x03a6711e14234b1d4e69aeed2acf18b9c3bd0e97db317b509516bd3a87e5b73268';

/// The generator point G (private key 1), whose Y is even.
const _generator =
    '0x0479be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8';
const _compressedGenerator =
    '0x0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';

/// The secp256k1 order n: one past the largest valid private key.
const _order =
    '0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141';

/// Decodes a hex constant into bytes.
Uint8List _hex(String hex) => VeChainHex.decode(hex);

/// A 32-byte private key holding the integer [value].
Uint8List _key(int value) =>
    VeChainSecp256k1.bigIntToBytes(BigInt.from(value), 32);

/// Matches a [VeChainCryptoException] whose message contains [text].
Matcher _throwsCryptoException(String text) => throwsA(
      isA<VeChainCryptoException>().having(
        (e) => e.message,
        'message',
        contains(text),
      ),
    );

void main() {
  group('VeChainSecp256k1.isValidPrivateKey', () {
    test('accepts the official valid keys', () {
      expect(VeChainSecp256k1.isValidPrivateKey(_hex(_privateKeyA)), isTrue);
      expect(VeChainSecp256k1.isValidPrivateKey(_hex(_privateKeyB)), isTrue);
    });

    test('accepts the range limits 1 and n - 1', () {
      final orderMinusOne = VeChainSecp256k1.bigIntToBytes(
        VeChainSecp256k1.order - BigInt.one,
        32,
      );

      expect(VeChainSecp256k1.isValidPrivateKey(_key(1)), isTrue);
      expect(VeChainSecp256k1.isValidPrivateKey(orderMinusOne), isTrue);
    });

    test('rejects zero', () {
      expect(VeChainSecp256k1.isValidPrivateKey(Uint8List(32)), isFalse);
    });

    test('rejects the curve order n', () {
      expect(VeChainSecp256k1.isValidPrivateKey(_hex(_order)), isFalse);
    });

    test('rejects the official invalid key (all 0xff)', () {
      final allOnes = Uint8List(32)..fillRange(0, 32, 0xff);

      expect(VeChainSecp256k1.isValidPrivateKey(allOnes), isFalse);
    });

    test('rejects keys that are not 32 bytes', () {
      expect(VeChainSecp256k1.isValidPrivateKey(Uint8List(31)), isFalse);
      expect(VeChainSecp256k1.isValidPrivateKey(Uint8List(33)), isFalse);
    });
  });

  group('VeChainSecp256k1.derivePublicKey', () {
    test('derives the official uncompressed public keys', () {
      final a = VeChainSecp256k1.derivePublicKey(_hex(_privateKeyA));
      final b = VeChainSecp256k1.derivePublicKey(_hex(_privateKeyB));

      expect(VeChainHex.encode(a), _publicKeyA);
      expect(VeChainHex.encode(b), _publicKeyB);
    });

    test('derives the official compressed public key', () {
      final b = VeChainSecp256k1.derivePublicKey(
        _hex(_privateKeyB),
        compressed: true,
      );

      expect(VeChainHex.encode(b), _compressedPublicKeyB);
    });

    test('private key 1 derives the generator point', () {
      final g = VeChainSecp256k1.derivePublicKey(_key(1));

      expect(VeChainHex.encode(g), _generator);
    });

    test('throws on an invalid private key', () {
      expect(
        () => VeChainSecp256k1.derivePublicKey(Uint8List(32)),
        _throwsCryptoException('Invalid private key'),
      );
    });
  });

  group('VeChainSecp256k1.decodePublicKey', () {
    test('returns a valid uncompressed key unchanged', () {
      final decoded = VeChainSecp256k1.decodePublicKey(_hex(_publicKeyA));

      expect(VeChainHex.encode(decoded), _publicKeyA);
    });

    test('inflates a compressed key with an odd Y (0x03)', () {
      final a = VeChainSecp256k1.decodePublicKey(_hex(_compressedPublicKeyA));
      final b = VeChainSecp256k1.decodePublicKey(_hex(_compressedPublicKeyB));

      expect(VeChainHex.encode(a), _publicKeyA);
      expect(VeChainHex.encode(b), _publicKeyB);
    });

    test('inflates a compressed key with an even Y (0x02)', () {
      final g = VeChainSecp256k1.decodePublicKey(_hex(_compressedGenerator));

      expect(VeChainHex.encode(g), _generator);
    });

    test('throws on an empty key', () {
      expect(
        () => VeChainSecp256k1.decodePublicKey(Uint8List(0)),
        _throwsCryptoException('got 0 bytes'),
      );
    });

    test('throws on the official invalid example [1, 2, 3, 4, 5]', () {
      expect(
        () => VeChainSecp256k1.decodePublicKey(
          Uint8List.fromList([1, 2, 3, 4, 5]),
        ),
        _throwsCryptoException('expected 33 bytes'),
      );
    });

    test('throws when the prefix does not match the length', () {
      final wrongPrefix = _hex(_publicKeyA)..[0] = 0x02;

      expect(
        () => VeChainSecp256k1.decodePublicKey(wrongPrefix),
        _throwsCryptoException('expected 33 bytes'),
      );
    });

    test('throws on a hybrid encoding (0x06)', () {
      final hybrid = _hex(_publicKeyA)..[0] = 0x06;

      expect(
        () => VeChainSecp256k1.decodePublicKey(hybrid),
        _throwsCryptoException('expected 33 bytes'),
      );
    });

    test('throws on an uncompressed point that is not on the curve', () {
      final tampered = _hex(_publicKeyA)..[64] ^= 0x01;

      expect(
        () => VeChainSecp256k1.decodePublicKey(tampered),
        _throwsCryptoException('not on the secp256k1 curve'),
      );
    });

    test('throws on a compressed X that has no point (x = 5)', () {
      final noPoint = Uint8List(33)
        ..[0] = 0x02
        ..[32] = 5;

      expect(
        () => VeChainSecp256k1.decodePublicKey(noPoint),
        _throwsCryptoException('not on the secp256k1 curve'),
      );
    });

    test('throws on a compressed X outside the field', () {
      final outside = Uint8List(33)..fillRange(1, 33, 0xff);
      outside[0] = 0x02;

      expect(
        () => VeChainSecp256k1.decodePublicKey(outside),
        _throwsCryptoException('not on the secp256k1 curve'),
      );
    });
  });

  group('VeChainSecp256k1 byte conversions', () {
    test('bigIntToBytes pads with leading zeros', () {
      final bytes = VeChainSecp256k1.bigIntToBytes(BigInt.one, 32);

      expect(bytes.length, 32);
      expect(bytes.sublist(0, 31), everyElement(0));
      expect(bytes[31], 1);
    });

    test('bytesToBigInt and bigIntToBytes round-trip', () {
      final key = _hex(_privateKeyA);
      final value = VeChainSecp256k1.bytesToBigInt(key);

      expect(VeChainSecp256k1.bigIntToBytes(value, 32), key);
    });
  });
}
