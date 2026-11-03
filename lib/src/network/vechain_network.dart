import 'package:meta/meta.dart';
import 'package:vechain_flutter_sdk/src/exceptions/vechain_network_exception.dart';

/// A VeChainThor network: its identity (genesis block ID and chain tag)
/// and the node URL used to reach it.
///
/// Why this exists: every VeChainThor transaction includes a chain tag,
/// the last byte of the network's genesis block ID. It is what prevents
/// a transaction signed for testnet from being replayed on mainnet. The
/// SDK needs a single, reliable source for that value, together with the
/// node URL the client will talk to.
///
/// Design decision: the [chainTag] is derived from the [genesisId], not
/// stored separately. Since the chain tag is, by definition, the last
/// byte of the genesis ID, deriving it makes an inconsistent network
/// (a chain tag that does not match its genesis) impossible to build.
///
/// Three official networks are predefined as `const` values, so they can
/// be used as default parameter values:
///
/// - [VeChainNetwork.mainnet]: production, real value.
/// - [VeChainNetwork.testnet]: public testing, valueless tokens.
/// - [VeChainNetwork.solo]: a local node for development.
///
/// Any other network (for example, a private node) can be described with
/// [VeChainNetwork.custom], which validates its inputs.
///
/// Example:
/// ```dart
/// const network = VeChainNetwork.testnet;
/// print(network.chainTag); // 39 (0x27)
/// print(network.nodeUrl); // https://testnet.vechain.org
///
/// final myNode = VeChainNetwork.custom(
///   name: 'my-mainnet-node',
///   genesisId:
///       '0x00000000851caf3cfdb6e899cf5958bfb1ac3413d346d43539627e6be7ec1b4a',
///   nodeUrl: 'https://my-node.example.com',
/// );
/// print(myNode.chainTag); // 74 (0x4a)
/// ```
///
/// See:
/// - https://docs.vechain.org/thor/learn/transaction-model
/// - https://academy.vechain.org/academy/connect-to-the-network
@immutable
class VeChainNetwork {
  const VeChainNetwork._({
    required this.name,
    required this.genesisId,
    required this.nodeUrl,
  });

  /// Creates a custom network, validating every input.
  ///
  /// - [name] must not be empty; surrounding whitespace is removed.
  /// - [genesisId] must be `0x` followed by 64 hexadecimal characters
  ///   (32 bytes). It is normalized to lowercase.
  /// - [nodeUrl] must be an absolute `http` or `https` URL with a host.
  ///   Trailing slashes are removed, so request paths can be appended
  ///   consistently.
  ///
  /// Throws a [VeChainNetworkException] if any input is invalid.
  ///
  /// Example:
  /// ```dart
  /// final local = VeChainNetwork.custom(
  ///   name: 'solo-docker',
  ///   genesisId:
  ///       '0x00000000c05a20fbca2bf6ae3affba6af4a74b800b585bf7a4988aba7aea69f6',
  ///   nodeUrl: 'http://192.168.1.20:8669/',
  /// );
  /// print(local.nodeUrl); // http://192.168.1.20:8669
  /// ```
  factory VeChainNetwork.custom({
    required String name,
    required String genesisId,
    required String nodeUrl,
  }) {
    // Reject empty names so every network can be identified in logs.
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const VeChainNetworkException('Network name must not be empty.');
    }

    // Normalize to lowercase, then check the exact 32-byte hex format.
    final normalizedGenesisId = genesisId.trim().toLowerCase();
    if (!_genesisIdPattern.hasMatch(normalizedGenesisId)) {
      throw VeChainNetworkException(
        'Invalid genesis ID "$genesisId": expected 0x followed by '
        '64 hexadecimal characters (32 bytes).',
      );
    }

    // Accept only absolute http(s) URLs that name a host.
    final trimmedUrl = nodeUrl.trim();
    final uri = Uri.tryParse(trimmedUrl);
    final isHttp =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    if (!isHttp || uri.host.isEmpty) {
      throw VeChainNetworkException(
        'Invalid node URL "$nodeUrl": expected an absolute http or https '
        'URL with a host.',
      );
    }

    // Drop trailing slashes so request paths can be appended uniformly.
    final normalizedUrl = trimmedUrl.replaceAll(_trailingSlashes, '');

    return VeChainNetwork._(
      name: trimmedName,
      genesisId: normalizedGenesisId,
      nodeUrl: normalizedUrl,
    );
  }

  // ---- Official networks ----

  /// The VeChainThor production network (chain tag `0x4a`).
  ///
  /// Uses the official public node `https://mainnet.vechain.org`.
  static const VeChainNetwork mainnet = VeChainNetwork._(
    name: 'mainnet',
    genesisId:
        '0x00000000851caf3cfdb6e899cf5958bfb1ac3413d346d43539627e6be7ec1b4a',
    nodeUrl: 'https://mainnet.vechain.org',
  );

  /// The VeChainThor public test network (chain tag `0x27`).
  ///
  /// Tokens on this network have no real-world value. Uses the official
  /// public node `https://testnet.vechain.org`.
  static const VeChainNetwork testnet = VeChainNetwork._(
    name: 'testnet',
    genesisId:
        '0x000000000b2bce3c70bc649a02749e8687721b09ed2e15997f466536b20bb127',
    nodeUrl: 'https://testnet.vechain.org',
  );

  /// A local Thor solo node for development (chain tag `0xf6`).
  ///
  /// Uses `http://127.0.0.1:8669`, the default solo port. The explicit
  /// IPv4 address (instead of `localhost`) follows the official SDK,
  /// which uses it to avoid IPv6 resolution issues.
  static const VeChainNetwork solo = VeChainNetwork._(
    name: 'solo',
    genesisId:
        '0x00000000c05a20fbca2bf6ae3affba6af4a74b800b585bf7a4988aba7aea69f6',
    nodeUrl: 'http://127.0.0.1:8669',
  );

  // ---- Validation patterns ----

  /// `0x` followed by exactly 64 lowercase hexadecimal characters.
  static final RegExp _genesisIdPattern = RegExp(r'^0x[0-9a-f]{64}$');

  /// One or more slashes at the end of a string.
  static final RegExp _trailingSlashes = RegExp(r'/+$');

  // ---- Fields ----

  /// A short, human-readable name for this network (for example,
  /// `mainnet`).
  final String name;

  /// The ID of this network's genesis block: `0x` followed by 64
  /// lowercase hexadecimal characters (32 bytes).
  final String genesisId;

  /// The base URL of the node used to reach this network, without a
  /// trailing slash.
  final String nodeUrl;

  // ---- Derived values ----

  /// The chain tag: the last byte of [genesisId], as an integer.
  ///
  /// Every transaction includes this value so it can only be executed
  /// on the network it was signed for.
  ///
  /// Example:
  /// ```dart
  /// print(VeChainNetwork.mainnet.chainTag); // 74 (0x4a)
  /// ```
  int get chainTag =>
      int.parse(genesisId.substring(genesisId.length - 2), radix: 16);

  /// [nodeUrl] parsed as a [Uri].
  Uri get nodeUri => Uri.parse(nodeUrl);

  // ---- Equality ----

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VeChainNetwork &&
          other.name == name &&
          other.genesisId == genesisId &&
          other.nodeUrl == nodeUrl;

  @override
  int get hashCode => Object.hash(name, genesisId, nodeUrl);

  @override
  String toString() {
    // Show the chain tag in the same 0x-prefixed form used in the docs.
    final tag = chainTag.toRadixString(16).padLeft(2, '0');
    return 'VeChainNetwork(name: $name, chainTag: 0x$tag, nodeUrl: $nodeUrl)';
  }
}
