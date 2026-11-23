import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vechain_flutter_sdk/vechain_flutter_sdk.dart';

import '../../support/bip39_vectors.dart';

// ---- Official VeChain test mnemonic (vechain-sdk-js Mnemonic tests) ----

const _vechainPhrase = 'ignore empty bird silly journey junior '
    'ripple have guard waste between tenant';

// ---- Independently computed values for the VeChain mnemonic ----

const _vechainEntropy = '0x70c9245a645786f26e934d675ef456ef';

/// BIP-39 seed of [_vechainPhrase] with an empty passphrase.
const _vechainSeed =
    '0x28bc19620b4fbb1f8892b9607f6e406fcd8226a0d6dc167ff677d122a1a64ef936101a644e6b447fd495677f68215d8522c893100d9010668614a68b3c7bb49f';

/// Matches a [VeChainMnemonicException] whose message contains [text].
Matcher _throwsMnemonicException(String text) => throwsA(
      isA<VeChainMnemonicException>().having(
        (e) => e.message,
        'message',
        contains(text),
      ),
    );

void main() {
  group('VeChainMnemonic official BIP-39 vectors', () {
    test('fromEntropy produces every official mnemonic', () {
      for (final vector in bip39TestVectors) {
        final mnemonic =
            VeChainMnemonic.fromEntropy(VeChainHex.decode(vector.entropy));
        expect(mnemonic.phrase, vector.mnemonic);
      }
    });

    test('parse recovers every official entropy', () {
      for (final vector in bip39TestVectors) {
        final mnemonic = VeChainMnemonic.parse(vector.mnemonic);
        expect(VeChainHex.encode(mnemonic.entropy), vector.entropy);
      }
    });

    test('toSeed with the passphrase TREZOR gives every official seed', () {
      for (final vector in bip39TestVectors) {
        final seed =
            VeChainMnemonic.parse(vector.mnemonic).toSeed(passphrase: 'TREZOR');
        expect(VeChainHex.encode(seed), vector.seed);
      }
    });
  });

  group('VeChainMnemonic and the official VeChain mnemonic', () {
    test('parses with the expected entropy and seed', () {
      final mnemonic = VeChainMnemonic.parse(_vechainPhrase);

      expect(mnemonic.words.length, 12);
      expect(VeChainHex.encode(mnemonic.entropy), _vechainEntropy);
      expect(VeChainHex.encode(mnemonic.toSeed()), _vechainSeed);
    });

    test('the default passphrase is the empty passphrase', () {
      final mnemonic = VeChainMnemonic.parse(_vechainPhrase);

      expect(mnemonic.toSeed(), mnemonic.toSeed());
    });

    test('a passphrase gives a different seed', () {
      final mnemonic = VeChainMnemonic.parse(_vechainPhrase);

      expect(mnemonic.toSeed(passphrase: 'TREZOR'), isNot(mnemonic.toSeed()));
    });

    test('every seed is 64 bytes', () {
      final seed = VeChainMnemonic.parse(_vechainPhrase).toSeed();

      expect(seed.length, VeChainMnemonic.seedLength);
    });
  });

  group('VeChainMnemonic.generate', () {
    test('produces each supported word count and round-trips', () {
      for (final wordCount in [12, 15, 18, 21, 24]) {
        final mnemonic = VeChainMnemonic.generate(wordCount: wordCount);
        final restored = VeChainMnemonic.parse(mnemonic.phrase);

        expect(mnemonic.words.length, wordCount);
        expect(restored.entropy, mnemonic.entropy);
      }
    });

    test('defaults to 12 words', () {
      expect(VeChainMnemonic.generate().words.length, 12);
    });

    test('two generated mnemonics are different', () {
      expect(
        VeChainMnemonic.generate().phrase,
        isNot(VeChainMnemonic.generate().phrase),
      );
    });

    test('throws on an unsupported word count', () {
      expect(
        () => VeChainMnemonic.generate(wordCount: 13),
        _throwsMnemonicException(
          'expected 12, 15, 18, 21 or 24, got 13',
        ),
      );
    });
  });

  group('VeChainMnemonic.fromEntropy', () {
    test('throws on an unsupported entropy length', () {
      for (final length in [0, 15, 17, 33]) {
        expect(
          () => VeChainMnemonic.fromEntropy(Uint8List(length)),
          _throwsMnemonicException('got $length'),
        );
      }
    });

    test('copies the entropy, so later changes do not affect it', () {
      final source = Uint8List(16);
      final mnemonic = VeChainMnemonic.fromEntropy(source);
      source[0] = 0xff;

      expect(mnemonic.entropy[0], 0);
    });
  });

  group('VeChainMnemonic.parse', () {
    test('ignores letter case and extra whitespace', () {
      final messy =
          '  ${_vechainPhrase.toUpperCase().replaceAll(' ', '   ')}\n';
      final mnemonic = VeChainMnemonic.parse(messy);

      expect(mnemonic.phrase, _vechainPhrase);
      expect(VeChainHex.encode(mnemonic.toSeed()), _vechainSeed);
    });

    test('throws on an unsupported number of words', () {
      final elevenWords = _vechainPhrase.split(' ').sublist(0, 11).join(' ');

      expect(
        () => VeChainMnemonic.parse(elevenWords),
        _throwsMnemonicException('expected 12, 15, 18, 21 or 24 words, got 11'),
      );
    });

    test('throws on an empty phrase', () {
      expect(
        () => VeChainMnemonic.parse('   '),
        _throwsMnemonicException('got 0'),
      );
    });

    test('reports an unknown word by position, never the word itself', () {
      final typo = _vechainPhrase.replaceFirst('silly', 'sily');

      expect(
        () => VeChainMnemonic.parse(typo),
        throwsA(
          isA<VeChainMnemonicException>()
              .having(
                (e) => e.message,
                'message',
                contains('word 4 is not in the BIP-39 English wordlist'),
              )
              .having((e) => e.message, 'message', isNot(contains('sily'))),
        ),
      );
    });

    test('throws on a wrong checksum', () {
      final allAbandon = List.filled(12, 'abandon').join(' ');

      expect(
        () => VeChainMnemonic.parse(allAbandon),
        _throwsMnemonicException('the checksum does not match'),
      );
    });

    test('throws when two words are swapped', () {
      final words = _vechainPhrase.split(' ');
      final swapped = [words[1], words[0], ...words.sublist(2)].join(' ');

      expect(
        () => VeChainMnemonic.parse(swapped),
        _throwsMnemonicException('the checksum does not match'),
      );
    });
  });

  group('VeChainMnemonic protects its secret', () {
    test('rejects a non-ASCII passphrase', () {
      final mnemonic = VeChainMnemonic.parse(_vechainPhrase);

      expect(
        () => mnemonic.toSeed(passphrase: 'contraseña'),
        _throwsMnemonicException('only ASCII characters are supported'),
      );
    });

    test('toString shows the word count but never the words', () {
      final text = VeChainMnemonic.parse(_vechainPhrase).toString();

      expect(text, 'VeChainMnemonic(12 words)');
      expect(text, isNot(contains('ignore')));
    });

    test('words and entropy return copies', () {
      final mnemonic = VeChainMnemonic.parse(_vechainPhrase);
      mnemonic.words[0] = 'zoo';
      mnemonic.entropy[0] = 0;

      expect(mnemonic.phrase, _vechainPhrase);
      expect(VeChainHex.encode(mnemonic.entropy), _vechainEntropy);
    });
  });
}
