import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/digests/sha512.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:vechain_flutter_sdk/src/exceptions/vechain_mnemonic_exception.dart';
import 'package:vechain_flutter_sdk/src/mnemonic/bip39_english_wordlist.dart';

/// A BIP-39 mnemonic: the list of English words that backs up the master
/// secret of a wallet.
///
/// Why this exists: a mnemonic is a human-readable form of a random
/// number (the entropy). Writing down 12 to 24 words is how users back
/// up a wallet, and from those words the SDK derives a 64-byte seed,
/// the input of the HD wallet that produces every account.
///
/// How it works (12 words as an example):
///
/// 1. 128 bits of entropy (16 bytes).
/// 2. The first 4 bits of the SHA-256 of the entropy are appended as a
///    checksum (132 bits).
/// 3. The 132 bits are cut into 12 groups of 11 bits; each group is the
///    index of a word in the official 2048-word list.
/// 4. The seed is PBKDF2-HMAC-SHA512 of the words, with the salt
///    `"mnemonic" + passphrase`, 2048 iterations and 64 bytes.
///
/// Design decisions:
///
/// - English wordlist only, with 12, 15, 18, 21 or 24 words, as in the
///   official VeChain SDK (12 by default).
/// - [VeChainMnemonic.parse] trims the phrase, accepts any whitespace
///   between words and lowercases them, and uses the same normalized
///   words to validate and to derive the seed.
/// - [toSeed] accepts an optional passphrase, empty by default, which
///   gives exactly the official VeChain SDK result. Only ASCII
///   passphrases are accepted: BIP-39 requires Unicode NFKD
///   normalization, which the Dart core libraries do not provide.
/// - [toString] never shows the words, and errors identify an invalid
///   word only by its position.
///
/// Example:
/// ```dart
/// final mnemonic = VeChainMnemonic.generate();
/// print(mnemonic.words.length); // 12
///
/// final restored = VeChainMnemonic.parse(mnemonic.phrase);
/// final seed = restored.toSeed(); // 64 bytes
/// ```
///
/// See:
/// - https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki
/// - https://github.com/vechain/vechain-sdk-js/blob/main/packages/core/src/vcdm/Mnemonic.ts
class VeChainMnemonic {
  VeChainMnemonic._(this._words, this._entropy);

  /// Creates the mnemonic that encodes [entropy]: 16, 20, 24, 28 or 32
  /// bytes, giving 12, 15, 18, 21 or 24 words.
  ///
  /// Throws a [VeChainMnemonicException] if the entropy length is not
  /// one of those.
  ///
  /// Example:
  /// ```dart
  /// final mnemonic = VeChainMnemonic.fromEntropy(Uint8List(16));
  /// print(mnemonic.phrase); // abandon abandon ... abandon about
  /// ```
  factory VeChainMnemonic.fromEntropy(Uint8List entropy) {
    if (!_entropyLengths.contains(entropy.length)) {
      throw VeChainMnemonicException(
        'Invalid entropy: expected 16, 20, 24, 28 or 32 bytes, got '
        '${entropy.length}.',
      );
    }

    // Append the checksum: the first (bits / 32) bits of the SHA-256.
    final checksumLength = entropy.length * 8 ~/ 32;
    final checksum = SHA256Digest().process(entropy);
    final bits = _toBits(entropy) +
        _toBits(Uint8List.fromList([checksum[0]])).substring(0, checksumLength);

    // Each 11-bit group is the index of one word.
    final words = <String>[
      for (var i = 0; i < bits.length; i += _bitsPerWord)
        bip39EnglishWordlist[
            int.parse(bits.substring(i, i + _bitsPerWord), radix: 2)],
    ];
    return VeChainMnemonic._(words, Uint8List.fromList(entropy));
  }

  /// Generates a new mnemonic of [wordCount] words (12, 15, 18, 21 or
  /// 24) from a cryptographically secure random source.
  ///
  /// Throws a [VeChainMnemonicException] if [wordCount] is not one of
  /// those.
  ///
  /// Example:
  /// ```dart
  /// final mnemonic = VeChainMnemonic.generate(wordCount: 24);
  /// ```
  factory VeChainMnemonic.generate({int wordCount = 12}) {
    if (!_wordCounts.contains(wordCount)) {
      throw VeChainMnemonicException(
        'Invalid word count: expected 12, 15, 18, 21 or 24, got '
        '$wordCount.',
      );
    }

    // Every 3 words carry 32 bits (4 bytes) of entropy.
    final random = Random.secure();
    final entropy = Uint8List.fromList(
      List<int>.generate(wordCount * 4 ~/ 3, (_) => random.nextInt(256)),
    );
    return VeChainMnemonic.fromEntropy(entropy);
  }

  /// Parses a mnemonic phrase, validating every word and the checksum.
  ///
  /// Surrounding whitespace is removed, words may be separated by any
  /// whitespace, and letter case is ignored.
  ///
  /// Throws a [VeChainMnemonicException] if the number of words is not
  /// 12, 15, 18, 21 or 24, if a word is not in the BIP-39 English
  /// wordlist, or if the checksum does not match.
  ///
  /// Example:
  /// ```dart
  /// final mnemonic = VeChainMnemonic.parse(
  ///   'ignore empty bird silly journey junior '
  ///   'ripple have guard waste between tenant',
  /// );
  /// ```
  factory VeChainMnemonic.parse(String phrase) {
    // Normalize once; the same words are validated and later hashed.
    final words = phrase
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (!_wordCounts.contains(words.length)) {
      throw VeChainMnemonicException(
        'Invalid mnemonic: expected 12, 15, 18, 21 or 24 words, got '
        '${words.length}.',
      );
    }

    // Map every word to its 11-bit index, reporting only its position.
    final bits = StringBuffer();
    for (var i = 0; i < words.length; i++) {
      final index = _wordIndex[words[i]];
      if (index == null) {
        throw VeChainMnemonicException(
          'Invalid mnemonic: word ${i + 1} is not in the BIP-39 English '
          'wordlist.',
        );
      }
      bits.write(index.toRadixString(2).padLeft(_bitsPerWord, '0'));
    }

    // Split entropy and checksum, then recompute the checksum.
    final allBits = bits.toString();
    final entropyLength = allBits.length * 32 ~/ 33;
    final entropy = Uint8List.fromList([
      for (var i = 0; i < entropyLength; i += 8)
        int.parse(allBits.substring(i, i + 8), radix: 2),
    ]);
    final expected = VeChainMnemonic.fromEntropy(entropy);
    if (expected._words.join(' ') != words.join(' ')) {
      throw const VeChainMnemonicException(
        'Invalid mnemonic: the checksum does not match. Check the '
        'spelling and the order of the words.',
      );
    }
    return VeChainMnemonic._(words, entropy);
  }

  /// Accepted word counts.
  static const List<int> _wordCounts = [12, 15, 18, 21, 24];

  /// Accepted entropy lengths, in bytes.
  static const List<int> _entropyLengths = [16, 20, 24, 28, 32];

  /// Bits encoded by each word (2^11 = 2048 words).
  static const int _bitsPerWord = 11;

  /// PBKDF2 iterations required by BIP-39.
  static const int _seedIterations = 2048;

  /// Length of the seed, in bytes.
  static const int seedLength = 64;

  /// Word to index lookup for the official wordlist.
  static final Map<String, int> _wordIndex = {
    for (var i = 0; i < bip39EnglishWordlist.length; i++)
      bip39EnglishWordlist[i]: i,
  };

  final List<String> _words;
  final Uint8List _entropy;

  /// The words of this mnemonic, in order (a copy).
  ///
  /// Keep them secret: anyone holding them controls every account
  /// derived from this mnemonic.
  List<String> get words => List<String>.of(_words);

  /// The words joined by single spaces, as a user writes them down.
  ///
  /// Keep it secret, like [words].
  String get phrase => _words.join(' ');

  /// The entropy encoded by this mnemonic (a copy).
  Uint8List get entropy => Uint8List.fromList(_entropy);

  /// Derives the 64-byte BIP-39 seed: PBKDF2-HMAC-SHA512 of the phrase,
  /// with the salt `"mnemonic" + passphrase` and 2048 iterations.
  ///
  /// With the default empty [passphrase], the result matches the
  /// official VeChain SDK.
  ///
  /// Throws a [VeChainMnemonicException] if [passphrase] contains a
  /// non-ASCII character.
  ///
  /// Example:
  /// ```dart
  /// final seed = mnemonic.toSeed();
  /// print(seed.length); // 64
  /// ```
  Uint8List toSeed({String passphrase = ''}) {
    // Without NFKD, only ASCII guarantees the seed BIP-39 defines.
    if (passphrase.codeUnits.any((unit) => unit > 0x7f)) {
      throw const VeChainMnemonicException(
        'Invalid passphrase: only ASCII characters are supported, '
        'because BIP-39 requires Unicode NFKD normalization.',
      );
    }

    final salt = Uint8List.fromList(utf8.encode('mnemonic$passphrase'));
    final derivator = PBKDF2KeyDerivator(HMac(SHA512Digest(), 128))
      ..init(Pbkdf2Parameters(salt, _seedIterations, seedLength));
    return derivator.process(Uint8List.fromList(utf8.encode(phrase)));
  }

  /// Shows only the word count; the words are never printed.
  @override
  String toString() => 'VeChainMnemonic(${_words.length} words)';

  /// Converts [bytes] to a string of bits, 8 per byte.
  static String _toBits(Uint8List bytes) =>
      bytes.map((byte) => byte.toRadixString(2).padLeft(8, '0')).join();
}
