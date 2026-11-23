/// Phase 1 - 0.0.6-dev: Mnemonic (BIP-39).
///
/// A mnemonic is a human-readable backup of a wallet's master secret:
/// 12 to 24 English words that encode random entropy plus a checksum.
/// From the words, BIP-39 derives a 64-byte seed, the input of the HD
/// wallet that produces every account.
///
/// // Full technical decisions:
/// https://github.com/nemorixgroup/VeChain-Knowledge-Base/tree/main/docs-sdk/phase-1/mnemonic
import 'package:vechain_flutter_sdk/vechain_flutter_sdk.dart';

void mnemonicExample() {
  // A fresh 12-word mnemonic from a secure random source.
  final fresh = VeChainMnemonic.generate();
  print('Generated: ${fresh.words.length} words');

  // Printing a mnemonic never shows its words.
  print('Printed: $fresh');

  // Parse the official VeChain test mnemonic; case and spacing are
  // normalized before validating the words and the checksum.
  final mnemonic = VeChainMnemonic.parse(
    '  IGNORE empty bird silly journey junior '
    'ripple have guard waste between   tenant ',
  );
  print('Normalized: ${mnemonic.phrase}');
  print('Entropy: ${VeChainHex.encode(mnemonic.entropy)}');

  // The seed, with the default empty passphrase, as the official SDK.
  final seed = mnemonic.toSeed();
  print('Seed: ${seed.length} bytes, ${VeChainHex.encode(seed)}');

  // A mistyped word is reported by its position, never by the word.
  try {
    VeChainMnemonic.parse(
      'ignore empty bird sily journey junior '
      'ripple have guard waste between tenant',
    );
  } on VeChainMnemonicException catch (e) {
    print('Expected word error: ${e.message}');
  }

  // Two swapped words keep every word valid, but break the checksum.
  try {
    VeChainMnemonic.parse(
      'empty ignore bird silly journey junior '
      'ripple have guard waste between tenant',
    );
  } on VeChainMnemonicException catch (e) {
    print('Expected checksum error: ${e.message}');
  }
}
