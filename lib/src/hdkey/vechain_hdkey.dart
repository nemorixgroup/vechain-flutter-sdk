import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/digests/sha512.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:vechain_flutter_sdk/src/address/vechain_address.dart';
import 'package:vechain_flutter_sdk/src/crypto/vechain_keypair.dart';
import 'package:vechain_flutter_sdk/src/crypto/vechain_secp256k1.dart';
import 'package:vechain_flutter_sdk/src/exceptions/vechain_crypto_exception.dart';
import 'package:vechain_flutter_sdk/src/exceptions/vechain_hdkey_exception.dart';
import 'package:vechain_flutter_sdk/src/mnemonic/vechain_mnemonic.dart';

/// A BIP-32 hierarchical deterministic (HD) key: one node of the tree of
/// keys that a single seed produces.
///
/// Why this exists: an HD wallet derives every account from one seed, so
/// backing up a mnemonic is enough to restore all of them. Each node has
/// a key and a chain code (32 extra bytes that make its children
/// unpredictable without it). VeChainThor accounts live under the path
/// `m/44'/818'/0'/0/i`, where 818 is VeChain's registered coin type
/// (SLIP-44) and `i` is the account number.
///
/// How a child is derived (BIP-32):
///
/// - Master: `HMAC-SHA512(key: "Bitcoin seed", data: seed)`; the first
///   32 bytes are the master private key, the last 32 the chain code.
/// - Child `i`: `HMAC-SHA512(key: chainCode, data: data || i)`. The
///   first 32 bytes (IL) are added to the parent key; the last 32 are
///   the child chain code.
/// - Normal children (`i < 2^31`) hash the parent public key, so their
///   public keys can be derived without any private key. Hardened
///   children (written with `'`) hash the parent private key.
///
/// Design decisions:
///
/// - [derive] accepts any syntactically valid BIP-32 path, not only the
///   shapes the official VeChain SDK's `isDerivationPathValid` allows,
///   because the official `derive` also accepts them.
/// - [VeChainHDKey.fromMnemonic] takes a validated [VeChainMnemonic],
///   not raw words.
/// - If an index produces an invalid key (odds of about 1 in 2^127),
///   [deriveChild] throws instead of silently moving to the next index,
///   which would return a different account than the one requested.
/// - Getters return copies, and [toString] never shows the private key
///   or the chain code. A public key plus its chain code reveals every
///   normal child's public key, so the chain code is treated as
///   sensitive.
///
/// Example:
/// ```dart
/// final root = VeChainHDKey.fromMnemonic(mnemonic); // m/44'/818'/0'/0
/// final account0 = root.deriveChild(0);
/// print(account0.address); // first account of the wallet
/// ```
///
/// See:
/// - https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki
/// - https://github.com/vechain/vechain-sdk-js/blob/main/packages/core/src/hdkey/HDKey.ts
class VeChainHDKey {
  VeChainHDKey._({
    required Uint8List? privateKey,
    required Uint8List publicKey,
    required Uint8List chainCode,
    required this.depth,
    required this.index,
  })  : _privateKey = privateKey,
        _publicKey = publicKey,
        _chainCode = chainCode;

  /// Creates the master node (`m`) from a BIP-32 [seed] of 16 to 64
  /// bytes, such as the 64-byte seed of a [VeChainMnemonic].
  ///
  /// Throws a [VeChainHDKeyException] if the seed length is outside that
  /// range or the seed produces an invalid master key.
  ///
  /// Example:
  /// ```dart
  /// final master = VeChainHDKey.fromSeed(mnemonic.toSeed());
  /// ```
  factory VeChainHDKey.fromSeed(Uint8List seed) {
    if (seed.length < 16 || seed.length > 64) {
      throw VeChainHDKeyException(
        'Invalid seed: expected 16 to 64 bytes, got ${seed.length}.',
      );
    }

    // Master key and chain code: HMAC-SHA512 keyed with "Bitcoin seed".
    final digest = _hmacSha512(_masterHmacKey, seed);
    final key = digest.sublist(0, 32);
    if (!VeChainSecp256k1.isValidPrivateKey(key)) {
      throw const VeChainHDKeyException(
        'Invalid seed: it produces an invalid master key. Use a '
        'different seed.',
      );
    }
    return VeChainHDKey._withPrivateKey(
      privateKey: key,
      chainCode: digest.sublist(32),
      depth: 0,
      index: 0,
    );
  }

  /// Derives the node at [path] (by default [vetDerivationPath]) from a
  /// [mnemonic] and an optional ASCII [passphrase].
  ///
  /// With the defaults, the result is the official VeChain account node;
  /// its children `0, 1, 2...` are the accounts of the wallet.
  ///
  /// Throws a [VeChainHDKeyException] if [path] is malformed, and a
  /// `VeChainMnemonicException` if [passphrase] is not ASCII.
  ///
  /// Example:
  /// ```dart
  /// final root = VeChainHDKey.fromMnemonic(mnemonic);
  /// print(root.deriveChild(0).address);
  /// ```
  factory VeChainHDKey.fromMnemonic(
    VeChainMnemonic mnemonic, {
    String path = vetDerivationPath,
    String passphrase = '',
  }) {
    final seed = mnemonic.toSeed(passphrase: passphrase);
    return VeChainHDKey.fromSeed(seed).derive(path);
  }

  /// Creates a node from a 32-byte [privateKey] and its 32-byte
  /// [chainCode], for example to restore a node saved earlier.
  ///
  /// Throws a [VeChainHDKeyException] if [chainCode] is not 32 bytes,
  /// and a [VeChainCryptoException] if [privateKey] is invalid.
  ///
  /// Example:
  /// ```dart
  /// final node = VeChainHDKey.fromPrivateKey(
  ///   root.privateKey!,
  ///   root.chainCode,
  /// );
  /// ```
  factory VeChainHDKey.fromPrivateKey(
    Uint8List privateKey,
    Uint8List chainCode,
  ) {
    _requireChainCode(chainCode);
    if (!VeChainSecp256k1.isValidPrivateKey(privateKey)) {
      throw const VeChainCryptoException(
        'Invalid private key: expected 32 bytes representing an integer '
        'between 1 and the secp256k1 curve order minus 1.',
      );
    }
    return VeChainHDKey._withPrivateKey(
      privateKey: Uint8List.fromList(privateKey),
      chainCode: Uint8List.fromList(chainCode),
      depth: 0,
      index: 0,
    );
  }

  /// Creates a watch-only node from a [publicKey] (33 or 65 bytes) and
  /// its 32-byte [chainCode].
  ///
  /// A watch-only node derives the public keys and addresses of its
  /// normal children, but cannot sign or derive hardened children.
  ///
  /// Throws a [VeChainHDKeyException] if [chainCode] is not 32 bytes,
  /// and a [VeChainCryptoException] if [publicKey] is invalid.
  ///
  /// Example:
  /// ```dart
  /// final watcher = VeChainHDKey.fromPublicKey(
  ///   root.publicKey,
  ///   root.chainCode,
  /// );
  /// print(watcher.deriveChild(0).address); // same as root's child 0
  /// ```
  factory VeChainHDKey.fromPublicKey(
    Uint8List publicKey,
    Uint8List chainCode,
  ) {
    _requireChainCode(chainCode);
    return VeChainHDKey._(
      privateKey: null,
      publicKey: VeChainSecp256k1.compressPublicKey(publicKey),
      chainCode: Uint8List.fromList(chainCode),
      depth: 0,
      index: 0,
    );
  }

  /// Builds a node from a private key that is already valid.
  factory VeChainHDKey._withPrivateKey({
    required Uint8List privateKey,
    required Uint8List chainCode,
    required int depth,
    required int index,
  }) =>
      VeChainHDKey._(
        privateKey: privateKey,
        publicKey: VeChainSecp256k1.derivePublicKey(
          privateKey,
          compressed: true,
        ),
        chainCode: chainCode,
        depth: depth,
        index: index,
      );

  // ---- Constants ----

  /// The official VeChain derivation path for accounts:
  /// `m/44'/818'/0'/0`. Account `i` is child `i` of this node.
  static const String vetDerivationPath = "m/44'/818'/0'/0";

  /// The first hardened index, 2^31.
  static const int hardenedOffset = 0x80000000;

  /// Length of a chain code, in bytes.
  static const int chainCodeLength = 32;

  /// The HMAC key for the master node, defined by BIP-32.
  static final Uint8List _masterHmacKey =
      Uint8List.fromList(utf8.encode('Bitcoin seed'));

  /// The secp256k1 domain, used to add points for public derivation.
  static final ECDomainParameters _domain = ECCurve_secp256k1();

  /// A path component: decimal digits, optionally followed by `'`.
  static final RegExp _componentPattern = RegExp(r"^(\d+)('?)$");

  // ---- Fields ----

  final Uint8List? _privateKey;
  final Uint8List _publicKey;
  final Uint8List _chainCode;

  /// How many derivation steps separate this node from the node it was
  /// created from (0 for a node created directly).
  final int depth;

  /// The child number of this node, including [hardenedOffset] for a
  /// hardened child (0 for a node created directly).
  final int index;

  /// The 32-byte private key (a copy), or null for a watch-only node.
  ///
  /// Keep it secret: anyone holding it controls the account.
  Uint8List? get privateKey {
    final key = _privateKey;
    return key == null ? null : Uint8List.fromList(key);
  }

  /// The 33-byte compressed public key (a copy).
  Uint8List get publicKey => Uint8List.fromList(_publicKey);

  /// The 32-byte chain code (a copy).
  ///
  /// Treat it as sensitive: with the public key, it reveals the public
  /// keys of every normal child.
  Uint8List get chainCode => Uint8List.fromList(_chainCode);

  /// Whether this node has no private key and can only derive public
  /// keys of normal children.
  bool get isWatchOnly => _privateKey == null;

  /// The account address of this node.
  VeChainAddress get address => VeChainAddress.fromPublicKey(_publicKey);

  /// The key pair of this node, to sign with it.
  ///
  /// Throws a [VeChainHDKeyException] if this node is watch-only.
  VeChainKeyPair get keyPair {
    final key = _privateKey;
    if (key == null) {
      throw const VeChainHDKeyException(
        'This key is watch-only: it has no private key to build a key '
        'pair.',
      );
    }
    return VeChainKeyPair.fromPrivateKey(key);
  }

  // ---- Derivation ----

  /// Derives the node at [path], applied from this node.
  ///
  /// The path starts with `m` (meaning this node) followed by
  /// `/`-separated indexes; an index ending in `'` is hardened. Every
  /// index must be below 2^31. `m` alone returns this node.
  ///
  /// Throws a [VeChainHDKeyException] if the path is malformed, an index
  /// is out of range, or a hardened step is requested on a watch-only
  /// node.
  ///
  /// Example:
  /// ```dart
  /// final node = master.derive("m/44'/818'/0'/0/0");
  /// ```
  VeChainHDKey derive(String path) {
    final components = path.split('/');
    if (components.first != 'm') {
      throw VeChainHDKeyException(
        'Invalid derivation path "$path": it must start with "m".',
      );
    }

    // Apply each component in order, starting from this node.
    var node = this;
    for (final component in components.skip(1)) {
      final match = _componentPattern.firstMatch(component);
      final value = match == null ? null : int.tryParse(match.group(1)!);
      if (match == null || value == null) {
        throw VeChainHDKeyException(
          'Invalid derivation path "$path": "$component" is not a valid '
          "index (digits, optionally followed by ').",
        );
      }
      if (value >= hardenedOffset) {
        throw VeChainHDKeyException(
          'Invalid derivation path "$path": index $value is out of range; '
          'it must be below 2^31.',
        );
      }
      node = node.deriveChild(value, hardened: match.group(2) == "'");
    }
    return node;
  }

  /// Derives child number [index] of this node; [hardened] selects a
  /// hardened child.
  ///
  /// Throws a [VeChainHDKeyException] if [index] is outside
  /// `[0, 2^31 - 1]`, if a hardened child is requested on a watch-only
  /// node, or if the index produces an invalid key.
  ///
  /// Example:
  /// ```dart
  /// final account3 = root.deriveChild(3);
  /// ```
  VeChainHDKey deriveChild(int index, {bool hardened = false}) {
    if (index < 0 || index >= hardenedOffset) {
      throw VeChainHDKeyException(
        'Invalid child index $index: it must be between 0 and 2^31 - 1.',
      );
    }
    final privateKey = _privateKey;
    if (hardened && privateKey == null) {
      throw const VeChainHDKeyException(
        'Cannot derive a hardened child from a watch-only key: hardened '
        'derivation needs the private key.',
      );
    }

    // Hardened children hash 0x00 + private key; normal children hash
    // the compressed public key. Both append the 4-byte index.
    final childNumber = hardened ? index + hardenedOffset : index;
    final data = Uint8List.fromList([
      if (hardened) ...[0x00, ...privateKey!] else ..._publicKey,
      ..._uint32(childNumber),
    ]);
    final digest = _hmacSha512(_chainCode, data);
    final il = VeChainSecp256k1.bytesToBigInt(digest.sublist(0, 32));
    final childChainCode = digest.sublist(32);
    final order = VeChainSecp256k1.order;

    // BIP-32: IL >= n is invalid for any child.
    if (il >= order) throw _invalidChild(childNumber);

    // With a private key: child key = (IL + parent key) mod n.
    if (privateKey != null) {
      final parent = VeChainSecp256k1.bytesToBigInt(privateKey);
      final childKey = (il + parent) % order;
      if (childKey == BigInt.zero) throw _invalidChild(childNumber);
      return VeChainHDKey._withPrivateKey(
        privateKey: VeChainSecp256k1.bigIntToBytes(childKey, 32),
        chainCode: childChainCode,
        depth: depth + 1,
        index: childNumber,
      );
    }

    // Watch-only: child public key = point(IL) + parent public key.
    final ilPoint = _domain.curve.decodePoint(
      VeChainSecp256k1.derivePublicKey(
        VeChainSecp256k1.bigIntToBytes(il, 32),
      ),
    )!;
    final parentPoint = _domain.curve.decodePoint(
      VeChainSecp256k1.decodePublicKey(_publicKey),
    )!;
    final childPoint = ilPoint + parentPoint;
    if (childPoint == null || childPoint.isInfinity) {
      throw _invalidChild(childNumber);
    }
    return VeChainHDKey._(
      privateKey: null,
      publicKey: childPoint.getEncoded(),
      chainCode: childChainCode,
      depth: depth + 1,
      index: childNumber,
    );
  }

  /// Shows the position and the address; never the private key or the
  /// chain code.
  @override
  String toString() => 'VeChainHDKey(depth: $depth, index: $index, '
      'address: $address, watchOnly: $isWatchOnly)';

  // ---- Helpers ----

  /// HMAC-SHA512 of [data] keyed with [key].
  static Uint8List _hmacSha512(Uint8List key, Uint8List data) {
    final mac = HMac(SHA512Digest(), 128)..init(KeyParameter(key));
    return mac.process(data);
  }

  /// [value] as 4 big-endian bytes.
  static Uint8List _uint32(int value) {
    final bytes = ByteData(4)..setUint32(0, value);
    return bytes.buffer.asUint8List();
  }

  /// Throws unless [chainCode] is exactly 32 bytes.
  static void _requireChainCode(Uint8List chainCode) {
    if (chainCode.length != chainCodeLength) {
      throw VeChainHDKeyException(
        'Invalid chain code: expected $chainCodeLength bytes, got '
        '${chainCode.length}.',
      );
    }
  }

  /// The exception for an index whose derived key is invalid.
  static VeChainHDKeyException _invalidChild(int childNumber) =>
      VeChainHDKeyException(
        'Invalid child: index $childNumber produces an invalid key (odds '
        'of about 1 in 2^127). Use the next index.',
      );
}
