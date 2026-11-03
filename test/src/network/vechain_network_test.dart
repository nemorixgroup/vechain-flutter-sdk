import 'package:flutter_test/flutter_test.dart';
import 'package:vechain_flutter_sdk/vechain_flutter_sdk.dart';

// ---- Official reference values (from @vechain/sdk-core and sdk-network) ----

const _mainnetGenesisId =
    '0x00000000851caf3cfdb6e899cf5958bfb1ac3413d346d43539627e6be7ec1b4a';
const _testnetGenesisId =
    '0x000000000b2bce3c70bc649a02749e8687721b09ed2e15997f466536b20bb127';
const _soloGenesisId =
    '0x00000000c05a20fbca2bf6ae3affba6af4a74b800b585bf7a4988aba7aea69f6';

/// Matches a [VeChainNetworkException] whose message contains [text].
Matcher _throwsNetworkException(String text) => throwsA(
      isA<VeChainNetworkException>().having(
        (e) => e.message,
        'message',
        contains(text),
      ),
    );

/// Returns [network], so the tests can prove the official networks
/// work as `const` default parameter values.
VeChainNetwork _pickNetwork({
  VeChainNetwork network = VeChainNetwork.testnet,
}) =>
    network;

void main() {
  group('VeChainNetwork official networks', () {
    test('mainnet matches the official constants', () {
      const network = VeChainNetwork.mainnet;

      expect(network.name, 'mainnet');
      expect(network.genesisId, _mainnetGenesisId);
      expect(network.chainTag, 0x4a);
      expect(network.nodeUrl, 'https://mainnet.vechain.org');
    });

    test('testnet matches the official constants', () {
      const network = VeChainNetwork.testnet;

      expect(network.name, 'testnet');
      expect(network.genesisId, _testnetGenesisId);
      expect(network.chainTag, 0x27);
      expect(network.nodeUrl, 'https://testnet.vechain.org');
    });

    test('solo matches the official constants', () {
      const network = VeChainNetwork.solo;

      expect(network.name, 'solo');
      expect(network.genesisId, _soloGenesisId);
      expect(network.chainTag, 0xf6);
      expect(network.nodeUrl, 'http://127.0.0.1:8669');
    });

    test('chainTag is the last byte of the genesis ID for every network', () {
      for (final network in [
        VeChainNetwork.mainnet,
        VeChainNetwork.testnet,
        VeChainNetwork.solo,
      ]) {
        final lastByte = network.genesisId.substring(64);
        expect(network.chainTag, int.parse(lastByte, radix: 16));
      }
    });

    test('official networks can be used as const default parameters', () {
      expect(_pickNetwork(), VeChainNetwork.testnet);
      expect(
        _pickNetwork(network: VeChainNetwork.mainnet),
        VeChainNetwork.mainnet,
      );
    });

    test('nodeUri parses the node URL', () {
      final uri = VeChainNetwork.mainnet.nodeUri;

      expect(uri.scheme, 'https');
      expect(uri.host, 'mainnet.vechain.org');
    });
  });

  group('VeChainNetwork.custom', () {
    test('creates a network and derives its chain tag', () {
      final network = VeChainNetwork.custom(
        name: 'my-node',
        genesisId: _mainnetGenesisId,
        nodeUrl: 'https://my-node.example.com',
      );

      expect(network.name, 'my-node');
      expect(network.genesisId, _mainnetGenesisId);
      expect(network.chainTag, 0x4a);
      expect(network.nodeUrl, 'https://my-node.example.com');
    });

    test('accepts http URLs with a port', () {
      final network = VeChainNetwork.custom(
        name: 'solo-docker',
        genesisId: _soloGenesisId,
        nodeUrl: 'http://192.168.1.20:8669',
      );

      expect(network.nodeUri.port, 8669);
    });

    test('normalizes the genesis ID to lowercase', () {
      final network = VeChainNetwork.custom(
        name: 'upper',
        genesisId: _testnetGenesisId.toUpperCase(),
        nodeUrl: 'https://testnet.vechain.org',
      );

      expect(network.genesisId, _testnetGenesisId);
      expect(network.chainTag, 0x27);
    });

    test('trims surrounding whitespace from every input', () {
      final network = VeChainNetwork.custom(
        name: '  my-node  ',
        genesisId: '  $_mainnetGenesisId  ',
        nodeUrl: '  https://my-node.example.com  ',
      );

      expect(network.name, 'my-node');
      expect(network.genesisId, _mainnetGenesisId);
      expect(network.nodeUrl, 'https://my-node.example.com');
    });

    test('removes trailing slashes from the node URL', () {
      final single = VeChainNetwork.custom(
        name: 'single',
        genesisId: _mainnetGenesisId,
        nodeUrl: 'https://my-node.example.com/',
      );
      final multiple = VeChainNetwork.custom(
        name: 'multiple',
        genesisId: _mainnetGenesisId,
        nodeUrl: 'https://my-node.example.com///',
      );

      expect(single.nodeUrl, 'https://my-node.example.com');
      expect(multiple.nodeUrl, 'https://my-node.example.com');
    });

    test('a custom network with official values equals the official one', () {
      final network = VeChainNetwork.custom(
        name: 'mainnet',
        genesisId: _mainnetGenesisId,
        nodeUrl: 'https://mainnet.vechain.org/',
      );

      expect(network, VeChainNetwork.mainnet);
      expect(network.hashCode, VeChainNetwork.mainnet.hashCode);
    });

    test('networks with a different node URL are not equal', () {
      final network = VeChainNetwork.custom(
        name: 'mainnet',
        genesisId: _mainnetGenesisId,
        nodeUrl: 'https://my-node.example.com',
      );

      expect(network, isNot(VeChainNetwork.mainnet));
    });
  });

  group('VeChainNetwork.custom validation', () {
    test('throws on an empty name', () {
      expect(
        () => VeChainNetwork.custom(
          name: '',
          genesisId: _mainnetGenesisId,
          nodeUrl: 'https://mainnet.vechain.org',
        ),
        _throwsNetworkException('Network name must not be empty'),
      );
    });

    test('throws on a whitespace-only name', () {
      expect(
        () => VeChainNetwork.custom(
          name: '   ',
          genesisId: _mainnetGenesisId,
          nodeUrl: 'https://mainnet.vechain.org',
        ),
        _throwsNetworkException('Network name must not be empty'),
      );
    });

    test('throws on a genesis ID without the 0x prefix', () {
      final withoutPrefix = _mainnetGenesisId.substring(2);

      expect(
        () => VeChainNetwork.custom(
          name: 'no-prefix',
          genesisId: withoutPrefix,
          nodeUrl: 'https://mainnet.vechain.org',
        ),
        _throwsNetworkException('Invalid genesis ID'),
      );
    });

    test('throws on a genesis ID that is too short', () {
      expect(
        () => VeChainNetwork.custom(
          name: 'short',
          genesisId: '0x1234',
          nodeUrl: 'https://mainnet.vechain.org',
        ),
        _throwsNetworkException('Invalid genesis ID "0x1234"'),
      );
    });

    test('throws on a genesis ID that is too long', () {
      expect(
        () => VeChainNetwork.custom(
          name: 'long',
          genesisId: '${_mainnetGenesisId}00',
          nodeUrl: 'https://mainnet.vechain.org',
        ),
        _throwsNetworkException('Invalid genesis ID'),
      );
    });

    test('throws on a genesis ID with non-hex characters', () {
      final nonHex = '0x${'z' * 64}';

      expect(
        () => VeChainNetwork.custom(
          name: 'non-hex',
          genesisId: nonHex,
          nodeUrl: 'https://mainnet.vechain.org',
        ),
        _throwsNetworkException('Invalid genesis ID'),
      );
    });

    test('throws on a node URL without a scheme', () {
      expect(
        () => VeChainNetwork.custom(
          name: 'no-scheme',
          genesisId: _mainnetGenesisId,
          nodeUrl: 'mainnet.vechain.org',
        ),
        _throwsNetworkException('Invalid node URL "mainnet.vechain.org"'),
      );
    });

    test('throws on a node URL with a non-http scheme', () {
      expect(
        () => VeChainNetwork.custom(
          name: 'websocket',
          genesisId: _mainnetGenesisId,
          nodeUrl: 'ws://mainnet.vechain.org',
        ),
        _throwsNetworkException('Invalid node URL'),
      );
    });

    test('throws on a node URL without a host', () {
      expect(
        () => VeChainNetwork.custom(
          name: 'no-host',
          genesisId: _mainnetGenesisId,
          nodeUrl: 'https://',
        ),
        _throwsNetworkException('Invalid node URL'),
      );
    });

    test('throws on an empty node URL', () {
      expect(
        () => VeChainNetwork.custom(
          name: 'empty-url',
          genesisId: _mainnetGenesisId,
          nodeUrl: '',
        ),
        _throwsNetworkException('Invalid node URL'),
      );
    });
  });

  group('VeChainNetwork.toString', () {
    test('shows the name, chain tag in hex, and node URL', () {
      expect(
        VeChainNetwork.mainnet.toString(),
        'VeChainNetwork(name: mainnet, chainTag: 0x4a, '
        'nodeUrl: https://mainnet.vechain.org)',
      );
    });
  });
}
