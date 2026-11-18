import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:vechain_flutter_sdk/src/codec/vechain_hex.dart';
import 'package:vechain_flutter_sdk/src/crypto/vechain_hash.dart';
import 'package:vechain_flutter_sdk/src/crypto/vechain_secp256k1.dart';
import 'package:vechain_flutter_sdk/src/exceptions/vechain_address_exception.dart';

/// A VeChainThor account address: 20 bytes, shown as `0x` plus 40 hex
/// digits with an EIP-55 checksum.
///
/// Why this exists: an address identifies an account and is where funds
/// are sent. VeChainThor derives it exactly like Ethereum: the
/// Keccak-256 hash of the uncompressed public key (without its `0x04`
/// prefix), keeping the last 20 bytes. Its text form uses the EIP-55
/// mixed-case checksum, so a mistyped character can be detected.
///
/// Design decisions:
///
/// - [VeChainAddress.parse] enforces EIP-55: an all-lowercase or
///   all-uppercase address carries no checksum and is accepted, but a
///   mixed-case address must match its checksum exactly. The official
///   VeChain SDK accepts any mixed case without checking it.
/// - Short addresses are rejected, not padded with zeros: a padded
///   address would be a different, valid-looking address.
///
/// Example:
/// ```dart
/// final address = VeChainAddress.parse(
///   '0x769E8AA372c8309c834EA6749B88861FF73581FF',
/// );
/// print(address); // 0x769E8AA372c8309c834EA6749B88861FF73581FF
/// print(address.bytes.length); // 20
/// ```
///
/// See:
/// - https://github.com/vechain/vechain-sdk-js/blob/main/packages/core/src/vcdm/Address.ts
/// - https://eips.ethereum.org/EIPS/eip-55
@immutable
class VeChainAddress {
  const VeChainAddress._(this._bytes);

  /// Creates an address from its 20 raw bytes.
  ///
  /// Throws a [VeChainAddressException] if [bytes] is not exactly 20
  /// bytes long.
  ///
  /// Example:
  /// ```dart
  /// final address = VeChainAddress.fromBytes(Uint8List(20));
  /// print(address); // 0x0000000000000000000000000000000000000000
  /// ```
  factory VeChainAddress.fromBytes(Uint8List bytes) {
    if (bytes.length != length) {
      throw VeChainAddressException(
        'Invalid address: expected $length bytes, got ${bytes.length}.',
      );
    }
    // Copy, so later changes to the caller's list cannot alter it.
    return VeChainAddress._(Uint8List.fromList(bytes));
  }

  /// Derives the address of a secp256k1 [publicKey], compressed (33
  /// bytes) or uncompressed (65 bytes).
  ///
  /// Throws a `VeChainCryptoException` if [publicKey] is not a valid
  /// secp256k1 public key.
  ///
  /// Example:
  /// ```dart
  /// final address = VeChainAddress.fromPublicKey(publicKey);
  /// ```
  factory VeChainAddress.fromPublicKey(Uint8List publicKey) {
    // Always hash the full point, even if a compressed key was given.
    final uncompressed = VeChainSecp256k1.decodePublicKey(publicKey);

    // Hash X and Y without the 0x04 prefix; keep the last 20 bytes.
    final hash = VeChainHash.keccak256(uncompressed.sublist(1));
    return VeChainAddress._(hash.sublist(hash.length - length));
  }

  /// Parses an address string: `0x` followed by 40 hex digits.
  ///
  /// All-lowercase and all-uppercase digits are accepted as they are.
  /// Mixed-case digits must match the EIP-55 checksum exactly.
  ///
  /// Throws a [VeChainAddressException] if the format is invalid or the
  /// checksum does not match.
  ///
  /// Example:
  /// ```dart
  /// VeChainAddress.parse('0x769e8aa372c8309c834ea6749b88861ff73581ff');
  /// VeChainAddress.parse('0x769E8AA372c8309c834EA6749B88861FF73581FF');
  /// ```
  factory VeChainAddress.parse(String address) {
    // Require the prefix and exactly 40 hex digits; never pad.
    if (!_addressPattern.hasMatch(address)) {
      throw VeChainAddressException(
        'Invalid address "$address": expected 0x followed by 40 '
        'hexadecimal characters (20 bytes).',
      );
    }
    final digits = address.substring(2);
    final parsed = VeChainAddress._(VeChainHex.decode(digits));

    // Only mixed case carries a checksum, and then it must match.
    final isMixedCase =
        digits != digits.toLowerCase() && digits != digits.toUpperCase();
    if (isMixedCase && parsed.toString().substring(2) != digits) {
      // The expected checksum is not shown: if a character was mistyped,
      // it would be the checksum of the wrong address.
      throw VeChainAddressException(
        'Invalid address checksum "$address": mixed-case addresses must '
        'match their EIP-55 checksum.',
      );
    }
    return parsed;
  }

  /// Length of an address, in bytes.
  static const int length = 20;

  /// `0x` (either case) followed by exactly 40 hex digits.
  static final RegExp _addressPattern = RegExp(r'^0[xX][0-9a-fA-F]{40}$');

  final Uint8List _bytes;

  /// The 20 raw bytes of this address (a copy).
  Uint8List get bytes => Uint8List.fromList(_bytes);

  /// The address with its EIP-55 checksum, for example
  /// `0x769E8AA372c8309c834EA6749B88861FF73581FF`.
  @override
  String toString() {
    // EIP-55 hashes the lowercase hex digits as ASCII text.
    final lower = VeChainHex.encode(_bytes).substring(2);
    final hash = VeChainHex.encode(
      VeChainHash.keccak256(Uint8List.fromList(ascii.encode(lower))),
    ).substring(2);

    // Uppercase each letter whose matching hash digit is 8 or more.
    final buffer = StringBuffer(VeChainHex.prefix);
    for (var i = 0; i < lower.length; i++) {
      final useUpper = int.parse(hash[i], radix: 16) > 7;
      buffer.write(useUpper ? lower[i].toUpperCase() : lower[i]);
    }
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! VeChainAddress) return false;
    for (var i = 0; i < length; i++) {
      if (other._bytes[i] != _bytes[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_bytes);
}
