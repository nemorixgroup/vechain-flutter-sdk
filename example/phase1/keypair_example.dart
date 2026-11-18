/// Phase 1 - 0.0.4-dev: Keypair, address and checksum.
///
/// A VeChainThor account is controlled by a secp256k1 private key. Its
/// public key comes from the curve, and its address is the last 20
/// bytes of the Keccak-256 hash of that public key, shown with an
/// EIP-55 mixed-case checksum that catches mistyped characters.
///
/// // Full technical decisions:
/// https://github.com/nemorixgroup/VeChain-Knowledge-Base/tree/main/docs-sdk/phase-1/keypair-and-address
import 'package:vechain_flutter_sdk/vechain_flutter_sdk.dart';

void keypairAndAddressExample() {
  // Restore the official test key: it always derives the same address.
  final keyPair = VeChainKeyPair.fromPrivateKey(
    VeChainHex.decode(
      '0x5434c159b817c377a55f6be66369622976014e78bce2adfd3e44e5de88ce502f',
    ),
  );
  print('Address: ${keyPair.address}');
  print('Public key: ${keyPair.publicKey.length} bytes uncompressed, '
      '${keyPair.compressedPublicKey.length} bytes compressed');

  // Printing a key pair shows the address, never the private key.
  print('Key pair: $keyPair');

  // A fresh, random key pair for a new account.
  final fresh = VeChainKeyPair.generate();
  print('New account: ${fresh.address}');

  // Addresses parse in lowercase, uppercase, or a correct checksum,
  // and all three forms are the same address.
  final lower = VeChainAddress.parse(
    '0x769e8aa372c8309c834ea6749b88861ff73581ff',
  );
  print('Lowercase equals checksummed: ${lower == keyPair.address}');

  // One mistyped character in a checksummed address is caught.
  try {
    VeChainAddress.parse('0x769F8AA372c8309c834EA6749B88861FF73581FF');
  } on VeChainAddressException catch (e) {
    print('Expected checksum error: ${e.message}');
  }

  // Short addresses are rejected, never padded with zeros.
  try {
    VeChainAddress.parse('0xcaffee');
  } on VeChainAddressException catch (e) {
    print('Expected format error: ${e.message}');
  }
}
