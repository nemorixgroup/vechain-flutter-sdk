/// Phase 1 - 0.0.3-dev: Hashing and hex encoding.
///
/// VeChainThor uses two 32-byte hash functions: BLAKE2b-256 for
/// transaction signing hashes and IDs, and Keccak-256 (legacy Keccak,
/// as in Ethereum) for addresses and ABI encoding. VeChainHex converts
/// bytes to and from the 0x-prefixed hex strings used across the
/// VeChainThor APIs.
///
/// // Full technical decisions:
/// https://github.com/nemorixgroup/VeChain-Knowledge-Base/tree/main/docs-sdk/phase-1/hashing
import 'dart:convert';
import 'dart:typed_data';

import 'package:vechain_flutter_sdk/vechain_flutter_sdk.dart';

void hashingExample() {
  // Hash the same official test text with both functions.
  final data = Uint8List.fromList(
    utf8.encode('Hello world - Здравствуйте - こんにちは!'),
  );
  final blake = VeChainHash.blake2b256(data);
  final keccak = VeChainHash.keccak256(data);
  print('BLAKE2b-256: ${VeChainHex.encode(blake)}');
  print('Keccak-256:  ${VeChainHex.encode(keccak)}');

  // Hashing several parts equals hashing them joined, as the node does
  // to build a transaction ID from its signing hash and sender.
  final parts = VeChainHash.blake2b256Concat([
    Uint8List.fromList(utf8.encode('multi')),
    Uint8List.fromList(utf8.encode('ple')),
    Uint8List.fromList(utf8.encode('data')),
  ]);
  final joined = VeChainHash.blake2b256(
    Uint8List.fromList(utf8.encode('multipledata')),
  );
  print('Parts equal joined: '
      '${VeChainHex.encode(parts) == VeChainHex.encode(joined)}');

  // Hex decoding accepts an optional prefix and any case; encoding
  // always returns 0x plus lowercase digits.
  final bytes = VeChainHex.decode('0xCAFE');
  print('Decoded 0xCAFE: $bytes -> ${VeChainHex.encode(bytes)}');

  // A missing digit is rejected, never padded silently.
  try {
    VeChainHex.decode('0xabc');
  } on VeChainCodecException catch (e) {
    print('Expected validation error: ${e.message}');
  }
}
