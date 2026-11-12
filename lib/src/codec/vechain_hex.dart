import 'dart:typed_data';

import 'package:vechain_flutter_sdk/src/exceptions/vechain_codec_exception.dart';

/// Converts between raw bytes and `0x`-prefixed hexadecimal strings, the
/// format VeChainThor uses for hashes, addresses, signatures, and raw
/// transactions.
///
/// Why this exists: almost every value the SDK sends to or reads from a
/// VeChainThor node is a hex string. Having one strict, well-tested
/// codec avoids repeating the conversion across the SDK, and guarantees
/// the same rules everywhere.
///
/// Rules, aligned with the official VeChain SDK (`Hex`):
///
/// - [encode] always returns `0x` followed by lowercase hex digits.
/// - [decode] accepts the `0x` prefix as optional, and digits in any
///   case.
/// - [decode] rejects any character that is not a hex digit.
///
/// Design decision: [decode] also rejects an odd number of digits, where
/// the official SDK pads with a leading `0`. The official `Hex` type
/// also represents numbers, where `0xabc` and `0x0abc` are the same
/// value. This codec represents bytes (hashes, addresses, signatures),
/// where a missing digit is almost always a copy error; padding it
/// silently would produce different bytes.
///
/// Example:
/// ```dart
/// final bytes = VeChainHex.decode('0xCAFE');
/// print(bytes); // [202, 254]
/// print(VeChainHex.encode(bytes)); // 0xcafe
/// ```
///
/// See:
/// https://github.com/vechain/vechain-sdk-js/blob/main/packages/core/src/vcdm/Hex.ts
class VeChainHex {
  const VeChainHex._();

  /// The prefix of every hex string produced by [encode].
  static const String prefix = '0x';

  /// Zero or more hex digits, in any case.
  static final RegExp _hexDigits = RegExp(r'^[0-9a-fA-F]*$');

  /// Converts [bytes] to `0x` followed by two lowercase hex digits per
  /// byte.
  ///
  /// An empty list produces `0x`.
  ///
  /// Example:
  /// ```dart
  /// print(VeChainHex.encode(Uint8List.fromList([0, 255]))); // 0x00ff
  /// ```
  static String encode(Uint8List bytes) {
    final buffer = StringBuffer(prefix);
    for (final byte in bytes) {
      // Pad to two digits so a byte like 0x0a is written as "0a".
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  /// Converts the hex string [hex] to bytes.
  ///
  /// The `0x` (or `0X`) prefix is optional and digits are
  /// case-insensitive. `0x` and the empty string both produce an empty
  /// list.
  ///
  /// Throws a [VeChainCodecException] if [hex] contains a character that
  /// is not a hex digit, or an odd number of digits.
  ///
  /// Example:
  /// ```dart
  /// print(VeChainHex.decode('0x00ff')); // [0, 255]
  /// print(VeChainHex.decode('00FF')); // [0, 255]
  /// ```
  static Uint8List decode(String hex) {
    // Remove the optional prefix, in either case.
    final hasPrefix = hex.startsWith('0x') || hex.startsWith('0X');
    final digits = hasPrefix ? hex.substring(2) : hex;

    // Reject anything that is not a hex digit.
    if (!_hexDigits.hasMatch(digits)) {
      throw VeChainCodecException(
        'Invalid hex string "$hex": only 0-9, a-f and A-F are allowed '
        'after the optional 0x prefix.',
      );
    }

    // Every byte needs exactly two digits; never pad silently.
    if (digits.length.isOdd) {
      throw VeChainCodecException(
        'Invalid hex string "$hex": expected an even number of hex '
        'digits (2 per byte), got ${digits.length}.',
      );
    }

    // Parse each pair of digits into one byte.
    final result = Uint8List(digits.length ~/ 2);
    for (var i = 0; i < result.length; i++) {
      result[i] = int.parse(digits.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }
}
