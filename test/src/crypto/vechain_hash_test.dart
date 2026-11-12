import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vechain_flutter_sdk/vechain_flutter_sdk.dart';

// ---- Official vectors (vechain-sdk-js, packages/core/tests/vcdm/hash) ----

const _content = 'Hello world - Здравствуйте - こんにちは!';

const _contentBlake2b256 =
    '0x6a908bb80109908919c0bf5d0594c890700dd46acc097f9f28bfc85a0a2e6c0c';
const _emptyBlake2b256 =
    '0x0e5751c026e543b2e8ab2eb06099daa1d1e5df47778f7787faab45cdf12fe3a8';

const _contentKeccak256 =
    '0x1e86a83a4fcab1b47b8c961f7ab6c5d32927eefa8af20af81f6eab0bc3be582a';
const _emptyKeccak256 =
    '0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470';

/// SHA3-256 of an empty input. Keccak-256 must never produce this value.
const _emptySha3256 =
    '0xa7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a';

/// Encodes [text] as UTF-8 bytes.
Uint8List _utf8(String text) => Uint8List.fromList(utf8.encode(text));

void main() {
  group('VeChainHash.blake2b256', () {
    test('matches the official vector for UTF-8 content', () {
      final hash = VeChainHash.blake2b256(_utf8(_content));

      expect(VeChainHex.encode(hash), _contentBlake2b256);
    });

    test('matches the official vector for empty input', () {
      final hash = VeChainHash.blake2b256(Uint8List(0));

      expect(VeChainHex.encode(hash), _emptyBlake2b256);
    });

    test('always returns 32 bytes', () {
      for (final size in [0, 1, 31, 32, 33, 128, 1000]) {
        final hash = VeChainHash.blake2b256(Uint8List(size));
        expect(hash.length, VeChainHash.hashLength);
      }
    });

    test('is deterministic and input-sensitive', () {
      final first = VeChainHash.blake2b256(_utf8('data'));
      final second = VeChainHash.blake2b256(_utf8('data'));
      final other = VeChainHash.blake2b256(_utf8('Data'));

      expect(first, second);
      expect(first, isNot(other));
    });
  });

  group('VeChainHash.blake2b256Concat', () {
    test('hashing parts equals hashing them joined', () {
      final parts = VeChainHash.blake2b256Concat([
        _utf8('multi'),
        _utf8('ple'),
        _utf8('data'),
      ]);
      final joined = VeChainHash.blake2b256(_utf8('multipledata'));

      expect(parts, joined);
    });

    test('a single part equals the single-input form', () {
      final data = _utf8(_content);

      expect(
        VeChainHash.blake2b256Concat([data]),
        VeChainHash.blake2b256(data),
      );
    });

    test('an empty list hashes an empty input', () {
      final hash = VeChainHash.blake2b256Concat([]);

      expect(VeChainHex.encode(hash), _emptyBlake2b256);
    });
  });

  group('VeChainHash.keccak256', () {
    test('matches the official vector for UTF-8 content', () {
      final hash = VeChainHash.keccak256(_utf8(_content));

      expect(VeChainHex.encode(hash), _contentKeccak256);
    });

    test('matches the official vector for empty input', () {
      final hash = VeChainHash.keccak256(Uint8List(0));

      expect(VeChainHex.encode(hash), _emptyKeccak256);
    });

    test('is legacy Keccak-256, not SHA3-256', () {
      final hash = VeChainHash.keccak256(Uint8List(0));

      expect(VeChainHex.encode(hash), isNot(_emptySha3256));
    });

    test('always returns 32 bytes', () {
      for (final size in [0, 1, 31, 32, 33, 136, 1000]) {
        final hash = VeChainHash.keccak256(Uint8List(size));
        expect(hash.length, VeChainHash.hashLength);
      }
    });

    test('is deterministic and input-sensitive', () {
      final first = VeChainHash.keccak256(_utf8('data'));
      final second = VeChainHash.keccak256(_utf8('data'));
      final other = VeChainHash.keccak256(_utf8('Data'));

      expect(first, second);
      expect(first, isNot(other));
    });
  });

  group('VeChainHash.keccak256Concat', () {
    test('hashing parts equals hashing them joined', () {
      final parts = VeChainHash.keccak256Concat([
        _utf8('multi'),
        _utf8('ple'),
        _utf8('data'),
      ]);
      final joined = VeChainHash.keccak256(_utf8('multipledata'));

      expect(parts, joined);
    });

    test('a single part equals the single-input form', () {
      final data = _utf8(_content);

      expect(
        VeChainHash.keccak256Concat([data]),
        VeChainHash.keccak256(data),
      );
    });

    test('an empty list hashes an empty input', () {
      final hash = VeChainHash.keccak256Concat([]);

      expect(VeChainHex.encode(hash), _emptyKeccak256);
    });
  });

  group('VeChainHash functions are independent', () {
    test('BLAKE2b-256 and Keccak-256 give different hashes', () {
      final data = _utf8(_content);

      expect(VeChainHash.blake2b256(data), isNot(VeChainHash.keccak256(data)));
    });
  });
}
