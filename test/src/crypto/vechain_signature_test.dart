import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vechain_flutter_sdk/src/crypto/vechain_secp256k1.dart';
import 'package:vechain_flutter_sdk/vechain_flutter_sdk.dart';

// ---- Official vectors (vechain-sdk-js Secp256k1 tests) ----

/// keccak256('hello world'), the official signed hash.
const _hash =
    '0x47173285a8d7341e5e972fc677286384f802f8ef42a5ec5f03bbfa254cb01fad';

const _privateKeyB =
    '0x7582be841ca040aa940fff6c05773129e135623e41acce3e0b8ba520dc1ae26a';
const _publicKeyB =
    '0x04b90e9bb2617387eba4502c730de65a33878ef384a46f1096d86f2da19043304afa67d0ad09cf2bea0c6f2d1767a9e62a7a7ecc41facf18f2fa505d92243a658f';
const _signatureB =
    '0xf8fe82c74f9e1f5bf443f8a7f8eb968140f554968fdcab0a6ffe904e451c8b9244be44bccb1feb34dd20d9d8943f8c131227e55861736907b02d32c06b934d7200';

// ---- Independently computed vectors (RFC 6979, low S) ----

const _addressB = '0xd989829d88B0eD1B06eDF5C50174eCfA64F14A64';

const _privateKeyA =
    '0x5434c159b817c377a55f6be66369622976014e78bce2adfd3e44e5de88ce502f';
const _addressA = '0x769E8AA372c8309c834EA6749B88861FF73581FF';

/// Key A over the same hash: its recovery byte is 1.
const _signatureA =
    '0x275f93a46a6816357278f51c3528d75129f4eeacea8381650d2c137b8730fcd358709d52a42f921db2b2587fcc85a7683a7efa45e7e21c9c3f8bea3d7efb8a1e01';

/// The official signature with s replaced by n - s and the recovery byte
/// flipped: valid on the curve, but rejected by the transaction pool.
const _highSSignatureB =
    '0xf8fe82c74f9e1f5bf443f8a7f8eb968140f554968fdcab0a6ffe904e451c8b92bb41bb4334e014cb22df26276bc073eba886f78e4dd537340fa52bcc64a2f3cf01';

/// Decodes a hex constant into bytes.
Uint8List _hex(String hex) => VeChainHex.decode(hex);

/// Encodes [text] as UTF-8 bytes.
Uint8List _utf8(String text) => Uint8List.fromList(utf8.encode(text));

/// Builds 65 signature bytes from r, s and a recovery byte.
Uint8List _signature(BigInt r, BigInt s, int recovery) => Uint8List.fromList([
      ...VeChainSecp256k1.bigIntToBytes(r, 32),
      ...VeChainSecp256k1.bigIntToBytes(s, 32),
      recovery,
    ]);

/// Matches a [VeChainCryptoException] whose message contains [text].
Matcher _throwsCryptoException(String text) => throwsA(
      isA<VeChainCryptoException>().having(
        (e) => e.message,
        'message',
        contains(text),
      ),
    );

void main() {
  final officialR =
      VeChainSecp256k1.bytesToBigInt(_hex(_signatureB).sublist(0, 32));

  group('VeChainSecp256k1.sign', () {
    test('matches the official signature', () {
      final signature = VeChainSecp256k1.sign(_hex(_hash), _hex(_privateKeyB));

      expect(VeChainHex.encode(signature), _signatureB);
    });

    test('matches an independent vector with recovery byte 1', () {
      final signature = VeChainSecp256k1.sign(_hex(_hash), _hex(_privateKeyA));

      expect(VeChainHex.encode(signature), _signatureA);
    });

    test('is deterministic (RFC 6979)', () {
      final first = VeChainSecp256k1.sign(_hex(_hash), _hex(_privateKeyA));
      final second = VeChainSecp256k1.sign(_hex(_hash), _hex(_privateKeyA));

      expect(first, second);
    });

    test('always produces a low S that recovers the signer', () {
      final privateKey = _hex(_privateKeyB);
      final publicKey = VeChainSecp256k1.derivePublicKey(privateKey);

      for (var i = 0; i < 20; i++) {
        final hash = VeChainHash.keccak256(_utf8('message $i'));
        final signature = VeChainSecp256k1.sign(hash, privateKey);
        final s = VeChainSecp256k1.bytesToBigInt(signature.sublist(32, 64));

        expect(s <= VeChainSecp256k1.halfOrder, isTrue);
        expect(VeChainSecp256k1.recoverPublicKey(hash, signature), publicKey);
      }
    });

    test('throws on a hash that is not 32 bytes (official example)', () {
      expect(
        () => VeChainSecp256k1.sign(
          _utf8('some_invalid_stuff'),
          _hex(_privateKeyB),
        ),
        _throwsCryptoException('Invalid hash: expected 32 bytes, got 18'),
      );
    });

    test('throws on an invalid private key (official all 0xff)', () {
      final allOnes = Uint8List(32)..fillRange(0, 32, 0xff);

      expect(
        () => VeChainSecp256k1.sign(_hex(_hash), allOnes),
        _throwsCryptoException('Invalid private key'),
      );
    });
  });

  group('VeChainSecp256k1.recoverPublicKey', () {
    test('recovers the official public key', () {
      final publicKey = VeChainSecp256k1.recoverPublicKey(
        _hex(_hash),
        _hex(_signatureB),
      );

      expect(VeChainHex.encode(publicKey), _publicKeyB);
    });

    test('a high-S signature still recovers at the curve level', () {
      // The low-S rule is enforced by VeChainSignature, not by the math.
      final publicKey = VeChainSecp256k1.recoverPublicKey(
        _hex(_hash),
        _hex(_highSSignatureB),
      );

      expect(VeChainHex.encode(publicKey), _publicKeyB);
    });

    test('throws on a hash that is not 32 bytes', () {
      expect(
        () => VeChainSecp256k1.recoverPublicKey(
          _utf8('some_invalid_stuff'),
          _hex(_signatureB),
        ),
        _throwsCryptoException('Invalid hash'),
      );
    });

    test('throws on a recovery byte of 8 (official forged example)', () {
      final forged = _hex(_signatureB)..[64] = 8;

      expect(
        () => VeChainSecp256k1.recoverPublicKey(_hex(_hash), forged),
        _throwsCryptoException('the recovery byte must be 0 or 1, got 8'),
      );
    });

    test('throws on a signature that is not 65 bytes', () {
      expect(
        () => VeChainSecp256k1.recoverPublicKey(
          _hex(_hash),
          _hex(_signatureB).sublist(0, 64),
        ),
        _throwsCryptoException('expected 65 bytes, got 64'),
      );
    });

    test('throws on r = 0', () {
      final zeroR = _signature(BigInt.zero, BigInt.one, 0);

      expect(
        () => VeChainSecp256k1.recoverPublicKey(_hex(_hash), zeroR),
        _throwsCryptoException('r and s must be between 1'),
      );
    });

    test('throws on s equal to the curve order', () {
      final orderS = _signature(officialR, VeChainSecp256k1.order, 0);

      expect(
        () => VeChainSecp256k1.recoverPublicKey(_hex(_hash), orderS),
        _throwsCryptoException('r and s must be between 1'),
      );
    });
  });

  group('VeChainSignature.fromBytes', () {
    test('parses the official signature', () {
      final signature = VeChainSignature.fromBytes(_hex(_signatureB));

      expect(signature.r, officialR);
      expect(signature.recovery, 0);
      expect(VeChainHex.encode(signature.bytes), _signatureB);
      expect(signature.toString(), _signatureB);
    });

    test('rejects a high-S signature, as the transaction pool does', () {
      expect(
        () => VeChainSignature.fromBytes(_hex(_highSSignatureB)),
        _throwsCryptoException('only accepts low-S signatures'),
      );
    });

    test('accepts s = n / 2 and rejects s = n / 2 + 1', () {
      final half = VeChainSecp256k1.halfOrder;

      expect(
        VeChainSignature.fromBytes(_signature(officialR, half, 0)).s,
        half,
      );
      expect(
        () => VeChainSignature.fromBytes(
          _signature(officialR, half + BigInt.one, 0),
        ),
        _throwsCryptoException('only accepts low-S signatures'),
      );
    });

    test('rejects a recovery byte other than 0 or 1', () {
      final two = _hex(_signatureB)..[64] = 2;

      expect(
        () => VeChainSignature.fromBytes(two),
        _throwsCryptoException('the recovery byte must be 0 or 1, got 2'),
      );
    });

    test('rejects a length other than 65 bytes', () {
      expect(
        () => VeChainSignature.fromBytes(Uint8List(64)),
        _throwsCryptoException('expected 65 bytes, got 64'),
      );
    });

    test('rejects r = 0', () {
      expect(
        () =>
            VeChainSignature.fromBytes(_signature(BigInt.zero, BigInt.one, 0)),
        _throwsCryptoException('r and s must be between 1'),
      );
    });
  });

  group('VeChainSignature recovery', () {
    test('recoverPublicKey returns the official public key', () {
      final signature = VeChainSignature.fromBytes(_hex(_signatureB));

      expect(
        VeChainHex.encode(signature.recoverPublicKey(_hex(_hash))),
        _publicKeyB,
      );
    });

    test('recoverAddress returns the signer address', () {
      final b = VeChainSignature.fromBytes(_hex(_signatureB));
      final a = VeChainSignature.fromBytes(_hex(_signatureA));

      expect(b.recoverAddress(_hex(_hash)).toString(), _addressB);
      expect(a.recoverAddress(_hex(_hash)).toString(), _addressA);
    });

    test('a different hash recovers a different address', () {
      final signature = VeChainSignature.fromBytes(_hex(_signatureB));
      final otherHash = VeChainHash.keccak256(_utf8('hello world!'));

      expect(
        signature.recoverAddress(otherHash).toString(),
        isNot(_addressB),
      );
    });

    test('signatures with the same bytes are equal', () {
      final first = VeChainSignature.fromBytes(_hex(_signatureB));
      final second = VeChainSignature.fromBytes(_hex(_signatureB));

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(VeChainSignature.fromBytes(_hex(_signatureA))));
    });
  });

  group('VeChainKeyPair.sign', () {
    test('produces the official signature', () {
      final keyPair = VeChainKeyPair.fromPrivateKey(_hex(_privateKeyB));

      expect(keyPair.sign(_hex(_hash)).toString(), _signatureB);
    });

    test('a generated key pair signs and recovers its own address', () {
      final keyPair = VeChainKeyPair.generate();
      final hash = VeChainHash.blake2b256(_utf8('VeChainThor'));
      final signature = keyPair.sign(hash);

      expect(signature.recoverAddress(hash), keyPair.address);
    });

    test('throws on a hash that is not 32 bytes', () {
      final keyPair = VeChainKeyPair.fromPrivateKey(_hex(_privateKeyB));

      expect(
        () => keyPair.sign(Uint8List(31)),
        _throwsCryptoException('expected 32 bytes, got 31'),
      );
    });
  });
}
