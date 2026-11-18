import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vechain_flutter_sdk/vechain_flutter_sdk.dart';

// ---- Official vectors (vechain-sdk-js Address tests) ----

const _publicKeyA =
    '0x04a6711e14234b1d4e69aeed2acf18b9c3bd0e97db317b509516bd3a87e5b732685ccaf855d9f8a955bc1f420b4ebf8f682c2e480d98a360e7fd0c08e6eef65607';
const _addressA = '0x769E8AA372c8309c834EA6749B88861FF73581FF';

const _officialLowercase = '0xcfb79a9c950b78e14c43efa621ebcf9660dbe01f';
const _officialUppercase = '0xCFB79A9C950B78E14C43EFA621EBCF9660DBE01F';

/// Accepted by the official SDK as "valid checksum format", but it does
/// not match the real EIP-55 checksum below.
const _officialWrongChecksum = '0xCfb79a9c950b78E14c43efa621ebcf9660dbe01F';

// ---- Independently computed vectors ----

/// The real EIP-55 checksum of [_officialLowercase].
const _checksummed = '0xcfB79A9C950B78E14c43Efa621EBCf9660dbe01F';

const _compressedPublicKeyA =
    '0x03a6711e14234b1d4e69aeed2acf18b9c3bd0e97db317b509516bd3a87e5b73268';

const _compressedPublicKeyB =
    '0x03b90e9bb2617387eba4502c730de65a33878ef384a46f1096d86f2da19043304a';
const _addressB = '0xd989829d88B0eD1B06eDF5C50174eCfA64F14A64';

/// The generator point G (private key 1) and its address.
const _compressedGenerator =
    '0x0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
const _generatorAddress = '0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf';

// ---- EIP-55 specification vectors ----

const _eip55Vectors = [
  '0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed',
  '0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359',
  '0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB',
  '0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb',
];

/// Matches a [VeChainAddressException] whose message contains [text].
Matcher _throwsAddressException(String text) => throwsA(
      isA<VeChainAddressException>().having(
        (e) => e.message,
        'message',
        contains(text),
      ),
    );

void main() {
  group('VeChainAddress.fromPublicKey', () {
    test('derives the official address from an uncompressed key', () {
      final address = VeChainAddress.fromPublicKey(
        VeChainHex.decode(_publicKeyA),
      );

      expect(address.toString(), _addressA);
    });

    test('a compressed key gives the same address as uncompressed', () {
      final address = VeChainAddress.fromPublicKey(
        VeChainHex.decode(_compressedPublicKeyA),
      );

      expect(address.toString(), _addressA);
    });

    test('derives the address of the second key', () {
      final address = VeChainAddress.fromPublicKey(
        VeChainHex.decode(_compressedPublicKeyB),
      );

      expect(address.toString(), _addressB);
    });

    test('derives the address of the generator point', () {
      final address = VeChainAddress.fromPublicKey(
        VeChainHex.decode(_compressedGenerator),
      );

      expect(address.toString(), _generatorAddress);
    });

    test('throws on the official invalid example [1, 2, 3, 4, 5]', () {
      expect(
        () => VeChainAddress.fromPublicKey(
          Uint8List.fromList([1, 2, 3, 4, 5]),
        ),
        throwsA(isA<VeChainCryptoException>()),
      );
    });
  });

  group('VeChainAddress.parse', () {
    test('accepts the official all-lowercase address', () {
      final address = VeChainAddress.parse(_officialLowercase);

      expect(address.toString(), _checksummed);
    });

    test('accepts the official all-uppercase address', () {
      final address = VeChainAddress.parse(_officialUppercase);

      expect(address.toString(), _checksummed);
    });

    test('accepts a correct EIP-55 checksum', () {
      expect(VeChainAddress.parse(_checksummed).toString(), _checksummed);
    });

    test('accepts every EIP-55 specification vector', () {
      for (final vector in _eip55Vectors) {
        expect(VeChainAddress.parse(vector).toString(), vector);
      }
    });

    test('accepts an uppercase 0X prefix', () {
      final address =
          VeChainAddress.parse('0X${_officialLowercase.substring(2)}');

      expect(address.toString(), _checksummed);
    });

    test('rejects the official mixed-case string with a wrong checksum', () {
      expect(
        () => VeChainAddress.parse(_officialWrongChecksum),
        _throwsAddressException('Invalid address checksum'),
      );
    });

    test('rejects a single mistyped character in a checksummed address', () {
      // Changing one digit keeps mixed case but breaks the checksum.
      final mistyped = _addressA.replaceFirst('769E', '769F');

      expect(
        () => VeChainAddress.parse(mistyped),
        _throwsAddressException('Invalid address checksum'),
      );
    });

    test('rejects a short address instead of padding it (official 0xcaffee)',
        () {
      expect(
        () => VeChainAddress.parse('0xcaffee'),
        _throwsAddressException('Invalid address "0xcaffee"'),
      );
    });

    test('rejects a negative sign (official -0xcaffee)', () {
      expect(
        () => VeChainAddress.parse('-0xcaffee'),
        _throwsAddressException('Invalid address'),
      );
    });

    test('rejects an address without the 0x prefix', () {
      expect(
        () => VeChainAddress.parse(_officialLowercase.substring(2)),
        _throwsAddressException('expected 0x followed by 40'),
      );
    });

    test('rejects 41 hex digits', () {
      expect(
        () => VeChainAddress.parse('${_officialLowercase}0'),
        _throwsAddressException('expected 0x followed by 40'),
      );
    });

    test('rejects a non-hex character', () {
      final nonHex = _officialLowercase.replaceFirst('c', 'g');

      expect(
        () => VeChainAddress.parse(nonHex),
        _throwsAddressException('expected 0x followed by 40'),
      );
    });
  });

  group('VeChainAddress.fromBytes', () {
    test('creates an address from 20 bytes', () {
      final address = VeChainAddress.fromBytes(Uint8List(20));

      expect(
        address.toString(),
        '0x0000000000000000000000000000000000000000',
      );
    });

    test('throws on a length other than 20', () {
      expect(
        () => VeChainAddress.fromBytes(Uint8List(19)),
        _throwsAddressException('expected 20 bytes, got 19'),
      );
      expect(
        () => VeChainAddress.fromBytes(Uint8List(21)),
        _throwsAddressException('expected 20 bytes, got 21'),
      );
    });

    test('copies the input, so later changes do not affect it', () {
      final source = Uint8List(20);
      final address = VeChainAddress.fromBytes(source);
      source[0] = 0xff;

      expect(address.bytes[0], 0);
    });

    test('bytes returns a copy', () {
      final address = VeChainAddress.parse(_addressA);
      address.bytes[0] = 0x00;

      expect(address.toString(), _addressA);
    });
  });

  group('VeChainAddress equality', () {
    test('the same address in any accepted form is equal', () {
      final lower = VeChainAddress.parse(_officialLowercase);
      final checksummed = VeChainAddress.parse(_checksummed);

      expect(lower, checksummed);
      expect(lower.hashCode, checksummed.hashCode);
    });

    test('different addresses are not equal', () {
      expect(
        VeChainAddress.parse(_addressA),
        isNot(VeChainAddress.parse(_checksummed)),
      );
    });
  });
}
