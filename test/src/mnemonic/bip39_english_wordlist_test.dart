import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:vechain_flutter_sdk/src/mnemonic/bip39_english_wordlist.dart';
import 'package:vechain_flutter_sdk/vechain_flutter_sdk.dart';

/// SHA-256 of the official english.txt from the bitcoin/bips repository.
const _officialSha256 =
    '0x2f5eed53a4727b4bf8880d8f3f199efc90e58503646d9ff8eff3a2ed3b24dbda';

void main() {
  group('bip39EnglishWordlist', () {
    test('has exactly 2048 words', () {
      expect(bip39EnglishWordlist.length, 2048);
    });

    test('matches the SHA-256 of the official file byte for byte', () {
      // The official file is one word per line, with a final newline.
      final text = '${bip39EnglishWordlist.join('\n')}\n';
      final hash = SHA256Digest().process(
        Uint8List.fromList(utf8.encode(text)),
      );

      expect(VeChainHex.encode(hash), _officialSha256);
    });

    test('is sorted, unique, and lowercase ASCII', () {
      for (var i = 1; i < bip39EnglishWordlist.length; i++) {
        expect(
          bip39EnglishWordlist[i - 1].compareTo(bip39EnglishWordlist[i]),
          lessThan(0),
        );
      }
      for (final word in bip39EnglishWordlist) {
        expect(word, matches(RegExp(r'^[a-z]+$')));
      }
    });

    test('starts with abandon and ends with zoo', () {
      expect(bip39EnglishWordlist.first, 'abandon');
      expect(bip39EnglishWordlist.last, 'zoo');
    });
  });
}
