import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vechain_flutter_sdk/src/crypto/vechain_secp256k1.dart';
import 'package:vechain_flutter_sdk/vechain_flutter_sdk.dart';

// ---- Official vectors (vechain-sdk-js Address and Secp256k1 tests) ----

const _privateKeyA =
    '0x5434c159b817c377a55f6be66369622976014e78bce2adfd3e44e5de88ce502f';
const _publicKeyA =
    '0x04a6711e14234b1d4e69aeed2acf18b9c3bd0e97db317b509516bd3a87e5b732685ccaf855d9f8a955bc1f420b4ebf8f682c2e480d98a360e7fd0c08e6eef65607';
const _addressA = '0x769E8AA372c8309c834EA6749B88861FF73581FF';

const _privateKeyB =
    '0x7582be841ca040aa940fff6c05773129e135623e41acce3e0b8ba520dc1ae26a';
const _publicKeyB =
    '0x04b90e9bb2617387eba4502c730de65a33878ef384a46f1096d86f2da19043304afa67d0ad09cf2bea0c6f2d1767a9e62a7a7ecc41facf18f2fa505d92243a658f';
const _compressedPublicKeyB =
    '0x03b90e9bb2617387eba4502c730de65a33878ef384a46f1096d86f2da19043304a';

// ---- Independently computed vectors ----

const _compressedPublicKeyA =
    '0x03a6711e14234b1d4e69aeed2acf18b9c3bd0e97db317b509516bd3a87e5b73268';

/// The generator point G (private key 1): its Y is even.
const _compressedGenerator =
    '0x0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
const _generatorAddress = '0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf';

/// Decodes a hex constant into bytes.
Uint8List _hex(String hex) => VeChainHex.decode(hex);

/// Matches a [VeChainCryptoException] whose message contains [text].
Matcher _throwsCryptoException(String text) => throwsA(
      isA<VeChainCryptoException>().having(
        (e) => e.message,
        'message',
        contains(text),
      ),
    );

void main() {
  group('VeChainKeyPair.fromPrivateKey', () {
    test('derives the official public key and address', () {
      final keyPair = VeChainKeyPair.fromPrivateKey(_hex(_privateKeyA));

      expect(VeChainHex.encode(keyPair.privateKey), _privateKeyA);
      expect(VeChainHex.encode(keyPair.publicKey), _publicKeyA);
      expect(keyPair.address.toString(), _addressA);
    });

    test('derives the official uncompressed and compressed public keys', () {
      final keyPair = VeChainKeyPair.fromPrivateKey(_hex(_privateKeyB));

      expect(VeChainHex.encode(keyPair.publicKey), _publicKeyB);
      expect(
        VeChainHex.encode(keyPair.compressedPublicKey),
        _compressedPublicKeyB,
      );
    });

    test('compresses an odd Y with the 0x03 prefix', () {
      final keyPair = VeChainKeyPair.fromPrivateKey(_hex(_privateKeyA));

      expect(
        VeChainHex.encode(keyPair.compressedPublicKey),
        _compressedPublicKeyA,
      );
    });

    test('compresses an even Y with the 0x02 prefix (private key 1)', () {
      final one = VeChainSecp256k1.bigIntToBytes(BigInt.one, 32);
      final keyPair = VeChainKeyPair.fromPrivateKey(one);

      expect(
        VeChainHex.encode(keyPair.compressedPublicKey),
        _compressedGenerator,
      );
      expect(keyPair.address.toString(), _generatorAddress);
    });

    test('the compressed public key derives the same address', () {
      final keyPair = VeChainKeyPair.fromPrivateKey(_hex(_privateKeyB));
      final fromCompressed = VeChainAddress.fromPublicKey(
        keyPair.compressedPublicKey,
      );

      expect(fromCompressed, keyPair.address);
    });

    test('throws on a zero private key', () {
      expect(
        () => VeChainKeyPair.fromPrivateKey(Uint8List(32)),
        _throwsCryptoException('Invalid private key'),
      );
    });

    test('throws on a private key equal to the curve order', () {
      final order = VeChainSecp256k1.bigIntToBytes(VeChainSecp256k1.order, 32);

      expect(
        () => VeChainKeyPair.fromPrivateKey(order),
        _throwsCryptoException('Invalid private key'),
      );
    });

    test('throws on a private key that is not 32 bytes', () {
      expect(
        () => VeChainKeyPair.fromPrivateKey(Uint8List(31)..[30] = 1),
        _throwsCryptoException('Invalid private key'),
      );
    });

    test('the error message never contains the private key', () {
      final allOnes = Uint8List(32)..fillRange(0, 32, 0xff);
      final keyHex = VeChainHex.encode(allOnes).substring(2);

      expect(
        () => VeChainKeyPair.fromPrivateKey(allOnes),
        throwsA(
          isA<VeChainCryptoException>().having(
            (e) => e.message.toLowerCase(),
            'message',
            isNot(contains(keyHex)),
          ),
        ),
      );
    });
  });

  group('VeChainKeyPair protects its keys', () {
    test('copies the input, so later changes do not affect it', () {
      final source = _hex(_privateKeyA);
      final keyPair = VeChainKeyPair.fromPrivateKey(source);
      source[0] = 0x00;

      expect(VeChainHex.encode(keyPair.privateKey), _privateKeyA);
    });

    test('getters return copies', () {
      final keyPair = VeChainKeyPair.fromPrivateKey(_hex(_privateKeyA));
      keyPair.privateKey[0] = 0x00;
      keyPair.publicKey[1] = 0x00;
      keyPair.compressedPublicKey[1] = 0x00;

      expect(VeChainHex.encode(keyPair.privateKey), _privateKeyA);
      expect(VeChainHex.encode(keyPair.publicKey), _publicKeyA);
      expect(
        VeChainHex.encode(keyPair.compressedPublicKey),
        _compressedPublicKeyA,
      );
    });

    test('toString shows the address but never the private key', () {
      final keyPair = VeChainKeyPair.fromPrivateKey(_hex(_privateKeyA));
      final text = keyPair.toString();

      expect(text, 'VeChainKeyPair(address: $_addressA)');
      expect(text.toLowerCase(), isNot(contains(_privateKeyA.substring(2))));
    });
  });

  group('VeChainKeyPair.generate', () {
    test('generates a valid key pair', () {
      final keyPair = VeChainKeyPair.generate();

      expect(VeChainSecp256k1.isValidPrivateKey(keyPair.privateKey), isTrue);
      expect(keyPair.publicKey.length, 65);
      expect(keyPair.publicKey[0], 0x04);
      expect(keyPair.compressedPublicKey.length, 33);
      expect(keyPair.compressedPublicKey[0], anyOf(0x02, 0x03));
    });

    test('two generated key pairs are different', () {
      final first = VeChainKeyPair.generate();
      final second = VeChainKeyPair.generate();

      expect(first.privateKey, isNot(second.privateKey));
      expect(first.address, isNot(second.address));
    });

    test('a generated key pair can be restored from its private key', () {
      final generated = VeChainKeyPair.generate();
      final restored = VeChainKeyPair.fromPrivateKey(generated.privateKey);

      expect(restored.address, generated.address);
      expect(restored.publicKey, generated.publicKey);
      expect(restored.compressedPublicKey, generated.compressedPublicKey);
    });

    test('the generated public key matches an independent derivation', () {
      final keyPair = VeChainKeyPair.generate();
      final derived = VeChainSecp256k1.derivePublicKey(
        keyPair.privateKey,
        compressed: true,
      );

      expect(keyPair.compressedPublicKey, derived);
    });
  });
}
