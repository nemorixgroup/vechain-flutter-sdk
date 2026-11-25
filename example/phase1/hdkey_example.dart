/// Phase 1 - 0.0.7-dev: HD wallet (BIP-32).
///
/// An HD wallet derives every account from one seed, so backing up the
/// mnemonic is enough to restore all of them. VeChainThor accounts live
/// under m/44'/818'/0'/0/i, where 818 is VeChain's registered coin type
/// and i is the account number.
///
/// // Full technical decisions:
/// https://github.com/nemorixgroup/VeChain-Knowledge-Base/tree/main/docs-sdk/phase-1/hd-wallet
import 'package:vechain_flutter_sdk/vechain_flutter_sdk.dart';

void hdWalletExample() {
  // From the official test mnemonic to the VeChain account node.
  final mnemonic = VeChainMnemonic.parse(
    'ignore empty bird silly journey junior '
    'ripple have guard waste between tenant',
  );
  final root = VeChainHDKey.fromMnemonic(mnemonic);
  print('Account node: ${VeChainHDKey.vetDerivationPath}');

  // Each child is one account of the wallet.
  for (var i = 0; i < 3; i++) {
    print('Account $i: ${root.deriveChild(i).address}');
  }

  // A watch-only copy derives the same addresses with no private key,
  // useful for a server that only needs to receive funds.
  final watcher = VeChainHDKey.fromPublicKey(root.publicKey, root.chainCode);
  print('Watch-only account 0: ${watcher.deriveChild(0).address}');
  print('Watch-only has a private key: ${!watcher.isWatchOnly}');

  // A derived account signs like any key pair.
  final account0 = root.deriveChild(0);
  print('Account 0 key pair: ${account0.keyPair}');

  // Printing a node never shows its private key or chain code.
  print('Printed: $account0');

  // Hardened derivation needs the private key.
  try {
    watcher.deriveChild(0, hardened: true);
  } on VeChainHDKeyException catch (e) {
    print('Expected watch-only error: ${e.message}');
  }

  // Malformed paths are rejected, never guessed.
  try {
    root.derive('m/0/1/4/2/4/h');
  } on VeChainHDKeyException catch (e) {
    print('Expected path error: ${e.message}');
  }
}
