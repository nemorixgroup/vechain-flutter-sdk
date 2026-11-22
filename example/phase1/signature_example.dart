/// Phase 1 - 0.0.5-dev: Signatures and public key recovery.
///
/// VeChainThor transactions do not carry the sender's public key: the
/// node recovers it from the signature and the signed hash. Signatures
/// are 65 bytes (r + s + a recovery byte of 0 or 1), deterministic
/// (RFC 6979), and always have a low S, as the transaction pool
/// requires.
///
/// // Full technical decisions:
/// https://github.com/nemorixgroup/VeChain-Knowledge-Base/tree/main/docs-sdk/phase-1/signatures
import 'dart:convert';
import 'dart:typed_data';

import 'package:vechain_flutter_sdk/vechain_flutter_sdk.dart';

void signatureExample() {
  // Sign the official test hash with the official test key.
  final keyPair = VeChainKeyPair.fromPrivateKey(
    VeChainHex.decode(
      '0x7582be841ca040aa940fff6c05773129e135623e41acce3e0b8ba520dc1ae26a',
    ),
  );
  final hash = VeChainHash.keccak256(
    Uint8List.fromList(utf8.encode('hello world')),
  );
  final signature = keyPair.sign(hash);
  print('Signature: $signature');
  print('Recovery byte: ${signature.recovery}');

  // Anyone holding the hash and the signature can identify the signer.
  final signer = signature.recoverAddress(hash);
  print('Signer: $signer');
  print('Signer is the key pair: ${signer == keyPair.address}');

  // Deterministic: signing the same hash again gives the same bytes.
  print('Deterministic: ${keyPair.sign(hash) == signature}');

  // The same signature over a different hash points to someone else.
  final otherHash = VeChainHash.keccak256(
    Uint8List.fromList(utf8.encode('hello world!')),
  );
  print('Other hash, same signer: '
      '${signature.recoverAddress(otherHash) == keyPair.address}');

  // A high-S signature is rejected, as the transaction pool does.
  try {
    VeChainSignature.fromBytes(
      VeChainHex.decode(
        '0xf8fe82c74f9e1f5bf443f8a7f8eb968140f554968fdcab0a6ffe904e451c8b92'
        'bb41bb4334e014cb22df26276bc073eba886f78e4dd537340fa52bcc64a2f3cf01',
      ),
    );
  } on VeChainCryptoException catch (e) {
    print('Expected validation error: ${e.message}');
  }
}
