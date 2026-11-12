import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vechain_flutter_sdk/vechain_flutter_sdk.dart';

/// Matches a [VeChainCodecException] whose message contains [text].
Matcher _throwsCodecException(String text) => throwsA(
      isA<VeChainCodecException>().having(
        (e) => e.message,
        'message',
        contains(text),
      ),
    );

void main() {
  group('VeChainHex.encode', () {
    test('an empty list produces 0x', () {
      expect(VeChainHex.encode(Uint8List(0)), '0x');
    });

    test('pads every byte to two digits', () {
      final bytes = Uint8List.fromList([0, 10, 255]);

      expect(VeChainHex.encode(bytes), '0x000aff');
    });

    test('always uses lowercase digits', () {
      final bytes = Uint8List.fromList([0xca, 0xfe, 0xba, 0xbe]);

      expect(VeChainHex.encode(bytes), '0xcafebabe');
    });
  });

  group('VeChainHex.decode', () {
    test('decodes a 0x-prefixed string', () {
      expect(VeChainHex.decode('0x000aff'), [0, 10, 255]);
    });

    test('decodes a string without prefix', () {
      expect(VeChainHex.decode('000aff'), [0, 10, 255]);
    });

    test('accepts an uppercase 0X prefix', () {
      expect(VeChainHex.decode('0Xcafe'), [0xca, 0xfe]);
    });

    test('accepts digits in any case', () {
      expect(VeChainHex.decode('0xCaFe'), [0xca, 0xfe]);
    });

    test('0x and the empty string both produce an empty list', () {
      expect(VeChainHex.decode('0x'), isEmpty);
      expect(VeChainHex.decode(''), isEmpty);
    });

    test('round-trips with encode', () {
      const hash =
          '0x6a908bb80109908919c0bf5d0594c890700dd46acc097f9f28bfc85a0a2e6c0c';

      expect(VeChainHex.encode(VeChainHex.decode(hash)), hash);
    });
  });

  group('VeChainHex.decode validation', () {
    test('throws on a non-hex character (official example 0xfoe)', () {
      expect(
        () => VeChainHex.decode('0xfoe'),
        _throwsCodecException('Invalid hex string "0xfoe": only 0-9'),
      );
    });

    test('throws on an odd number of digits instead of padding', () {
      expect(
        () => VeChainHex.decode('0xabc'),
        _throwsCodecException('expected an even number of hex digits'),
      );
    });

    test('throws on surrounding whitespace', () {
      expect(
        () => VeChainHex.decode(' 0x00'),
        _throwsCodecException('Invalid hex string'),
      );
    });

    test('throws on a doubled prefix', () {
      expect(
        () => VeChainHex.decode('0x0x00'),
        _throwsCodecException('Invalid hex string'),
      );
    });

    test('throws on a negative sign', () {
      expect(
        () => VeChainHex.decode('-0x01'),
        _throwsCodecException('Invalid hex string'),
      );
    });
  });
}
